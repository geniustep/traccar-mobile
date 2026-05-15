/// How camera follow reacts to user gestures differs between fleet vs single-vehicle UIs.
enum MapCameraFollowMode {
  /// Follow stays "on" but pauses until the user taps resume (fleet bottom sheet).
  fleetSelectedVehicle,

  /// Panning turns follow off immediately (vehicle tracking screen).
  singleVehicle,
}

/// Shared camera-follow guard + pause semantics for map screens.
class MapCameraFollowController {
  MapCameraFollowController(
    this.mode, {
    this.followThrottle,
  });

  final MapCameraFollowMode mode;

  /// When non-null, limits how often follow animations run (fleet selected vehicle).
  final Duration? followThrottle;

  int _programmaticGuard = 0;

  /// User wants the map to track the target (vehicle / selection).
  bool followEnabled = false;

  /// Fleet mode only: follow is enabled but user panned; show resume chip.
  bool gesturePaused = false;

  DateTime? _lastFollowTick;

  void beginProgrammaticMove() => _programmaticGuard++;

  void endProgrammaticMoveSoon([
    Duration delay = const Duration(milliseconds: 80),
  ]) {
    Future.delayed(delay, () {
      if (_programmaticGuard > 0) _programmaticGuard--;
    });
  }

  /// `onCameraMoveStarted` from [GoogleMap]. Returns whether UI should rebuild.
  bool handleUserCameraMoveStarted() {
    if (_programmaticGuard > 0) {
      _programmaticGuard--;
      return false;
    }
    if (!followEnabled) return false;

    switch (mode) {
      case MapCameraFollowMode.fleetSelectedVehicle:
        gesturePaused = true;
        return true;
      case MapCameraFollowMode.singleVehicle:
        followEnabled = false;
        gesturePaused = false;
        return true;
    }
  }

  void clearFollow() {
    followEnabled = false;
    gesturePaused = false;
  }

  void resumeFleetGesturePause() => gesturePaused = false;

  bool get canApplyLiveCamera =>
      followEnabled &&
      (mode == MapCameraFollowMode.singleVehicle || !gesturePaused);

  /// Returns true when this tick should be skipped (throttling).
  bool consumeFollowThrottle() {
    final t = followThrottle;
    if (t == null) return false;
    final now = DateTime.now();
    if (_lastFollowTick != null &&
        now.difference(_lastFollowTick!) < t) {
      return true;
    }
    _lastFollowTick = now;
    return false;
  }
}
