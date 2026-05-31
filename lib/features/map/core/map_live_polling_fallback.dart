import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/socket/socket_provider.dart';
import '../../../core/socket/socket_state.dart';
import 'map_audit_logger.dart';
import 'map_polling_decision.dart';

/// Screen-scoped REST polling when WebSocket positions go quiet or socket is down.
///
/// Polls every [pollInterval] only when [MapPollingDecision] says REST fallback is needed.
/// Uses [TraccarSocketService.currentState] (not [socketStateProvider] AsyncValue) so a
/// healthy socket is not misread as disconnected while positions are still arriving.
class MapLivePollingFallback {
  MapLivePollingFallback({
    required this.screen,
    required this.onPoll,
    this.pollInterval = const Duration(seconds: 5),
    this.silenceThreshold = const Duration(seconds: 15),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final String screen;
  final VoidCallback onPoll;
  final Duration pollInterval;
  final Duration silenceThreshold;
  final DateTime Function() _now;

  Timer? _timer;

  void start(WidgetRef ref) {
    stop(log: false);
    MapAuditLogger.polling(screen: screen, action: 'started');
    _timer = Timer.periodic(pollInterval, (_) => _tick(ref));
  }

  void _tick(WidgetRef ref) {
    final lastAt = ref.read(lastLivePositionReceivedAtProvider);
    // Use service.currentState — StreamProvider AsyncValue can be loading/null
    // while the socket is already connected and receiving positions.
    final socketConnected =
        ref.read(traccarSocketServiceProvider).currentState is SocketConnected;

    final result = MapPollingDecision(
      socketConnected: socketConnected,
      lastLivePositionAt: lastAt,
      now: _now(),
      silenceThreshold: silenceThreshold,
    ).evaluate();

    MapAuditLogger.polling(
      screen: screen,
      action: 'state',
      socketConnected: result.socketConnected,
      lastLivePositionAgeSeconds: result.lastLivePositionAgeSeconds,
    );

    switch (result.action) {
      case MapPollingAction.skip:
        MapAuditLogger.polling(
          screen: screen,
          action: 'skipped',
          reason: result.reason,
          socketConnected: result.socketConnected,
          lastLivePositionAgeSeconds: result.lastLivePositionAgeSeconds,
        );
        return;
      case MapPollingAction.poll:
        MapAuditLogger.polling(
          screen: screen,
          action: 'tick',
          reason: result.reason,
          socketConnected: result.socketConnected,
          lastLivePositionAgeSeconds: result.lastLivePositionAgeSeconds,
        );
        onPoll();
    }
  }

  void stop({bool log = true}) {
    final had = _timer != null;
    _timer?.cancel();
    _timer = null;
    if (log && had) {
      MapAuditLogger.polling(screen: screen, action: 'stopped');
    }
  }
}
