import 'package:flutter/material.dart';

import '../../../../core/models/traccar_geofence.dart';

/// Domain entity for a Traccar geofence plus app-side metadata in [attributes].
class GeofenceEntity {
  const GeofenceEntity({
    required this.id,
    required this.name,
    required this.area,
    this.description,
    this.calendarId,
    this.attributes = const {},
    this.linkedDeviceIds = const [],
    this.fillColor = const Color(0x802196F3),
  });

  final int id;
  final String name;
  final String? description;
  final String area;
  final int? calendarId;
  final Map<String, dynamic> attributes;

  /// Persisted in Traccar `attributes.elmoDeviceIds` (JSON array string).
  final List<int> linkedDeviceIds;

  /// ARGB color for map / editor (from `attributes.elmoColor`).
  final Color fillColor;

  GeofenceType get shapeType => TraccarGeofence(
        id: id,
        name: name,
        area: area,
        attributes: attributes,
      ).type;

  bool get isCircle => shapeType == GeofenceType.circle;
  bool get isPolygon => shapeType == GeofenceType.polygon;

  GeofenceEntity copyWith({
    String? name,
    String? area,
    String? description,
    int? calendarId,
    Map<String, dynamic>? attributes,
    List<int>? linkedDeviceIds,
    Color? fillColor,
  }) {
    return GeofenceEntity(
      id: id,
      name: name ?? this.name,
      area: area ?? this.area,
      description: description ?? this.description,
      calendarId: calendarId ?? this.calendarId,
      attributes: attributes ?? this.attributes,
      linkedDeviceIds: linkedDeviceIds ?? this.linkedDeviceIds,
      fillColor: fillColor ?? this.fillColor,
    );
  }
}
