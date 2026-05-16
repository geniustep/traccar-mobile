import 'package:elmogps/features/map/data/datasources/route_datasource.dart';
import 'package:elmogps/features/reports/core/replay_route_gap.dart';
import 'package:elmogps/features/vehicles/presentation/replay_multi/multi_replay_kpi.dart';
import 'package:elmogps/features/vehicles/presentation/replay_multi/multi_vehicle_replay_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

RoutePoint _pt(
  DateTime t, {
  double lat = 33.5,
  double lng = -7.6,
  double speed = 40,
}) =>
    RoutePoint(
      position: LatLng(lat, lng),
      speed: speed,
      course: 90,
      fixTime: t,
      ignition: true,
    );

MultiVehicleReplayTrack _track(String id, List<RoutePoint> points) =>
    MultiVehicleReplayTrack(
      vehicleId: id,
      name: id,
      colorIndex: 0,
      allPoints: points,
      mapPoints: points,
    );

void main() {
  final t0 = DateTime(2026, 5, 15, 10, 0, 0);
  final t1 = DateTime(2026, 5, 15, 10, 0, 30);
  final t2 = DateTime(2026, 5, 15, 10, 1, 0);
  final tGap = DateTime(2026, 5, 15, 10, 20, 0);

  group('MultiReplayKpiCalculator', () {
    test('empty track hasEnoughData false', () {
      final kpi = MultiReplayKpiCalculator.computeForTrack(
        _track('A', const []),
      );
      expect(kpi.hasEnoughData, isFalse);
      expect(kpi.totalDistanceMeters, isNull);
    });

    test('single point hasEnoughData false and no crash', () {
      final kpi = MultiReplayKpiCalculator.computeForTrack(
        _track('A', [_pt(t0)]),
      );
      expect(kpi.hasEnoughData, isFalse);
      expect(kpi.firstPointTime, t0);
    });

    test('distance between two valid points', () {
      final kpi = MultiReplayKpiCalculator.computeForTrack(
        _track('A', [
          _pt(t0, lat: 33.5, lng: -7.6),
          _pt(t1, lat: 33.51, lng: -7.6, speed: 50),
        ]),
      );
      expect(kpi.hasEnoughData, isTrue);
      expect(kpi.totalDistanceMeters, greaterThan(0));
    });

    test('does not count distance across gap', () {
      final withGap = MultiReplayKpiCalculator.computeForTrack(
        _track('A', [
          _pt(t0, lat: 33.5),
          _pt(tGap, lat: 34.0, speed: 50),
        ]),
      );
      final continuous = MultiReplayKpiCalculator.computeForTrack(
        _track('B', [
          _pt(t0, lat: 33.5),
          _pt(t1, lat: 33.51, speed: 50),
        ]),
      );
      expect(withGap.totalDistanceMeters ?? 0, 0);
      expect(continuous.totalDistanceMeters, greaterThan(0));
    });

    test('moving duration when speed >= 5', () {
      final kpi = MultiReplayKpiCalculator.computeForTrack(
        _track('A', [
          _pt(t0, speed: 40),
          _pt(t1, speed: 40),
        ]),
      );
      expect(kpi.movingDuration, const Duration(seconds: 30));
      expect(kpi.stoppedDuration, Duration.zero);
    });

    test('stopped duration when speed < 5', () {
      final kpi = MultiReplayKpiCalculator.computeForTrack(
        _track('A', [
          _pt(t0, speed: 2),
          _pt(t1, speed: 2),
        ]),
      );
      expect(kpi.stoppedDuration, const Duration(seconds: 30));
      expect(kpi.movingDuration, Duration.zero);
    });

    test('does not count duration across gap', () {
      final kpi = MultiReplayKpiCalculator.computeForTrack(
        _track('A', [
          _pt(t0, speed: 40),
          _pt(tGap, speed: 40),
        ]),
      );
      expect(kpi.movingDuration, Duration.zero);
    });

    test('maxSpeed from valid points', () {
      final kpi = MultiReplayKpiCalculator.computeForTrack(
        _track('A', [
          _pt(t0, speed: 30),
          _pt(t1, speed: 95),
          _pt(t2, speed: 50),
        ]),
      );
      expect(kpi.maxSpeedKmh, 95);
    });

    test('averageMovingSpeed excludes stopped segments', () {
      final kpi = MultiReplayKpiCalculator.computeForTrack(
        _track('A', [
          _pt(t0, speed: 60, lat: 33.5),
          _pt(t1, speed: 60, lat: 33.501),
          _pt(t2, speed: 2, lat: 33.502),
        ]),
      );
      expect(kpi.movingDuration.inSeconds, greaterThan(0));
      expect(kpi.averageMovingSpeedKmh, isNotNull);
      expect(kpi.averageMovingSpeedKmh!, greaterThan(0));
    });

    test('stopsCount from RouteEventAnalyzer', () {
      final stopStart = DateTime(2026, 5, 15, 10, 0, 0);
      final stopMid = DateTime(2026, 5, 15, 10, 5, 0);
      final stopEnd = DateTime(2026, 5, 15, 10, 10, 0);
      final kpi = MultiReplayKpiCalculator.computeForTrack(
        _track('A', [
          _pt(stopStart, speed: 0),
          _pt(stopMid, speed: 0),
          _pt(stopEnd, speed: 50),
        ]),
      );
      expect(kpi.stopsCount, greaterThanOrEqualTo(1));
    });

    test('overspeedCount uses default 80 km/h threshold', () {
      final kpi = MultiReplayKpiCalculator.computeForTrack(
        _track('A', [
          _pt(t0, speed: 90),
          _pt(t1, speed: 95),
          _pt(t2, speed: 40),
        ]),
      );
      expect(kpi.overspeedCount, greaterThanOrEqualTo(1));
    });

    test('summary picks longest distance', () {
      final summary = MultiReplayKpiCalculator.buildSummary([
        _track('A', [
          _pt(t0, lat: 33.5, lng: -7.6),
          _pt(t1, lat: 33.5005, lng: -7.6, speed: 50),
        ]),
        _track('B', [
          _pt(t0, lat: 33.5, lng: -7.6),
          _pt(t1, lat: 33.502, lng: -7.6, speed: 50),
        ]),
      ]);
      final insight = summary.insights.firstWhere(
        (i) => i.kind == MultiReplayInsightKind.longestDistance,
      );
      expect(insight.vehicleId, 'B');
    });

    test('summary picks highest max speed', () {
      final summary = MultiReplayKpiCalculator.buildSummary([
        _track('A', [_pt(t0, speed: 50), _pt(t1, speed: 55)]),
        _track('B', [_pt(t0, speed: 50), _pt(t1, speed: 120)]),
      ]);
      final insight = summary.insights.firstWhere(
        (i) => i.kind == MultiReplayInsightKind.highestMaxSpeed,
      );
      expect(insight.vehicleId, 'B');
    });

    test('summary empty when fewer than 2 vehicles with data', () {
      final summary = MultiReplayKpiCalculator.buildSummary([
        _track('A', [_pt(t0), _pt(t1)]),
        _track('B', const []),
      ]);
      expect(summary.insights, isEmpty);
    });

    test('invalid coordinates ignored for distance', () {
      final kpi = MultiReplayKpiCalculator.computeForTrack(
        _track('A', [
          _pt(t0, lat: 0, lng: 0),
          _pt(t1, lat: 33.51, lng: -7.6),
        ]),
      );
      expect(kpi.hasEnoughData, isFalse);
    });

    test('five vehicles summary builds without crash', () {
      final tracks = List.generate(
        5,
        (i) => _track(
          'V$i',
          [
            _pt(t0.add(Duration(minutes: i)), speed: 40.0 + i),
            _pt(t1, speed: 50),
          ],
        ),
      );
      final summary = MultiReplayKpiCalculator.buildSummary(tracks);
      expect(summary.kpisByVehicleId.length, 5);
    });
  });
}
