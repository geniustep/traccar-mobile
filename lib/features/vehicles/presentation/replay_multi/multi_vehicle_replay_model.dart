import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../map/data/datasources/route_datasource.dart';

/// Hard limits for multi-vehicle replay (Phase D).
abstract final class MultiVehicleReplayLimits {
  MultiVehicleReplayLimits._();

  static const int minVehicles = 2;
  static const int maxVehicles = 5;
  static const int maxPointsPerVehicle = 900;
}

/// Distinct colors for up to 5 vehicles on the map.
abstract final class MultiVehicleReplayColors {
  MultiVehicleReplayColors._();

  static const List<Color> palette = [
    Color(0xFF2563EB),
    Color(0xFF16A34A),
    Color(0xFFEA580C),
    Color(0xFF9333EA),
    Color(0xFFDC2626),
  ];

  static Color forIndex(int index) =>
      palette[index.clamp(0, palette.length - 1)];
}

/// One vehicle's route data for replay.
class MultiVehicleReplayTrack {
  const MultiVehicleReplayTrack({
    required this.vehicleId,
    required this.name,
    required this.colorIndex,
    required this.allPoints,
    required this.mapPoints,
    this.loadError,
  });

  final String vehicleId;
  final String name;
  final int colorIndex;

  /// Full sorted points (for timeline / markers).
  final List<RoutePoint> allPoints;

  /// Decimated points for polyline drawing.
  final List<RoutePoint> mapPoints;

  /// Non-null when the route request failed.
  final Object? loadError;

  bool get hasData => allPoints.isNotEmpty;

  Color get color => MultiVehicleReplayColors.forIndex(colorIndex);

  double? get distanceMeters {
    if (allPoints.length < 2) return null;
    var total = 0.0;
    for (var i = 1; i < allPoints.length; i++) {
      total += _haversineMeters(
        allPoints[i - 1].position,
        allPoints[i].position,
      );
    }
    return total;
  }

  static double _haversineMeters(LatLng a, LatLng b) {
    const earthRadius = 6371000.0;
    final dLat = _toRad(b.latitude - a.latitude);
    final dLng = _toRad(b.longitude - a.longitude);
    final lat1 = _toRad(a.latitude);
    final lat2 = _toRad(b.latitude);
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return 2 * earthRadius * math.asin(math.sqrt(h));
  }

  static double _toRad(double deg) => deg * math.pi / 180;
}
