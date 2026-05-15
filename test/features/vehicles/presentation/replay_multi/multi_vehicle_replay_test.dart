import 'package:elmogps/core/utils/route_decimator.dart';
import 'package:elmogps/features/map/data/datasources/route_datasource.dart';
import 'package:elmogps/features/vehicles/presentation/replay_multi/multi_vehicle_replay_controller.dart';
import 'package:elmogps/features/vehicles/presentation/replay_multi/multi_vehicle_replay_formatters.dart';
import 'package:elmogps/features/vehicles/presentation/replay_multi/multi_vehicle_replay_model.dart';
import 'package:elmogps/features/vehicles/presentation/replay_multi/multi_vehicle_replay_timeline.dart';
import 'package:elmogps/features/vehicles/presentation/replay_multi/multi_vehicle_replay_ui.dart';
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

MultiVehicleReplayTrack _track(
  String id,
  List<RoutePoint> points, {
  int colorIndex = 0,
}) =>
    MultiVehicleReplayTrack(
      vehicleId: id,
      name: id,
      colorIndex: colorIndex,
      allPoints: points,
      mapPoints: points,
    );

void main() {
  group('MultiVehicleReplayTimelineBuilder validation', () {
    test('reject fewer than 2 vehicles', () {
      expect(
        MultiVehicleReplayTimelineBuilder.validateVehicleCount(0),
        'too_few',
      );
      expect(
        MultiVehicleReplayTimelineBuilder.validateVehicleCount(1),
        'too_few',
      );
      expect(MultiVehicleReplayFormatters.canReplay(1), isFalse);
    });

    test('reject more than 5 vehicles', () {
      expect(
        MultiVehicleReplayTimelineBuilder.validateVehicleCount(6),
        'too_many',
      );
      expect(MultiVehicleReplayFormatters.canReplay(6), isFalse);
    });

    test('accept 2 to 5 vehicles', () {
      expect(MultiVehicleReplayTimelineBuilder.isValidCount(2), isTrue);
      expect(MultiVehicleReplayTimelineBuilder.isValidCount(5), isTrue);
    });
  });

  group('Unified timeline', () {
    final t0 = DateTime(2026, 5, 15, 10, 0, 0);
    final t1 = DateTime(2026, 5, 15, 10, 0, 5);
    final t2 = DateTime(2026, 5, 15, 10, 0, 8);
    final t3 = DateTime(2026, 5, 15, 10, 0, 12);

    test('build unified timeline from two vehicles', () {
      final timeline = MultiVehicleReplayTimelineBuilder.build([
        _track('A', [_pt(t0), _pt(t3)]),
        _track('B', [_pt(t1), _pt(t2)]),
      ]);

      expect(timeline.timestamps, [t0, t1, t2, t3]);
    });

    test('marker position uses latest point at or before current time', () {
      final timeline = MultiVehicleReplayTimelineBuilder.build([
        _track('A', [_pt(t0, lat: 1), _pt(t3, lat: 2)]),
        _track('B', [_pt(t1, lat: 3), _pt(t2, lat: 4)]),
      ]);

      final atMid = DateTime(2026, 5, 15, 10, 0, 10);
      final markers = timeline.markersAtTime(atMid);

      expect(markers['A']?.position.latitude, 1);
      expect(markers['B']?.position.latitude, 4);
    });

    test('vehicle with no points is handled safely', () {
      final timeline = MultiVehicleReplayTimelineBuilder.build([
        _track('A', [_pt(t0)]),
        _track('B', const []),
      ]);

      expect(timeline.markersAtTime(t1)['A'], isNotNull);
      expect(timeline.markersAtTime(t1)['B'], isNull);
    });

    test('partial data works', () {
      final timeline = MultiVehicleReplayTimelineBuilder.build([
        _track('A', [_pt(t0)]),
        _track('B', const [], colorIndex: 1),
      ]);

      expect(timeline.timestamps, [t0]);
      expect(timeline.tracksByVehicleId.length, 2);
    });
  });

  group('Timeline decimation', () {
    test('decimateTimestamps keeps first and last', () {
      final times = List.generate(
        5000,
        (i) => DateTime(2026, 5, 15, 10, 0, i),
      );
      final decimated = MultiVehicleReplayTimelineBuilder.decimateTimestamps(
        times,
        maxCount: 100,
      );
      expect(decimated.first, times.first);
      expect(decimated.last, times.last);
      expect(decimated.length, lessThanOrEqualTo(100));
    });
  });

  group('RoutePointDecimator', () {
    test('decimation keeps first and last point', () {
      final points = List.generate(
        2000,
        (i) => _pt(DateTime(2026, 5, 15, 10, 0, i)),
      );
      final decimated = RoutePointDecimator.decimateForMap(
        points,
        maxPoints: 100,
      );
      expect(decimated.first, points.first);
      expect(decimated.last, points.last);
      expect(decimated.length, lessThanOrEqualTo(100));
    });
  });

  group('Playback visibility', () {
    test('visibility toggle hides vehicle', () {
      final t0 = DateTime(2026, 5, 15, 10);
      final timeline = MultiVehicleReplayTimelineBuilder.build([
        _track('A', [_pt(t0)]),
        _track('B', [_pt(t0)], colorIndex: 1),
      ]);

      final controller = MultiVehicleReplayController();
      controller.loadTimeline(timeline);
      expect(controller.state.vehicleVisible('A'), isTrue);

      controller.setVehicleVisible('A', false);
      expect(controller.state.vehicleVisible('A'), isFalse);
      expect(controller.state.vehicleVisible('B'), isTrue);

      controller.dispose();
    });
  });

  group('MultiVehicleReplayUi', () {
    test('shortVehicleLabel truncates long names', () {
      expect(
        MultiVehicleReplayUi.shortVehicleLabel(
          'Very Long Vehicle Name Here',
          '99',
        ).length,
        lessThanOrEqualTo(12),
      );
      expect(
        MultiVehicleReplayUi.shortVehicleLabel('', 'ABCD12345'),
        'ABCD12345',
      );
    });

    test('markerInitials from name', () {
      expect(
        MultiVehicleReplayUi.markerInitials('Fleet Alpha', '1'),
        'FA',
      );
    });

    test('legendStatus reflects visibility and data', () {
      expect(
        MultiVehicleReplayUi.legendStatus(hasData: false, visible: true),
        MultiVehicleReplayLegendStatus.noData,
      );
      expect(
        MultiVehicleReplayUi.legendStatus(hasData: true, visible: false),
        MultiVehicleReplayLegendStatus.hidden,
      );
      expect(
        MultiVehicleReplayUi.legendStatus(hasData: true, visible: true),
        MultiVehicleReplayLegendStatus.active,
      );
    });

    test('shouldRotateMarker only when moving', () {
      expect(
        MultiVehicleReplayUi.shouldRotateMarker(speedKmh: 10, course: 90),
        isTrue,
      );
      expect(
        MultiVehicleReplayUi.shouldRotateMarker(speedKmh: 2, course: 90),
        isFalse,
      );
    });

    test('colorForTrack matches palette index', () {
      final track = _track('X', [_pt(DateTime(2026, 5, 15))], colorIndex: 2);
      expect(
        MultiVehicleReplayUi.colorForTrack(track),
        MultiVehicleReplayColors.palette[2],
      );
    });
  });

  group('MultiVehicleReplayFormatters', () {
    test('duration/time formatting', () {
      final start = DateTime(2026, 5, 15, 8, 30);
      final end = DateTime(2026, 5, 15, 18, 45);
      expect(
        MultiVehicleReplayFormatters.formatTimeRange(start, end),
        contains('–'),
      );
      expect(
        MultiVehicleReplayFormatters.formatReplayTime(start),
        isNot('—'),
      );
    });
  });
}
