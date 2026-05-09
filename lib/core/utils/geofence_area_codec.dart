import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../maps/map_helper.dart';

/// Encodes/decodes Traccar geofence [area] WKT strings.
///
/// Convention (aligned with [TraccarGeofence] in `core/models/traccar_geofence.dart`):
/// - **Circle:** `CIRCLE(latitude longitude, radiusMeters)`
/// - **Polygon:** `POLYGON ((lon1 lat1, lon2 lat2, …))` — each pair is lon then lat,
///   ring closed (first point repeated at end).
class GeofenceAreaCodec {
  GeofenceAreaCodec._();

  static String encodeCircle({
    required double latitude,
    required double longitude,
    required double radiusMeters,
  }) =>
      'CIRCLE (${_num(latitude)} ${_num(longitude)}, ${_num(radiusMeters)})';

  /// [points] in map order (lat/lng). Encodes as closed ring in WKT lon/lat order.
  static String encodePolygon(List<LatLng> points) {
    if (points.length < 3) {
      throw ArgumentError('Polygon requires at least 3 positions');
    }
    final buf = StringBuffer('POLYGON ((');
    for (var i = 0; i < points.length; i++) {
      if (i > 0) buf.write(', ');
      final p = points[i];
      buf.write('${_num(p.longitude)} ${_num(p.latitude)}');
    }
    // close ring
    final first = points.first;
    buf.write(', ${_num(first.longitude)} ${_num(first.latitude)}');
    buf.write('))');
    return buf.toString();
  }

  static CircleData? decodeCircle(String area) {
    final m = RegExp(
      r'CIRCLE\s*\(\s*([-\d.]+)\s+([-\d.]+)\s*,\s*([-\d.]+)\s*\)',
      caseSensitive: false,
    ).firstMatch(area.trim());
    if (m == null) return null;
    return CircleData(
      latitude: double.parse(m.group(1)!),
      longitude: double.parse(m.group(2)!),
      radiusMeters: double.parse(m.group(3)!),
    );
  }

  static List<LatLng> decodePolygon(String area) =>
      MapHelper.parsePolygonWkt(area.trim());

  /// Point-in-polygon (ray casting). [polygon] must have at least 3 points.
  static bool pointInPolygon(LatLng point, List<LatLng> polygon) {
    if (polygon.length < 3) return false;
    final x = point.longitude;
    final y = point.latitude;
    var inside = false;
    for (var i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      final xi = polygon[i].longitude;
      final yi = polygon[i].latitude;
      final xj = polygon[j].longitude;
      final yj = polygon[j].latitude;
      final intersect = ((yi > y) != (yj > y)) &&
          (x < (xj - xi) * (y - yi) / (yj - yi + 0.0) + xi);
      if (intersect) inside = !inside;
    }
    return inside;
  }

  static bool pointInCircle(LatLng point, CircleData circle) {
    final d = MapHelper.distanceMeters(
      point,
      LatLng(circle.latitude, circle.longitude),
    );
    return d <= circle.radiusMeters + 0.5;
  }

  /// Returns geofence id if [tap] hits a circle/polygon built from [area] (keyed by id string).
  static String? hitTestGeofence(
    LatLng tap,
    Iterable<MapEntry<String, String>> idToArea,
  ) {
    for (final e in idToArea) {
      final area = e.value.toUpperCase();
      if (area.startsWith('CIRCLE')) {
        final c = decodeCircle(e.value);
        if (c != null && pointInCircle(tap, c)) return e.key;
      } else if (area.startsWith('POLYGON')) {
        final poly = decodePolygon(e.value);
        if (poly.length >= 3 && pointInPolygon(tap, poly)) return e.key;
      }
    }
    return null;
  }

  static String _num(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(6).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }
}

class CircleData {
  const CircleData({
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
  });

  final double latitude;
  final double longitude;
  final double radiusMeters;

  LatLng get center => LatLng(latitude, longitude);
}
