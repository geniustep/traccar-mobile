import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:elmogps/core/connection/app_connection_monitor.dart';
import 'package:elmogps/core/connection/app_connection_status.dart';
import 'package:elmogps/core/socket/socket_state.dart';

/// Minimal stub that satisfies [Connectivity] without real platform channels.
class _FakeConnectivity implements Connectivity {
  final _controller = StreamController<ConnectivityResult>.broadcast();

  @override
  Stream<ConnectivityResult> get onConnectivityChanged => _controller.stream;

  @override
  Future<ConnectivityResult> checkConnectivity() async =>
      ConnectivityResult.wifi;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  void dispose() => _controller.close();
}

void main() {
  late AppConnectionMonitor monitor;
  late _FakeConnectivity fakeConnectivity;

  AppConnectionStatus appStatus() => monitor.debugReadState().appStatus;
  LiveSyncStatus liveStatus() => monitor.debugReadState().liveStatus;

  setUp(() {
    fakeConnectivity = _FakeConnectivity();
    monitor = AppConnectionMonitor(
      connectivity: fakeConnectivity,
      apiSuccessWindow: const Duration(seconds: 90),
      liveFreshnessWindow: const Duration(seconds: 45),
    );
  });

  tearDown(() {
    monitor.dispose();
    fakeConnectivity.dispose();
  });

  group('AppConnectionStatus', () {
    test('starts in checking', () {
      expect(appStatus(), AppConnectionStatus.checking);
    });

    test('becomes online after API success', () {
      monitor.recordApiSuccess();
      expect(appStatus(), AppConnectionStatus.online);
    });

    test('stays online when WebSocket fails', () {
      monitor.recordApiSuccess();
      monitor.onSocketStateChanged(
          const SocketError('Reconnect limit reached'));
      expect(appStatus(), AppConnectionStatus.online);
    });

    test('becomes unauthorized on 401', () {
      monitor.recordApiFailure(isAuthError: true);
      expect(appStatus(), AppConnectionStatus.unauthorized);
    });

    test('becomes serverUnavailable on 500 when API is stale', () {
      monitor.recordApiFailure(isServerError: true);
      expect(appStatus(), AppConnectionStatus.serverUnavailable);
    });

    test('stays online when 500 but recent API success exists', () {
      monitor.recordApiSuccess();
      monitor.recordApiFailure(isServerError: true);
      expect(appStatus(), AppConnectionStatus.online);
    });

    test('becomes offline when no internet', () {
      monitor.recordApiFailure(isNoConnection: true);
      expect(appStatus(), AppConnectionStatus.offline);
    });
  });

  group('LiveSyncStatus', () {
    test('starts as idle', () {
      expect(liveStatus(), LiveSyncStatus.idle);
    });

    test('becomes connected when socket connects', () {
      monitor.onSocketStateChanged(const SocketConnected());
      expect(liveStatus(), LiveSyncStatus.connected);
    });

    test('becomes reconnecting after disconnect (was connected)', () {
      monitor.onSocketStateChanged(const SocketConnected());
      monitor.onSocketStateChanged(
          const SocketReconnecting(attempt: 1, maxAttempts: 10));
      expect(liveStatus(), LiveSyncStatus.reconnecting);
    });

    test('stays idle during reconnecting if never was connected', () {
      monitor.onSocketStateChanged(
          const SocketReconnecting(attempt: 1, maxAttempts: 10));
      expect(liveStatus(), LiveSyncStatus.idle);
    });

    test('becomes disconnected on socket error', () {
      monitor.onSocketStateChanged(const SocketConnected());
      monitor.onSocketStateChanged(
          const SocketError('Reconnect limit reached'));
      expect(liveStatus(), LiveSyncStatus.disconnected);
    });
  });

  group('Dashboard badge rules', () {
    test('no offline shown during initial loading', () {
      expect(appStatus(), isNot(AppConnectionStatus.offline));
      expect(appStatus(), AppConnectionStatus.checking);
    });

    test('no offline when API works but WebSocket is down', () {
      monitor.recordApiSuccess();
      monitor.onSocketStateChanged(
          const SocketError('Connection refused'));
      expect(appStatus(), AppConnectionStatus.online);
      expect(liveStatus(), LiveSyncStatus.disconnected);
    });

    test('reconnecting only after channel was previously connected', () {
      monitor.recordApiSuccess();
      monitor.onSocketStateChanged(
          const SocketReconnecting(attempt: 1, maxAttempts: 10));
      expect(liveStatus(), LiveSyncStatus.idle);

      monitor.onSocketStateChanged(const SocketConnected());
      monitor.onSocketStateChanged(
          const SocketReconnecting(attempt: 1, maxAttempts: 10));
      expect(liveStatus(), LiveSyncStatus.reconnecting);
    });

    test('appStatus offline only when no internet', () {
      monitor.recordApiSuccess();
      monitor.recordApiFailure(isNoConnection: true);
      expect(appStatus(), AppConnectionStatus.offline);
    });
  });
}
