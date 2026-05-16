import 'package:elmogps/features/map/data/datasources/route_datasource.dart';
import 'package:elmogps/features/reports/presentation/providers/replay_controller.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  final t0 = DateTime.utc(2024, 1, 1, 8);

  List<RoutePoint> threePoints() => [
        RoutePoint(
          position: const LatLng(33.5, -7.6),
          speed: 10,
          course: 0,
          fixTime: t0,
          ignition: true,
        ),
        RoutePoint(
          position: const LatLng(33.51, -7.61),
          speed: 20,
          course: 45,
          fixTime: t0.add(const Duration(minutes: 1)),
          ignition: true,
        ),
        RoutePoint(
          position: const LatLng(33.52, -7.62),
          speed: 30,
          course: 90,
          fixTime: t0.add(const Duration(minutes: 2)),
          ignition: true,
        ),
      ];

  group('empty route', () {
    late ReplayController controller;

    setUp(() => controller = ReplayController());
    tearDown(() => controller.dispose());

    test('currentPoint is null', () {
      expect(controller.state.currentPoint, isNull);
      expect(controller.state.hasData, isFalse);
    });

    test('play does not start', () {
      controller.play();
      expect(controller.state.isPlaying, isFalse);
    });

    test('seekTo is no-op', () {
      controller.seekTo(5);
      expect(controller.state.currentIndex, 0);
    });

    test('stepNext and stepPrevious are safe', () {
      controller.stepNext();
      controller.stepPrevious();
      expect(controller.state.currentIndex, 0);
    });

    test('dispose cancels timer without error', () {
      controller.play();
      expect(controller.state.isPlaying, isFalse);
    });
  });

  group('single point', () {
    late ReplayController controller;

    setUp(() {
      controller = ReplayController();
      controller.loadPoints([
        RoutePoint(
          position: const LatLng(33.5, -7.6),
          speed: 10,
          course: 0,
          fixTime: t0,
          ignition: true,
        ),
      ]);
    });
    tearDown(() => controller.dispose());

    test('hasData is false with one point', () {
      expect(controller.state.hasData, isFalse);
      expect(controller.state.points.length, 1);
    });

    test('play does not advance', () {
      controller.play();
      expect(controller.state.isPlaying, isFalse);
      expect(controller.state.currentIndex, 0);
    });

    test('stepNext does not change index', () {
      controller.stepNext();
      expect(controller.state.currentIndex, 0);
    });

    test('canStepNext and canStepPrevious are false', () {
      expect(controller.canStepNext, isFalse);
      expect(controller.canStepPrevious, isFalse);
    });
  });

  group('normal route', () {
    late ReplayController controller;

    setUp(() {
      controller = ReplayController();
      controller.loadPoints(threePoints());
    });
    tearDown(() => controller.dispose());

    test('loadPoints resets index to 0', () {
      expect(controller.state.currentIndex, 0);
      expect(controller.state.points.length, 3);
    });

    test('play and pause', () {
      controller.play();
      expect(controller.state.isPlaying, isTrue);
      controller.pause();
      expect(controller.state.isPlaying, isFalse);
    });

    test('restart resets state', () {
      controller.seekTo(2);
      controller.restart();
      expect(controller.state.currentIndex, 0);
      expect(controller.state.isPlaying, isFalse);
      expect(controller.state.isCompleted, isFalse);
    });

    test('seekTo clamps out of range', () {
      controller.seekTo(99);
      expect(controller.state.currentIndex, 2);
      controller.seekTo(-5);
      expect(controller.state.currentIndex, 0);
    });

    test('seekTo clears completed when leaving end', () {
      fakeAsync((async) {
        controller.play();
        async.elapse(const Duration(milliseconds: 1200));
        expect(controller.state.isCompleted, isTrue);
        controller.seekTo(1);
        expect(controller.state.isCompleted, isFalse);
      });
    });

    test('tick advances to completion', () {
      fakeAsync((async) {
        controller.play();
        async.elapse(const Duration(milliseconds: 400));
        expect(controller.state.currentIndex, 1);
        async.elapse(const Duration(milliseconds: 400));
        expect(controller.state.currentIndex, 2);
        async.elapse(const Duration(milliseconds: 400));
        expect(controller.state.isPlaying, isFalse);
        expect(controller.state.isCompleted, isTrue);
      });
    });

    test('play after completion restarts from 0', () {
      fakeAsync((async) {
        controller.play();
        async.elapse(const Duration(milliseconds: 1500));
        expect(controller.state.isCompleted, isTrue);
        controller.play();
        expect(controller.state.currentIndex, 0);
        expect(controller.state.isCompleted, isFalse);
        expect(controller.state.isPlaying, isTrue);
      });
    });

    test('progress at ends', () {
      expect(controller.state.progress, 0);
      controller.seekTo(2);
      expect(controller.state.progress, 1.0);
    });
  });

  group('speed changes', () {
    late ReplayController controller;

    setUp(() {
      controller = ReplayController();
      controller.loadPoints(threePoints());
    });
    tearDown(() => controller.dispose());

    test('setPlaybackSpeed while paused does not start play', () {
      controller.setPlaybackSpeed(PlaybackSpeed.x4);
      expect(controller.state.isPlaying, isFalse);
      expect(controller.state.playbackSpeed, PlaybackSpeed.x4);
    });

    test('setPlaybackSpeed while playing keeps playing', () {
      fakeAsync((async) {
        controller.play();
        controller.setPlaybackSpeed(PlaybackSpeed.x8);
        expect(controller.state.isPlaying, isTrue);
        async.elapse(const Duration(milliseconds: 100));
        expect(controller.state.currentIndex, greaterThan(0));
      });
    });

    test('faster speed advances index sooner', () {
      fakeAsync((async) {
        controller.setPlaybackSpeed(PlaybackSpeed.x8);
        controller.play();
        async.elapse(const Duration(milliseconds: 60));
        expect(controller.state.currentIndex, 1);
      });
    });
  });

  group('step controls', () {
    late ReplayController controller;

    setUp(() {
      controller = ReplayController();
      controller.loadPoints(threePoints());
    });
    tearDown(() => controller.dispose());

    test('stepNext from 0 moves to index 1 and pauses', () {
      controller.play();
      controller.stepNext();
      expect(controller.state.currentIndex, 1);
      expect(controller.state.isPlaying, isFalse);
    });

    test('stepPrevious from 1 moves to index 0', () {
      controller.seekTo(1);
      controller.stepPrevious();
      expect(controller.state.currentIndex, 0);
    });

    test('stepPrevious at index 0 does not decrease', () {
      controller.stepPrevious();
      expect(controller.state.currentIndex, 0);
    });

    test('stepNext at last index does not exceed', () {
      controller.seekTo(2);
      controller.stepNext();
      expect(controller.state.currentIndex, 2);
    });

    test('canStep flags', () {
      expect(controller.canStepPrevious, isFalse);
      expect(controller.canStepNext, isTrue);
      controller.seekTo(2);
      expect(controller.canStepPrevious, isTrue);
      expect(controller.canStepNext, isFalse);
    });
  });

  group('loadPoints sampling', () {
    test('filters invalid (0,0) coordinates', () {
      final c = ReplayController();
      c.loadPoints([
        RoutePoint(
          position: const LatLng(0, 0),
          speed: 10,
          course: 0,
          fixTime: t0,
          ignition: true,
        ),
        ...threePoints(),
      ]);
      expect(c.state.points.length, 3);
      c.dispose();
    });
  });
}
