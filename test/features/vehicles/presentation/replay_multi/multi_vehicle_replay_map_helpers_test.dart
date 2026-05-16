import 'package:elmogps/features/map/data/datasources/route_datasource.dart';
import 'package:elmogps/features/vehicles/presentation/replay_multi/multi_vehicle_replay_map_helpers.dart';
import 'package:elmogps/features/vehicles/presentation/replay_multi/multi_vehicle_replay_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

RoutePoint _pt(DateTime t, {double lat = 33.5, double lng = -7.6}) =>
    RoutePoint(
      position: LatLng(lat, lng),
      speed: 40,
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
  final t0 = DateTime(2026, 5, 15, 10);

  group('MultiVehicleReplayMapHelpers', () {
    test('positionsForFit ignores hidden vehicles', () {
      final tracks = [
        _track('A', [_pt(t0, lat: 1)]),
        _track('B', [_pt(t0, lat: 2)]),
      ];
      final positions = MultiVehicleReplayMapHelpers.positionsForFit(
        tracks: tracks,
        isVisible: (id) => id != 'B',
      );
      expect(positions.length, 1);
      expect(positions.first.latitude, 1);
    });

    test('positionsForFit ignores vehicles without map points', () {
      final tracks = [
        _track('A', [_pt(t0)]),
        MultiVehicleReplayTrack(
          vehicleId: 'B',
          name: 'B',
          colorIndex: 1,
          allPoints: const [],
          mapPoints: const [],
        ),
      ];
      final positions = MultiVehicleReplayMapHelpers.positionsForFit(
        tracks: tracks,
        isVisible: (_) => true,
      );
      expect(positions.length, 1);
    });

    test('positionsForFit returns empty when all hidden', () {
      final tracks = [_track('A', [_pt(t0)])];
      final positions = MultiVehicleReplayMapHelpers.positionsForFit(
        tracks: tracks,
        isVisible: (_) => false,
      );
      expect(positions, isEmpty);
    });

    test('cameraUpdateForFit returns null for empty positions', () {
      expect(
        MultiVehicleReplayMapHelpers.cameraUpdateForFit([]),
        isNull,
      );
    });

    test('cameraUpdateForFit returns zoom for single position', () {
      expect(
        MultiVehicleReplayMapHelpers.cameraUpdateForFit(
          [const LatLng(33.5, -7.6)],
        ),
        isNotNull,
      );
    });

    test('preferMarkersOnly uses live marker when provided', () {
      final tracks = [
        _track('A', [_pt(t0, lat: 1), _pt(t0.add(const Duration(hours: 1)), lat: 9)]),
      ];
      final marker = _pt(t0, lat: 5);
      final positions = MultiVehicleReplayMapHelpers.positionsForFit(
        tracks: tracks,
        isVisible: (_) => true,
        markersAtCurrentTime: {'A': marker},
        preferMarkersOnly: true,
      );
      expect(positions.length, 1);
      expect(positions.first.latitude, 5);
    });
  });
}
