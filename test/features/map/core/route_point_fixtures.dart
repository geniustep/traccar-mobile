import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:elmogps/features/map/data/datasources/route_datasource.dart';

/// Test-only [RoutePoint] factory (avoid JSON / Traccar).
RoutePoint testRoutePoint(
  LatLng position,
  double speedKmh,
  DateTime fixTime, {
  double course = 0,
  bool ignition = false,
}) =>
    RoutePoint(
      position: position,
      speed: speedKmh,
      course: course,
      fixTime: fixTime,
      ignition: ignition,
    );

DateTime utc(int y, int m, int d, [int h = 0, int min = 0, int s = 0]) =>
    DateTime.utc(y, m, d, h, min, s);
