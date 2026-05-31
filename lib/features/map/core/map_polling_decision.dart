/// Pure decision logic for [MapLivePollingFallback] periodic ticks.
class MapPollingDecision {
  MapPollingDecision({
    required this.socketConnected,
    required this.lastLivePositionAt,
    required this.now,
    this.silenceThreshold = const Duration(seconds: 15),
  });

  final bool socketConnected;
  final DateTime? lastLivePositionAt;
  final DateTime now;
  final Duration silenceThreshold;

  double? get lastLivePositionAgeSeconds {
    if (lastLivePositionAt == null) return null;
    return now.difference(lastLivePositionAt!).inMilliseconds / 1000.0;
  }

  /// Any accepted socket position within [silenceThreshold].
  bool get hasRecentLivePosition {
    if (lastLivePositionAt == null) return false;
    return now.difference(lastLivePositionAt!) <= silenceThreshold;
  }

  /// No accepted position for longer than [silenceThreshold].
  bool get isLiveSilent {
    if (lastLivePositionAt == null) return true;
    return now.difference(lastLivePositionAt!) > silenceThreshold;
  }

  MapPollingTickResult evaluate() {
    final age = lastLivePositionAgeSeconds;

    if (hasRecentLivePosition) {
      return MapPollingTickResult.skip(
        reason: 'recent_live_position',
        socketConnected: socketConnected,
        lastLivePositionAgeSeconds: age,
      );
    }

    if (!socketConnected) {
      return MapPollingTickResult.poll(
        reason: 'websocket_disconnected',
        socketConnected: socketConnected,
        lastLivePositionAgeSeconds: age,
      );
    }

    if (isLiveSilent) {
      return MapPollingTickResult.poll(
        reason: 'live_silent',
        socketConnected: socketConnected,
        lastLivePositionAgeSeconds: age,
      );
    }

    return MapPollingTickResult.skip(
      reason: 'recent_live_position',
      socketConnected: socketConnected,
      lastLivePositionAgeSeconds: age,
    );
  }
}

enum MapPollingAction { skip, poll }

final class MapPollingTickResult {
  const MapPollingTickResult._({
    required this.action,
    required this.reason,
    required this.socketConnected,
    this.lastLivePositionAgeSeconds,
  });

  factory MapPollingTickResult.skip({
    required String reason,
    required bool socketConnected,
    double? lastLivePositionAgeSeconds,
  }) =>
      MapPollingTickResult._(
        action: MapPollingAction.skip,
        reason: reason,
        socketConnected: socketConnected,
        lastLivePositionAgeSeconds: lastLivePositionAgeSeconds,
      );

  factory MapPollingTickResult.poll({
    required String reason,
    required bool socketConnected,
    double? lastLivePositionAgeSeconds,
  }) =>
      MapPollingTickResult._(
        action: MapPollingAction.poll,
        reason: reason,
        socketConnected: socketConnected,
        lastLivePositionAgeSeconds: lastLivePositionAgeSeconds,
      );

  final MapPollingAction action;
  final String reason;
  final bool socketConnected;
  final double? lastLivePositionAgeSeconds;
}
