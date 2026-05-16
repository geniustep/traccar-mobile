import 'package:elmogps/features/map/data/datasources/route_datasource.dart';
import 'package:elmogps/features/reports/core/replay_motion_helper.dart';
import 'package:elmogps/features/reports/core/replay_route_gap.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  RoutePoint pt(
    DateTime t,
    double lat,
    double lng, {
    double speed = 40,
  }) =>
      RoutePoint(
        position: LatLng(lat, lng),
        speed: speed,
        course: 90,
        fixTime: t,
        ignition: true,
      );

  final t0 = DateTime.utc(2024, 6, 1, 10);
  final t1 = t0.add(const Duration(minutes: 2));

  test('canInterpolateBetween true for close valid points', () {
    expect(
      canInterpolateBetween(
        pt(t0, 33.5, -7.6),
        pt(t1, 33.51, -7.61),
      ),
      isTrue,
    );
  });

  test('canInterpolateBetween false when delta exceeds gap threshold', () {
    final far = t0.add(const Duration(minutes: 11));
    expect(
      canInterpolateBetween(pt(t0, 33.5, -7.6), pt(far, 33.6, -7.7)),
      isFalse,
    );
  });

  test('canInterpolateBetween false when delta <= 0', () {
    expect(
      canInterpolateBetween(pt(t0, 33.5, -7.6), pt(t0, 33.51, -7.61)),
      isFalse,
    );
  });

  test('canInterpolateBetween false for invalid coordinates', () {
    expect(
      canInterpolateBetween(
        pt(t0, 0, 0),
        pt(t1, 33.51, -7.61),
      ),
      isFalse,
    );
  });

  test('canInterpolateBetween false across known gap', () {
    final gapStart = t0;
    final gapEnd = t0.add(const Duration(minutes: 15));
    final gaps = [
      ReplayRouteGap(
        indexBefore: 0,
        indexAfter: 1,
        gapStartTime: gapStart,
        gapEndTime: gapEnd,
        duration: const Duration(minutes: 15),
        markerPosition: const LatLng(33.5, -7.6),
      ),
    ];
    expect(
      canInterpolateBetween(
        pt(t0, 33.5, -7.6),
        pt(gapEnd, 33.6, -7.7),
        knownGaps: gaps,
      ),
      isFalse,
    );
  });

  test('canInterpolateBetween false for implausible speed', () {
    final far = t0.add(const Duration(seconds: 10));
    expect(
      canInterpolateBetween(
        pt(t0, 33.5, -7.6),
        pt(far, 35.0, -5.0),
      ),
      isFalse,
    );
  });

  test('snapshot source point differs from interpolated visual', () {
    final a = pt(t0, 33.5, -7.6);
    final b = pt(t1, 33.6, -7.7);
    final visual = interpolateRoutePoint(a, b, 0.5);
    expect(visual.fixTime, a.fixTime);
    expect(visual.position.latitude, isNot(b.position.latitude));
    expect(b.fixTime, t1);
  });

  test('interpolateRoutePoint keeps fixTime from origin', () {
    final a = pt(t0, 33.5, -7.6);
    final b = pt(t1, 33.6, -7.7);
    final mid = interpolateRoutePoint(a, b, 0.5);
    expect(mid.fixTime, t0);
    expect(mid.position.latitude, closeTo(33.55, 0.01));
  });
}
