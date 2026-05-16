import 'package:elmogps/features/map/data/datasources/route_datasource.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// مسار عادي (~30 دقيقة، نقطة كل دقيقة).
List<RoutePoint> qaNormalRoute({DateTime? start}) {
  final t0 = start ?? DateTime.utc(2024, 6, 1, 8);
  return List.generate(30, (i) {
    return RoutePoint(
      position: LatLng(33.50 + i * 0.001, -7.60 + i * 0.001),
      speed: 20 + (i % 5) * 10,
      course: (i * 15) % 360,
      fixTime: t0.add(Duration(minutes: i)),
      ignition: true,
      attributes: i == 15
          ? {
              'fuel': 62.5,
              'rssi': -75,
              'sat': 12,
            }
          : null,
    );
  });
}

/// مسار فيه فجوة GPS (15 دقيقة بين نقطتين متتاليتين).
List<RoutePoint> qaRouteWithGap({DateTime? start}) {
  final base = qaNormalRoute(start: start);
  final gapStart = base[10].fixTime;
  final afterGap = base.sublist(11).map((p) {
    return RoutePoint(
      position: p.position,
      speed: p.speed,
      course: p.course,
      fixTime: p.fixTime.add(const Duration(minutes: 14)),
      ignition: p.ignition,
      attributes: p.attributes,
    );
  });
  return [...base.sublist(0, 11), ...afterGap];
}

/// مسار طويل (يفحص التقسيم / decimation على الخريطة).
List<RoutePoint> qaLongRoute({int count = 400}) {
  final t0 = DateTime.utc(2024, 6, 2, 6);
  return List.generate(count, (i) {
    return RoutePoint(
      position: LatLng(34.0 + i * 0.0002, -7.0 + i * 0.0002),
      speed: 30 + (i % 7) * 8,
      course: 90,
      fixTime: t0.add(Duration(seconds: i * 30)),
      ignition: true,
    );
  });
}
