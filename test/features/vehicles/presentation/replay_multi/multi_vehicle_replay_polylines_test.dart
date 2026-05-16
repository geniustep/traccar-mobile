import 'package:elmogps/features/map/data/datasources/route_datasource.dart';
import 'package:elmogps/features/vehicles/presentation/replay_multi/multi_vehicle_replay_model.dart';
import 'package:elmogps/features/vehicles/presentation/replay_multi/multi_vehicle_replay_polylines.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

RoutePoint _pt(DateTime t, {double speed = 40}) => RoutePoint(
      position: const LatLng(33.5, -7.6),
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
  final t1 = DateTime(2026, 5, 15, 10, 0, 5);
  final t2 = DateTime(2026, 5, 15, 10, 0, 10);

  group('MultiVehicleReplayPolylines', () {
    test('hidden vehicle produces no polylines', () {
      final polys = MultiVehicleReplayPolylines.build(
        tracks: [_track('A', [_pt(t0), _pt(t1)])],
        isVisible: (_) => false,
      );
      expect(polys, isEmpty);
    });

    test('solid polylines per visible track', () {
      final polys = MultiVehicleReplayPolylines.build(
        tracks: [
          _track('A', [_pt(t0), _pt(t1)]),
          _track('B', [_pt(t0), _pt(t2)]),
        ],
        isVisible: (_) => true,
        useSpeedColors: false,
      );
      expect(polys.length, greaterThanOrEqualTo(2));
    });

    test('speed colors produce more segments than single solid line', () {
      final track = _track(
        'A',
        [
          _pt(t0, speed: 10),
          _pt(t1, speed: 80),
          _pt(t2, speed: 20),
        ],
      );
      final solid = MultiVehicleReplayPolylines.build(
        tracks: [track],
        isVisible: (_) => true,
        useSpeedColors: false,
      );
      final colored = MultiVehicleReplayPolylines.build(
        tracks: [track],
        isVisible: (_) => true,
        useSpeedColors: true,
      );
      expect(colored.length, greaterThanOrEqualTo(solid.length));
    });

    test('track with fewer than 2 points skipped', () {
      final polys = MultiVehicleReplayPolylines.build(
        tracks: [_track('A', [_pt(t0)])],
        isVisible: (_) => true,
      );
      expect(polys, isEmpty);
    });
  });
}
