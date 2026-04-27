import 'dart:math' as math;
import 'package:flutter/material.dart' show Color;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'map_config.dart';

/// Utility functions for Google Maps operations.
class MapHelper {
  MapHelper._();

  // ── Camera ────────────────────────────────────────────────────────────────

  /// Builds a [CameraPosition] centered on [position].
  static CameraPosition cameraOn(
    LatLng position, {
    double zoom = MapConfig.cityZoom,
    double tilt = 0,
    double bearing = 0,
  }) =>
      CameraPosition(
        target: position,
        zoom: zoom,
        tilt: tilt,
        bearing: bearing,
      );

  /// Computes the [LatLngBounds] that contains all [points].
  /// Returns null if the list is empty.
  static LatLngBounds? boundsFromPoints(List<LatLng> points) {
    if (points.isEmpty) return null;
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final p in points) {
      minLat = math.min(minLat, p.latitude);
      maxLat = math.max(maxLat, p.latitude);
      minLng = math.min(minLng, p.longitude);
      maxLng = math.max(maxLng, p.longitude);
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  /// Returns a [CameraUpdate] that fits all [points] with optional padding.
  static CameraUpdate? fitPoints(
    List<LatLng> points, {
    double padding = 60,
  }) {
    final bounds = boundsFromPoints(points);
    if (bounds == null) return null;
    return CameraUpdate.newLatLngBounds(bounds, padding);
  }

  // ── Distance ──────────────────────────────────────────────────────────────

  /// Haversine distance in meters between two coordinates.
  static double distanceMeters(LatLng a, LatLng b) {
    const r = 6371000.0; // Earth radius in meters
    final lat1 = _rad(a.latitude);
    final lat2 = _rad(b.latitude);
    final dLat = _rad(b.latitude - a.latitude);
    final dLng = _rad(b.longitude - a.longitude);

    final h = math.pow(math.sin(dLat / 2), 2) +
        math.cos(lat1) * math.cos(lat2) * math.pow(math.sin(dLng / 2), 2);

    return 2 * r * math.asin(math.sqrt(h));
  }

  static double _rad(double deg) => deg * math.pi / 180;

  // ── Polylines ─────────────────────────────────────────────────────────────

  /// Builds a route [Polyline] from a list of coordinates.
  static Polyline buildRoutePolyline({
    required String id,
    required List<LatLng> points,
    Color color = const Color(0xFF00B4D8),
    int width = MapConfig.routePolylineWidth,
    bool geodesic = true,
  }) =>
      Polyline(
        polylineId: PolylineId(id),
        points: points,
        color: color,
        width: width,
        geodesic: geodesic,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
      );

  // ── Circles (geofence) ────────────────────────────────────────────────────

  /// Builds a [Circle] for visualising a circular geofence.
  static Circle buildGeofenceCircle({
    required String id,
    required LatLng center,
    required double radiusMeters,
    Color strokeColor = const Color(0xFF00B4D8),
    Color fillColor = const Color(0x1A00B4D8),
    int strokeWidth = 2,
  }) =>
      Circle(
        circleId: CircleId(id),
        center: center,
        radius: radiusMeters,
        strokeColor: strokeColor,
        strokeWidth: strokeWidth,
        fillColor: fillColor,
      );

  // ── Polygons (geofence) ───────────────────────────────────────────────────

  /// Builds a [Polygon] for visualising a polygon geofence.
  static Polygon buildGeofencePolygon({
    required String id,
    required List<LatLng> points,
    Color strokeColor = const Color(0xFF00B4D8),
    Color fillColor = const Color(0x1A00B4D8),
    int strokeWidth = 2,
  }) =>
      Polygon(
        polygonId: PolygonId(id),
        points: points,
        strokeColor: strokeColor,
        strokeWidth: strokeWidth,
        fillColor: fillColor,
      );

  // ── WKT parsing ───────────────────────────────────────────────────────────

  /// Parse a WKT POLYGON string into a list of [LatLng].
  static List<LatLng> parsePolygonWkt(String wkt) {
    final match = RegExp(r'POLYGON\s*\(\((.+)\)\)', caseSensitive: false)
        .firstMatch(wkt);
    if (match == null) return [];

    return match
        .group(1)!
        .split(',')
        .map((pair) {
          final parts = pair.trim().split(RegExp(r'\s+'));
          if (parts.length < 2) return null;
          return LatLng(
            double.tryParse(parts[1]) ?? 0,
            double.tryParse(parts[0]) ?? 0,
          );
        })
        .whereType<LatLng>()
        .toList();
  }
}
