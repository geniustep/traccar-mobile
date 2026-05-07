import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../map/data/datasources/route_datasource.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PlaybackSpeed
// ─────────────────────────────────────────────────────────────────────────────

enum PlaybackSpeed { x1, x2, x4, x8 }

extension PlaybackSpeedValue on PlaybackSpeed {
  int get multiplier => switch (this) {
        PlaybackSpeed.x1 => 1,
        PlaybackSpeed.x2 => 2,
        PlaybackSpeed.x4 => 4,
        PlaybackSpeed.x8 => 8,
      };

  String get label => switch (this) {
        PlaybackSpeed.x1 => 'x1',
        PlaybackSpeed.x2 => 'x2',
        PlaybackSpeed.x4 => 'x4',
        PlaybackSpeed.x8 => 'x8',
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// ReplayState
// ─────────────────────────────────────────────────────────────────────────────

class ReplayState {
  const ReplayState({
    this.points = const [],
    this.currentIndex = 0,
    this.isPlaying = false,
    this.playbackSpeed = PlaybackSpeed.x1,
    this.isCompleted = false,
  });

  final List<RoutePoint> points;
  final int currentIndex;
  final bool isPlaying;
  final PlaybackSpeed playbackSpeed;
  final bool isCompleted;

  RoutePoint? get currentPoint =>
      points.isNotEmpty ? points[currentIndex.clamp(0, points.length - 1)] : null;

  double get progress =>
      points.length < 2 ? 0.0 : currentIndex / (points.length - 1);

  bool get hasData => points.length >= 2;

  ReplayState copyWith({
    List<RoutePoint>? points,
    int? currentIndex,
    bool? isPlaying,
    PlaybackSpeed? playbackSpeed,
    bool? isCompleted,
  }) =>
      ReplayState(
        points: points ?? this.points,
        currentIndex: currentIndex ?? this.currentIndex,
        isPlaying: isPlaying ?? this.isPlaying,
        playbackSpeed: playbackSpeed ?? this.playbackSpeed,
        isCompleted: isCompleted ?? this.isCompleted,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// ReplayController
// ─────────────────────────────────────────────────────────────────────────────

class ReplayController extends StateNotifier<ReplayState> {
  ReplayController() : super(const ReplayState());

  Timer? _timer;

  /// Base tick interval in milliseconds at x1 speed.
  static const int _baseTickMs = 400;

  /// Max replay points — too many points cause unnecessary redraws.
  static const int _maxReplayPoints = 1200;

  // ── Public API ─────────────────────────────────────────────────────────────

  void loadPoints(List<RoutePoint> rawPoints) {
    _cancelTimer();

    // Filter invalid and sort by time.
    final valid = rawPoints
        .where((p) =>
            p.position.latitude != 0 ||
            p.position.longitude != 0)
        .toList()
      ..sort((a, b) => a.fixTime.compareTo(b.fixTime));

    final pts = _sample(valid, maxCount: _maxReplayPoints);

    state = ReplayState(points: pts);
  }

  void play() {
    if (!state.hasData) return;
    if (state.isCompleted) {
      // Auto-restart if already finished.
      state = state.copyWith(
        currentIndex: 0,
        isCompleted: false,
        isPlaying: true,
      );
    } else {
      state = state.copyWith(isPlaying: true);
    }
    _startTimer();
  }

  void pause() {
    _cancelTimer();
    state = state.copyWith(isPlaying: false);
  }

  void restart() {
    _cancelTimer();
    state = state.copyWith(
      currentIndex: 0,
      isPlaying: false,
      isCompleted: false,
    );
  }

  void seekTo(int index) {
    if (state.points.isEmpty) return;
    final clamped = index.clamp(0, state.points.length - 1);
    final wasCompleted = state.isCompleted;
    state = state.copyWith(
      currentIndex: clamped,
      isCompleted: wasCompleted && clamped == state.points.length - 1,
    );
  }

  void setPlaybackSpeed(PlaybackSpeed speed) {
    if (state.playbackSpeed == speed) return;
    state = state.copyWith(playbackSpeed: speed);
    if (state.isPlaying) {
      _cancelTimer();
      _startTimer();
    }
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  void _startTimer() {
    final intervalMs = (_baseTickMs / state.playbackSpeed.multiplier).round();
    _timer = Timer.periodic(Duration(milliseconds: intervalMs), (_) => _tick());
  }

  void _tick() {
    if (!mounted) return;
    final next = state.currentIndex + 1;
    if (next >= state.points.length) {
      _cancelTimer();
      state = state.copyWith(isPlaying: false, isCompleted: true);
    } else {
      state = state.copyWith(currentIndex: next);
    }
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  static List<RoutePoint> _sample(List<RoutePoint> pts, {required int maxCount}) {
    if (pts.length <= maxCount) return pts;
    final step = (pts.length - 1) / (maxCount - 1);
    final result = <RoutePoint>[pts.first];
    for (var i = 1; i < maxCount - 1; i++) {
      result.add(pts[(i * step).round().clamp(1, pts.length - 2)]);
    }
    result.add(pts.last);
    return result;
  }

  @override
  void dispose() {
    _cancelTimer();
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final replayControllerProvider =
    StateNotifierProvider.autoDispose<ReplayController, ReplayState>(
  (ref) => ReplayController(),
);
