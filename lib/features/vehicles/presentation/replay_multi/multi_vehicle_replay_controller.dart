import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../reports/presentation/providers/replay_controller.dart';
import 'multi_vehicle_replay_timeline.dart';

class MultiVehicleReplayPlaybackState {
  const MultiVehicleReplayPlaybackState({
    this.timeline,
    this.currentIndex = 0,
    this.isPlaying = false,
    this.playbackSpeed = PlaybackSpeed.x1,
    this.isCompleted = false,
    this.visibility = const {},
    this.showMapLabels = false,
    this.autoFollow = false,
    this.useSpeedColors = false,
    this.activeVehicleId,
  });

  final MultiVehicleReplayTimeline? timeline;
  final int currentIndex;
  final bool isPlaying;
  final PlaybackSpeed playbackSpeed;
  final bool isCompleted;

  /// vehicleId → visible on map.
  final Map<String, bool> visibility;

  /// When true, markers use compact initials badges (less clutter than always-on).
  final bool showMapLabels;

  /// When true, map recenters on visible vehicles during playback (throttled).
  final bool autoFollow;

  /// Speed-colored route segments per vehicle (optional).
  final bool useSpeedColors;

  /// Highlighted vehicle for legend / snapshot focus.
  final String? activeVehicleId;

  bool vehicleVisible(String vehicleId) => visibility[vehicleId] ?? true;

  int get visibleVehicleCount {
    final tl = timeline;
    if (tl == null) return 0;
    var n = 0;
    for (final id in tl.tracksByVehicleId.keys) {
      if (vehicleVisible(id)) n++;
    }
    return n;
  }

  DateTime? get currentTime => timeline?.timeAtIndex(currentIndex);

  double get progress {
    final tl = timeline;
    if (tl == null || tl.length < 2) return 0;
    return currentIndex / (tl.length - 1);
  }

  bool get hasTimeline => timeline != null && timeline!.length > 0;

  MultiVehicleReplayPlaybackState copyWith({
    MultiVehicleReplayTimeline? timeline,
    int? currentIndex,
    bool? isPlaying,
    PlaybackSpeed? playbackSpeed,
    bool? isCompleted,
    Map<String, bool>? visibility,
    bool? showMapLabels,
    bool? autoFollow,
    bool? useSpeedColors,
    String? activeVehicleId,
    bool clearActiveVehicle = false,
  }) =>
      MultiVehicleReplayPlaybackState(
        timeline: timeline ?? this.timeline,
        currentIndex: currentIndex ?? this.currentIndex,
        isPlaying: isPlaying ?? this.isPlaying,
        playbackSpeed: playbackSpeed ?? this.playbackSpeed,
        isCompleted: isCompleted ?? this.isCompleted,
        visibility: visibility ?? this.visibility,
        showMapLabels: showMapLabels ?? this.showMapLabels,
        autoFollow: autoFollow ?? this.autoFollow,
        useSpeedColors: useSpeedColors ?? this.useSpeedColors,
        activeVehicleId: clearActiveVehicle
            ? null
            : (activeVehicleId ?? this.activeVehicleId),
      );
}

class MultiVehicleReplayController
    extends StateNotifier<MultiVehicleReplayPlaybackState> {
  MultiVehicleReplayController() : super(const MultiVehicleReplayPlaybackState());

  Timer? _timer;
  static const int _baseTickMs = 400;

  void loadTimeline(MultiVehicleReplayTimeline timeline) {
    _cancelTimer();
    final visibility = {
      for (final id in timeline.tracksByVehicleId.keys) id: true,
    };
    final active = _defaultActiveVehicleId(timeline, visibility);
    state = MultiVehicleReplayPlaybackState(
      timeline: timeline,
      visibility: visibility,
      activeVehicleId: active,
    );
  }

  static String? _defaultActiveVehicleId(
    MultiVehicleReplayTimeline timeline,
    Map<String, bool> visibility,
  ) {
    for (final id in timeline.tracksByVehicleId.keys) {
      final track = timeline.tracksByVehicleId[id];
      if (track != null && track.hasData && (visibility[id] ?? true)) {
        return id;
      }
    }
    return null;
  }

  void play() {
    if (!state.hasTimeline) return;
    if (state.isCompleted) {
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

  /// Timer only — no [state] update (safe during screen teardown / autoDispose).
  void stopTimerOnly() {
    _cancelTimer();
  }

  void reset() {
    _cancelTimer();
    state = state.copyWith(
      currentIndex: 0,
      isPlaying: false,
      isCompleted: false,
    );
  }

  void seekToProgress(double progress) {
    final tl = state.timeline;
    if (tl == null || tl.isEmpty) return;
    final maxIdx = tl.length - 1;
    final idx = (progress * maxIdx).round().clamp(0, maxIdx);
    state = state.copyWith(
      currentIndex: idx,
      isCompleted: idx >= maxIdx,
    );
  }

  void seekToIndex(int index) {
    final tl = state.timeline;
    if (tl == null || tl.isEmpty) return;
    final clamped = index.clamp(0, tl.length - 1);
    state = state.copyWith(
      currentIndex: clamped,
      isCompleted: clamped >= tl.length - 1,
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

  void setVehicleVisible(String vehicleId, bool visible) {
    final next = Map<String, bool>.from(state.visibility);
    next[vehicleId] = visible;
    var active = state.activeVehicleId;
    if (!visible && active == vehicleId) {
      active = _firstVisibleVehicleId(next);
    } else if (visible && active == null) {
      active = vehicleId;
    }
    state = state.copyWith(
      visibility: next,
      activeVehicleId: active,
      clearActiveVehicle: active == null,
    );
  }

  String? _firstVisibleVehicleId(Map<String, bool> visibility) {
    for (final entry in visibility.entries) {
      if (!entry.value) continue;
      final track = state.timeline?.tracksByVehicleId[entry.key];
      if (track != null && track.hasData) return entry.key;
    }
    return null;
  }

  void setActiveVehicle(String? vehicleId) {
    if (vehicleId != null) {
      if (!state.vehicleVisible(vehicleId)) return;
      final track = state.timeline?.tracksByVehicleId[vehicleId];
      if (track == null || !track.hasData) return;
    }
    state = state.copyWith(
      activeVehicleId: vehicleId,
      clearActiveVehicle: vehicleId == null,
    );
  }

  void setAutoFollow(bool enabled) {
    if (state.autoFollow == enabled) return;
    state = state.copyWith(autoFollow: enabled);
  }

  void setUseSpeedColors(bool enabled) {
    if (state.useSpeedColors == enabled) return;
    state = state.copyWith(useSpeedColors: enabled);
  }

  void setShowMapLabels(bool enabled) {
    if (state.showMapLabels == enabled) return;
    state = state.copyWith(showMapLabels: enabled);
  }

  void _startTimer() {
    final intervalMs =
        (_baseTickMs / state.playbackSpeed.multiplier).round();
    _timer = Timer.periodic(Duration(milliseconds: intervalMs), (_) => _tick());
  }

  void _tick() {
    if (!mounted) return;
    final tl = state.timeline;
    if (tl == null) return;
    final next = state.currentIndex + 1;
    if (next >= tl.length) {
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

  @override
  void dispose() {
    _cancelTimer();
    super.dispose();
  }
}

final multiVehicleReplayControllerProvider = StateNotifierProvider.autoDispose<
    MultiVehicleReplayController, MultiVehicleReplayPlaybackState>(
  (ref) => MultiVehicleReplayController(),
);
