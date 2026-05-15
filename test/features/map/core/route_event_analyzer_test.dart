import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:elmogps/features/map/core/route_event_analyzer.dart';
import 'package:elmogps/features/map/core/route_intelligence_thresholds.dart';

import 'route_point_fixtures.dart';

void main() {
  const pos = LatLng(10.0, 20.0);

  group('RouteEventAnalyzer — stops', () {
    test('no stop when segment shorter than minStopDuration', () {
      final t0 = utc(2024, 6, 1, 10, 0);
      final pts = [
        testRoutePoint(pos, 2, t0),
        testRoutePoint(pos, 2, t0.add(const Duration(minutes: 1))),
        testRoutePoint(pos, 2, t0.add(const Duration(minutes: 2))),
        testRoutePoint(pos, 2, t0.add(const Duration(minutes: 3))),
        testRoutePoint(pos, 10, t0.add(const Duration(minutes: 4))),
      ];
      final r = RouteEventAnalyzer.analyze(pts);
      expect(r.stops, isEmpty);
    });

    test('one stop when speed below enter long enough then exit above exit', () {
      final t0 = utc(2024, 6, 1, 10, 0);
      final pts = [
        testRoutePoint(pos, 2, t0),
        testRoutePoint(pos, 2, t0.add(const Duration(minutes: 1))),
        testRoutePoint(pos, 2, t0.add(const Duration(minutes: 2))),
        testRoutePoint(pos, 2, t0.add(const Duration(minutes: 3))),
        testRoutePoint(pos, 2, t0.add(const Duration(minutes: 4))),
        testRoutePoint(pos, 2, t0.add(const Duration(minutes: 5))),
        testRoutePoint(pos, 10, t0.add(const Duration(minutes: 6))),
      ];
      final r = RouteEventAnalyzer.analyze(pts);
      expect(r.stops, hasLength(1));
      expect(r.stops.single.startTime, t0);
      expect(r.stops.single.endTime, t0.add(const Duration(minutes: 5)));
    });

    test('leaves stop when speed strictly above stopSpeedExitKmh', () {
      final th = const RouteIntelligenceThresholds(
        stopSpeedEnterKmh: 3,
        stopSpeedExitKmh: 5,
        minStopDuration: Duration(minutes: 1),
      );
      final t0 = utc(2024, 6, 1, 12, 0);
      final pts = [
        testRoutePoint(pos, 2, t0),
        testRoutePoint(pos, 2, t0.add(const Duration(minutes: 2))),
        testRoutePoint(pos, 6, t0.add(const Duration(minutes: 3))),
      ];
      final r = RouteEventAnalyzer.analyze(pts, thresholds: th);
      expect(r.stops, hasLength(1));
      expect(r.stops.single.endTime, t0.add(const Duration(minutes: 2)));
    });

    test('hysteresis: speed between enter and exit does not break stop', () {
      final th = const RouteIntelligenceThresholds(
        stopSpeedEnterKmh: 3,
        stopSpeedExitKmh: 5,
        minStopDuration: Duration(minutes: 2),
      );
      final t0 = utc(2024, 6, 1, 8, 0);
      final pts = [
        testRoutePoint(pos, 2, t0),
        testRoutePoint(pos, 4, t0.add(const Duration(minutes: 1))),
        testRoutePoint(pos, 4, t0.add(const Duration(minutes: 2))),
        testRoutePoint(pos, 4, t0.add(const Duration(minutes: 3))),
        testRoutePoint(pos, 10, t0.add(const Duration(minutes: 4))),
      ];
      final r = RouteEventAnalyzer.analyze(pts, thresholds: th);
      expect(r.stops, hasLength(1));
      expect(r.stops.single.startTime, t0);
    });

    test('detectStops false yields no stops; overspeed still detected', () {
      final t0 = utc(2024, 6, 1, 9, 0);
      final pts = [
        testRoutePoint(pos, 2, t0),
        testRoutePoint(pos, 2, t0.add(const Duration(minutes: 10))),
        testRoutePoint(pos, 95, t0.add(const Duration(minutes: 11))),
        testRoutePoint(pos, 95, t0.add(const Duration(minutes: 12))),
        testRoutePoint(pos, 0, t0.add(const Duration(minutes: 13))),
      ];
      const th = RouteIntelligenceThresholds(
        detectStops: false,
        detectOverspeed: true,
      );
      final r = RouteEventAnalyzer.analyze(pts, thresholds: th);
      expect(r.stops, isEmpty);
      expect(r.overspeeds, isNotEmpty);
    });
  });

  group('RouteEventAnalyzer — overspeed', () {
    test('no overspeed when all speeds ≤ threshold (> not ≥)', () {
      final t0 = utc(2024, 6, 2, 7, 0);
      final pts = [
        testRoutePoint(pos, 79, t0),
        testRoutePoint(pos, 80, t0.add(const Duration(seconds: 10))),
      ];
      final r = RouteEventAnalyzer.analyze(pts);
      expect(r.overspeeds, isEmpty);
    });

    test('single overspeed contiguous run emits one peak event', () {
      final t0 = utc(2024, 6, 2, 7, 0);
      final pts = [
        testRoutePoint(pos, 70, t0),
        testRoutePoint(pos, 92, t0.add(const Duration(seconds: 1))),
        testRoutePoint(pos, 88, t0.add(const Duration(seconds: 2))),
        testRoutePoint(pos, 93, t0.add(const Duration(seconds: 3))),
        testRoutePoint(pos, 74, t0.add(const Duration(seconds: 4))),
      ];
      final r = RouteEventAnalyzer.analyze(pts);
      expect(r.overspeeds, hasLength(1));
      expect(r.overspeeds.single.speed, 93);
    });

    test('peak holds max speed inside the run', () {
      final t0 = utc(2024, 6, 2, 8, 0);
      final pts = [
        testRoutePoint(pos, 130, t0.add(const Duration(seconds: 10))),
        testRoutePoint(pos, 110, t0.add(const Duration(seconds: 11))),
      ];
      final r = RouteEventAnalyzer.analyze(pts);
      expect(r.overspeeds.single.speed, 130);
    });

    test('two separate runs produce two events', () {
      final t0 = utc(2024, 6, 2, 9, 0);
      final pts = [
        testRoutePoint(pos, 90, t0),
        testRoutePoint(pos, 73, t0.add(const Duration(seconds: 1))),
        testRoutePoint(pos, 85, t0.add(const Duration(seconds: 2))),
      ];
      final r = RouteEventAnalyzer.analyze(pts);
      expect(r.overspeeds, hasLength(2));
      expect(r.overspeeds.map((e) => e.speed), containsAll(<double>[90, 85]));
    });

    test('lower overspeedThresholdKmh increases event count', () {
      final t0 = utc(2024, 6, 2, 10, 0);
      final pts = [
        testRoutePoint(pos, 48, t0),
        testRoutePoint(pos, 52, t0.add(const Duration(seconds: 1))),
        testRoutePoint(pos, 48, t0.add(const Duration(seconds: 2))),
      ];
      final highTh = RouteEventAnalyzer.analyze(
        pts,
        thresholds: const RouteIntelligenceThresholds(overspeedThresholdKmh: 55),
      );
      final lowTh = RouteEventAnalyzer.analyze(
        pts,
        thresholds: const RouteIntelligenceThresholds(overspeedThresholdKmh: 50),
      );
      expect(highTh.overspeeds, isEmpty);
      expect(lowTh.overspeeds, hasLength(1));
    });

    test('detectOverspeed false yields no overspeed events', () {
      final t0 = utc(2024, 6, 2, 11, 0);
      final pts = [
        testRoutePoint(pos, 120, t0),
        testRoutePoint(pos, 120, t0.add(const Duration(seconds: 1))),
      ];
      const th = RouteIntelligenceThresholds(
        detectOverspeed: false,
      );
      final r = RouteEventAnalyzer.analyze(pts, thresholds: th);
      expect(r.overspeeds, isEmpty);
    });
  });

  group('RouteEventAnalyzer — ignition', () {
    test('uniform false: no ignition events and not likely', () {
      final t0 = utc(2024, 6, 3, 6, 0);
      final pts = [
        testRoutePoint(pos, 0, t0, ignition: false),
        testRoutePoint(pos, 0, t0.add(const Duration(seconds: 5)), ignition: false),
        testRoutePoint(pos, 0, t0.add(const Duration(seconds: 10)), ignition: false),
      ];
      final r = RouteEventAnalyzer.analyze(pts);
      expect(r.ignitions, isEmpty);
      expect(r.ignitionDataLikelyPresent, false);
    });

    test('false → true emits ignition on at second point', () {
      final t0 = utc(2024, 6, 3, 7, 0);
      final t1 = t0.add(const Duration(seconds: 1));
      final pts = [
        testRoutePoint(pos, 0, t0, ignition: false),
        testRoutePoint(pos, 0, t1, ignition: true),
      ];
      final r = RouteEventAnalyzer.analyze(pts);
      expect(r.ignitions, hasLength(1));
      expect(r.ignitions.single.on, true);
      expect(r.ignitions.single.time, t1);
      expect(r.ignitionDataLikelyPresent, true);
    });

    test('true → false emits ignition off', () {
      final t0 = utc(2024, 6, 3, 8, 0);
      final t1 = t0.add(const Duration(seconds: 1));
      final pts = [
        testRoutePoint(pos, 0, t0, ignition: true),
        testRoutePoint(pos, 0, t1, ignition: false),
      ];
      final r = RouteEventAnalyzer.analyze(pts);
      expect(r.ignitions.single.on, false);
      expect(r.ignitions.single.time, t1);
    });

    test('multiple transitions stay ordered by time', () {
      final t0 = utc(2024, 6, 3, 9, 0);
      final pts = [
        testRoutePoint(pos, 0, t0, ignition: false),
        testRoutePoint(pos, 0, t0.add(const Duration(seconds: 1)), ignition: true),
        testRoutePoint(pos, 0, t0.add(const Duration(seconds: 2)), ignition: false),
        testRoutePoint(pos, 0, t0.add(const Duration(seconds: 3)), ignition: true),
      ];
      final r = RouteEventAnalyzer.analyze(pts);
      expect(r.ignitions, hasLength(3));
      final times = r.ignitions.map((e) => e.time).toList();
      expect(times, orderedEquals(<DateTime>[
        t0.add(const Duration(seconds: 1)),
        t0.add(const Duration(seconds: 2)),
        t0.add(const Duration(seconds: 3)),
      ]));
    });

    test('detectIgnition false hides ignition and sets likely false', () {
      final t0 = utc(2024, 6, 3, 10, 0);
      final pts = [
        testRoutePoint(pos, 0, t0, ignition: false),
        testRoutePoint(pos, 0, t0.add(const Duration(seconds: 1)), ignition: true),
      ];
      const th = RouteIntelligenceThresholds(detectIgnition: false);
      final r = RouteEventAnalyzer.analyze(pts, thresholds: th);
      expect(r.ignitions, isEmpty);
      expect(r.ignitionDataLikelyPresent, false);
    });

    test('uniform true: no synthesized transitions; lists stay empty but likely true', () {
      final t0 = utc(2024, 6, 3, 11, 0);
      final pts = [
        testRoutePoint(pos, 40, t0, ignition: true),
        testRoutePoint(pos, 40, t0.add(const Duration(seconds: 30)), ignition: true),
      ];
      final r = RouteEventAnalyzer.analyze(pts);
      expect(r.ignitions, isEmpty);
      expect(r.ignitionDataLikelyPresent, true);
    });
  });

  group('RouteEventAnalyzer — edge', () {
    test('empty list', () {
      final r = RouteEventAnalyzer.analyze([]);
      expect(r.summary.maxSpeed, 0);
      expect(r.stops, isEmpty);
    });

    test('single point', () {
      final t0 = utc(2024, 6, 4, 1, 0);
      final r = RouteEventAnalyzer.analyze([testRoutePoint(pos, 40, t0)]);
      expect(r.stops, isEmpty);
      expect(r.summary.maxSpeed, 40);
    });

    test('null thresholds uses defaults', () {
      final t0 = utc(2024, 6, 4, 2, 0);
      final pts = [
        testRoutePoint(pos, 2, t0),
        testRoutePoint(pos, 2, t0.add(const Duration(minutes: 5))),
        testRoutePoint(pos, 10, t0.add(const Duration(minutes: 6))),
      ];
      final a = RouteEventAnalyzer.analyze(pts, thresholds: null);
      final b = RouteEventAnalyzer.analyze(pts);
      expect(a.stops.length, b.stops.length);
    });
  });
}
