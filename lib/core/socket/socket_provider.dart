import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/traccar_device.dart';
import '../models/traccar_event.dart';
import '../logging/app_logger.dart';
import '../models/traccar_position.dart';
import '../../features/map/core/map_audit_logger.dart';
import 'live_position_update_gate.dart';
import 'socket_event_parser.dart';
import 'socket_state.dart';
import 'traccar_socket_service.dart';

/// Last time any device position was accepted into [livePositionsProvider].
final lastLivePositionReceivedAtProvider =
    StateProvider<DateTime?>((ref) => null);

// ── Service provider ──────────────────────────────────────────────────────────

/// Singleton [TraccarSocketService] — disposed when the app is closed.
final traccarSocketServiceProvider = Provider<TraccarSocketService>((ref) {
  // storage is injected lazily to avoid circular dependency at startup
  // Usage: ref.read(traccarSocketServiceProvider).connect()
  throw UnimplementedError(
    'Override traccarSocketServiceProvider with a concrete instance '
    'that has access to SecureStorageService.',
  );
});

// ── Connection state ──────────────────────────────────────────────────────────

/// Watches the WebSocket connection state.
final socketStateProvider = StreamProvider<SocketState>((ref) {
  final svc = ref.watch(traccarSocketServiceProvider);
  return svc.stateStream;
});

// ── Live positions ────────────────────────────────────────────────────────────

/// Keeps a map of deviceId → latest [TraccarPosition] from the socket.
final livePositionsProvider =
    StateNotifierProvider<LivePositionsNotifier, Map<int, TraccarPosition>>(
  (ref) {
    final svc = ref.watch(traccarSocketServiceProvider);
    return LivePositionsNotifier(
      svc,
      onPositionAccepted: () {
        ref.read(lastLivePositionReceivedAtProvider.notifier).state =
            DateTime.now();
      },
    );
  },
);

class LivePositionsNotifier
    extends StateNotifier<Map<int, TraccarPosition>> {
  LivePositionsNotifier(
    TraccarSocketService svc, {
    void Function()? onPositionAccepted,
  })  : _onPositionAccepted = onPositionAccepted,
        super({}) {
    _sub = svc.messageStream.listen((msg) {
      if (!msg.hasPositions) return;

      var next = Map<int, TraccarPosition>.from(state);
      var acceptedAny = false;
      for (final pos in msg.positions) {
        final current = next[pos.deviceId];
        if (!LivePositionUpdateGate.shouldAcceptLiveUpdate(
          current: current,
          incoming: pos,
        )) {
          AppLogger.liveSyncStale(
            'Ignored stale position for live update: '
            'vehicleId=${pos.deviceId} '
            'fixTime=${pos.fixTime.toUtc().toIso8601String()} '
            'lastFixTime=${current!.fixTime.toUtc().toIso8601String()}',
          );
          continue;
        }
        MapAuditLogger.websocketPosition(pos);
        next[pos.deviceId] = pos;
        acceptedAny = true;
      }
      if (acceptedAny) {
        _onPositionAccepted?.call();
        state = next;
      }
    });
  }

  final void Function()? _onPositionAccepted;

  late final StreamSubscription<SocketMessage> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

// ── Live device statuses ──────────────────────────────────────────────────────

/// Keeps a map of deviceId → latest [TraccarDevice] status from the socket.
final liveDevicesProvider =
    StateNotifierProvider<LiveDevicesNotifier, Map<int, TraccarDevice>>(
  (ref) {
    final svc = ref.watch(traccarSocketServiceProvider);
    return LiveDevicesNotifier(svc);
  },
);

class LiveDevicesNotifier extends StateNotifier<Map<int, TraccarDevice>> {
  LiveDevicesNotifier(TraccarSocketService svc) : super({}) {
    _sub = svc.messageStream.listen((msg) {
      if (msg.hasDevices) {
        state = {
          ...state,
          for (final d in msg.devices) d.id: d,
        };
      }
    });
  }

  late final StreamSubscription<SocketMessage> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

// ── Live events ───────────────────────────────────────────────────────────────

/// Accumulates the last N [TraccarEvent] received via socket (newest first).
final liveEventsProvider =
    StateNotifierProvider<LiveEventsNotifier, List<TraccarEvent>>(
  (ref) {
    final svc = ref.watch(traccarSocketServiceProvider);
    return LiveEventsNotifier(svc);
  },
);

class LiveEventsNotifier extends StateNotifier<List<TraccarEvent>> {
  LiveEventsNotifier(TraccarSocketService svc) : super([]) {
    _sub = svc.messageStream.listen((msg) {
      // msg.events
      if (msg.hasEvents) {
        state = [...msg.events.reversed, ...state].take(_maxEvents).toList();
      }
    });
  }

  static const int _maxEvents = 100;
  late final StreamSubscription<SocketMessage> _sub;

  void clear() => state = [];

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
