import 'dart:convert';

import 'package:flutter/material.dart';

import '../../domain/entities/geofence.dart';

class GeofenceModel {
  const GeofenceModel({
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
  final String area;
  final int? calendarId;
  final Map<String, dynamic> attributes;

  factory GeofenceModel.fromJson(Map<String, dynamic> json) => GeofenceModel(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String? ?? '',
        description: json['description'] as String?,
        area: json['area'] as String? ?? '',
        calendarId: (json['calendarId'] as num?)?.toInt(),
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

  Map<String, dynamic> toCreateJson() => {
        'name': name,
        if (description != null) 'description': description,
        'area': area,
        if (calendarId != null) 'calendarId': calendarId,
        'attributes': attributes,
      };

  GeofenceEntity toEntity() {
    final ids = _parseDeviceIds(attributes);
    final base = _parseColor(attributes['elmoColor'] as String?) ??
        const Color(0xFF2196F3);
    return GeofenceEntity(
      id: id,
      name: name,
      description: description,
      area: area,
      calendarId: calendarId,
      attributes: attributes,
      linkedDeviceIds: ids,
      fillColor: base.withValues(alpha: 0.35),
    );
  }

  static List<int> _parseDeviceIds(Map<String, dynamic> attrs) {
    final raw = attrs['elmoDeviceIds'];
    if (raw == null) return [];
    try {
      if (raw is String) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded.map((e) => (e as num).toInt()).toList();
        }
      }
      if (raw is List) {
        return raw.map((e) => (e as num).toInt()).toList();
      }
    } catch (_) {}
    return [];
  }

  static Color? _parseColor(String? s) {
    if (s == null || s.isEmpty) return null;
    var v = s.trim();
    if (v.startsWith('#')) {
      v = v.substring(1);
      if (v.length == 6) {
        final rgb = int.tryParse(v, radix: 16);
        if (rgb != null) return Color(0xFF000000 | rgb);
      }
    }
    return null;
  }

  static Map<String, dynamic> attrsWithDevicesAndColor(
    Map<String, dynamic> base,
    List<int> deviceIds,
    Color color,
  ) {
    final next = Map<String, dynamic>.from(base);
    next['elmoDeviceIds'] = jsonEncode(deviceIds);
    final r = color.red;
    final g = color.green;
    final b = color.blue;
    next['elmoColor'] =
        '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}';
    return next;
  }
}
