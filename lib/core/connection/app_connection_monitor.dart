import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logging/app_logger.dart';
import '../socket/socket_state.dart';
import 'app_connection_status.dart';

/// Tracks the high-level app connection health and the live-sync channel
/// status as two independent concepts.
///
/// **AppConnectionStatus** — considers internet + last successful API call.
/// **LiveSyncStatus** — derived purely from WebSocket state + data freshness.
///
/// The monitor exposes both via [appStatus] and [liveStatus] Riverpod
/// providers that the Dashboard reads.
class AppConnectionMonitor extends StateNotifier<ConnectionSnapshot> {
  AppConnectionMonitor({
    required Connectivity connectivity,
    Duration apiSuccessWindow = const Duration(seconds: 90),
    Duration liveFreshnessWindow = const Duration(seconds: 45),
  })  : _connectivity = connectivity,
        _apiSuccessWindow = apiSuccessWindow,
        _liveFreshnessWindow = liveFreshnessWindow,
        super(const ConnectionSnapshot()) {
    _connectivitySub = _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);
    _freshnessTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _recomputeFromTimers(),
    );
  }

  final Connectivity _connectivity;
  final Duration _apiSuccessWindow;
  final Duration _liveFreshnessWindow;

  StreamSubscription<dynamic>? _connectivitySub;
  Timer? _freshnessTimer;

  DateTime? _lastApiSuccess;
  DateTime? _lastLiveEvent;
  bool _hasInternet = true;
  bool _wasLiveConnectedBefore = false;
  SocketState _lastSocketState = const SocketDisconnected();

  // ---------------------------------------------------------------------------
  // Public API — called from interceptors / providers
  // ---------------------------------------------------------------------------

  /// Call after every successful REST API response.
  void recordApiSuccess() {
    final now = DateTime.now();
    _lastApiSuccess = now;
    _recompute(reason: 'api_success');
  }

  /// Call when an API request fails.
  void recordApiFailure({
    bool isAuthError = false,
    bool isServerError = false,
    bool isNoConnection = false,
  }) {
    if (isNoConnection) {
      _hasInternet = false;
    }
    _recompute(
      reason: isAuthError
          ? 'api_401'
          : isServerError
              ? 'api_server_error'
              : isNoConnection
                  ? 'api_no_connection'
                  : 'api_failure',
      forceAuthError: isAuthError,
      forceServerError: isServerError,
    );
  }

  /// Call from the socket state stream listener.
  void onSocketStateChanged(SocketState socketState) {
    final old = _lastSocketState;
    _lastSocketState = socketState;

    if (socketState is SocketConnected) {
      _wasLiveConnectedBefore = true;
      _lastLiveEvent = DateTime.now();
    }

    _recompute(
      reason: 'socket_${_socketStateName(socketState)}',
      oldSocketState: old,
    );
  }

  /// Call when a WebSocket message with actual data arrives.
  void recordLiveEvent() {
    _lastLiveEvent = DateTime.now();
    if (_lastSocketState is SocketConnected) {
      final prev = state.liveStatus;
      if (prev != LiveSyncStatus.connected) {
        _recompute(reason: 'live_event_received');
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Connectivity listener
  // ---------------------------------------------------------------------------

  void _onConnectivityChanged(dynamic result) {
    final bool hasConn = switch (result) {
      final List<dynamic> list =>
        list.any((r) => r != ConnectivityResult.none),
      ConnectivityResult.none => false,
      _ => true,
    };
    final was = _hasInternet;
    _hasInternet = hasConn;
    if (was != hasConn) {
      _recompute(reason: hasConn ? 'internet_restored' : 'internet_lost');
    }
  }

  // ---------------------------------------------------------------------------
  // Core recomputation
  // ---------------------------------------------------------------------------

  void _recompute({
    required String reason,
    bool forceAuthError = false,
    bool forceServerError = false,
    SocketState? oldSocketState,
  }) {
    final now = DateTime.now();
    final oldApp = state.appStatus;
    final oldLive = state.liveStatus;

    // ── App connection status ──
    AppConnectionStatus newApp;
    if (!_hasInternet) {
      newApp = AppConnectionStatus.offline;
    } else if (forceAuthError) {
      newApp = AppConnectionStatus.unauthorized;
    } else if (forceServerError && _isApiStale(now)) {
      newApp = AppConnectionStatus.serverUnavailable;
    } else if (_lastApiSuccess != null &&
        now.difference(_lastApiSuccess!) <= _apiSuccessWindow) {
      newApp = AppConnectionStatus.online;
    } else if (_lastApiSuccess == null && oldApp == AppConnectionStatus.checking) {
      newApp = AppConnectionStatus.checking;
    } else if (forceServerError) {
      newApp = AppConnectionStatus.serverUnavailable;
    } else {
      newApp = oldApp == AppConnectionStatus.checking
          ? AppConnectionStatus.checking
          : oldApp;
    }

    // ── Live sync status ──
    LiveSyncStatus newLive;
    if (_lastSocketState is SocketConnected) {
      if (_lastLiveEvent != null &&
          now.difference(_lastLiveEvent!) > _liveFreshnessWindow) {
        newLive = LiveSyncStatus.degraded;
      } else {
        newLive = LiveSyncStatus.connected;
      }
    } else if (_lastSocketState is SocketReconnecting) {
      newLive = _wasLiveConnectedBefore
          ? LiveSyncStatus.reconnecting
          : LiveSyncStatus.idle;
    } else if (_lastSocketState is SocketConnecting) {
      newLive = _wasLiveConnectedBefore
          ? LiveSyncStatus.reconnecting
          : LiveSyncStatus.idle;
    } else if (_lastSocketState is SocketError) {
      newLive = LiveSyncStatus.disconnected;
    } else {
      newLive = LiveSyncStatus.idle;
    }

    if (newApp != oldApp || newLive != oldLive) {
      state = ConnectionSnapshot(appStatus: newApp, liveStatus: newLive);

      if (newApp != oldApp) {
        AppLogger.connection(
          'AppConnectionStatus changed: ${oldApp.name} -> ${newApp.name}, '
          'reason: $reason',
        );
      }
      if (newLive != oldLive) {
        AppLogger.liveSync(
          'LiveSyncStatus changed: ${oldLive.name} -> ${newLive.name}, '
          'reason: $reason',
        );
      }
    }
  }

  void _recomputeFromTimers() {
    _recompute(reason: 'freshness_timer');
  }

  bool _isApiStale(DateTime now) {
    if (_lastApiSuccess == null) return true;
    return now.difference(_lastApiSuccess!) > _apiSuccessWindow;
  }

  String _socketStateName(SocketState s) => switch (s) {
        SocketDisconnected() => 'disconnected',
        SocketConnecting() => 'connecting',
        SocketConnected() => 'connected',
        SocketReconnecting() => 'reconnecting',
        SocketError() => 'error',
      };

  /// Exposed for tests only — returns the current snapshot.
  ConnectionSnapshot debugReadState() => state;

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _freshnessTimer?.cancel();
    super.dispose();
  }
}

/// Immutable snapshot of both statuses.
@immutable
class ConnectionSnapshot {
  const ConnectionSnapshot({
    this.appStatus = AppConnectionStatus.checking,
    this.liveStatus = LiveSyncStatus.idle,
  });

  final AppConnectionStatus appStatus;
  final LiveSyncStatus liveStatus;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConnectionSnapshot &&
          other.appStatus == appStatus &&
          other.liveStatus == liveStatus;

  @override
  int get hashCode => Object.hash(appStatus, liveStatus);
}

// =============================================================================
// Riverpod providers
// =============================================================================

/// The single [AppConnectionMonitor] instance. Override in tests.
final appConnectionMonitorProvider =
    StateNotifierProvider<AppConnectionMonitor, ConnectionSnapshot>((ref) {
  final connectivity = ref.watch(_connectivityInstanceProvider);
  final monitor = AppConnectionMonitor(connectivity: connectivity);

  ref.onDispose(monitor.dispose);
  return monitor;
});

final _connectivityInstanceProvider = Provider<Connectivity>((ref) {
  return Connectivity();
});

/// Current [AppConnectionStatus] — watch this in the Dashboard.
final appConnectionStatusProvider = Provider<AppConnectionStatus>((ref) {
  return ref.watch(
    appConnectionMonitorProvider.select((s) => s.appStatus),
  );
});

/// Current [LiveSyncStatus] — watch this in the Dashboard.
final liveSyncStatusProvider = Provider<LiveSyncStatus>((ref) {
  return ref.watch(
    appConnectionMonitorProvider.select((s) => s.liveStatus),
  );
});
