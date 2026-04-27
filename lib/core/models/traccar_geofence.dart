/// Traccar Geofence — a geographic boundary that triggers events.
/// Maps to `/geofences` API endpoint.
class TraccarGeofence {
  const TraccarGeofence({
    required this.id,
    required this.name,
    required this.area,
    this.description,
    this.calendarId,
    this.attributes = const {},
  });

  final int id;
  final String name;
  final String? description;

  /// WKT area string, e.g.:
  /// - Circle: CIRCLE(lat lng, radius_meters)
  /// - Polygon: POLYGON((lng lat, lng lat, …))
  /// - Linestring: LINESTRING(lng lat, …)
  final String area;

  /// Optional calendar restriction
  final int? calendarId;

  final Map<String, dynamic> attributes;

  // ── Computed ──────────────────────────────────────────────────────────────

  GeofenceType get type {
    if (area.startsWith('CIRCLE')) return GeofenceType.circle;
    if (area.startsWith('POLYGON')) return GeofenceType.polygon;
    if (area.startsWith('LINESTRING')) return GeofenceType.linestring;
    return GeofenceType.unknown;
  }

  /// Parse circle center and radius from WKT.
  /// Returns null if the area is not a circle.
  CircleArea? get circleArea {
    if (type != GeofenceType.circle) return null;
    final match =
        RegExp(r'CIRCLE\s*\(\s*([-\d.]+)\s+([-\d.]+)\s*,\s*([-\d.]+)\s*\)')
            .firstMatch(area);
    if (match == null) return null;
    return CircleArea(
      lat: double.parse(match.group(1)!),
      lng: double.parse(match.group(2)!),
      radiusMeters: double.parse(match.group(3)!),
    );
  }

  // ── Serialisation ─────────────────────────────────────────────────────────

  factory TraccarGeofence.fromJson(Map<String, dynamic> json) =>
      TraccarGeofence(
        id: json['id'] as int,
        name: json['name'] as String? ?? 'Unnamed',
        description: json['description'] as String?,
        area: json['area'] as String? ?? '',
        calendarId: json['calendarId'] as int?,
        attributes:
            Map<String, dynamic>.from(json['attributes'] as Map? ?? {}),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (description != null) 'description': description,
        'area': area,
        if (calendarId != null) 'calendarId': calendarId,
        'attributes': attributes,
      };

  @override
  String toString() =>
      'TraccarGeofence(id: $id, name: $name, type: ${type.name})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is TraccarGeofence && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

enum GeofenceType { circle, polygon, linestring, unknown }

class CircleArea {
  const CircleArea({
    required this.lat,
    required this.lng,
    required this.radiusMeters,
  });

  final double lat;
  final double lng;
  final double radiusMeters;

  @override
  String toString() =>
      'CircleArea(lat: $lat, lng: $lng, r: ${radiusMeters}m)';
}
