import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../api/api_config.dart';
import '../storage/secure_storage_service.dart';
import 'socket_event_parser.dart';
import 'socket_state.dart';

/// Manages the Traccar WebSocket connection with:
/// - Automatic reconnection with exponential backoff
/// - Traccar auth: `Authorization: Basic …` (same as REST), optional
///   `Cookie: JSESSIONID=…` when stored from POST /session, plus subprotocol `json`
/// - Ping-keepalive to prevent silent disconnects
/// - Stream of [SocketMessage] for consumers
///
/// Usage:
/// ```dart
/// final svc = TraccarSocketService(storage: storage);
/// svc.connect();
/// svc.messageStream.listen((msg) { ... });
/// svc.stateStream.listen((state) { ... });
/// ```
class TraccarSocketService {
  TraccarSocketService({required SecureStorageService storage})
      : _storage = storage,
        _parser = const SocketEventParser();

  final SecureStorageService _storage;
  final SocketEventParser _parser;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _pingTimer;
  Timer? _reconnectTimer;

  int _reconnectAttempt = 0;
  bool _manualDisconnect = false;
  /// Last connect/stream error; used to back off more on 503 / 429.
  String? _lastErrorSummary;

  // ── Public streams ────────────────────────────────────────────────────────

  final _messageController =
      StreamController<SocketMessage>.broadcast();
  final _stateController =
      StreamController<SocketState>.broadcast();

  Stream<SocketMessage> get messageStream => _messageController.stream;
  Stream<SocketState> get stateStream => _stateController.stream;

  SocketState _currentState = const SocketDisconnected();
  SocketState get currentState => _currentState;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  Future<void> connect() async {
    _manualDisconnect = false;
    _reconnectAttempt = 0;
    await _doConnect();
  }

  void disconnect() {
    _manualDisconnect = true;
    _cleanup();
    _emit(const SocketDisconnected());
  }

  void dispose() {
    _manualDisconnect = true;
    _cleanup();
    _messageController.close();
    _stateController.close();
  }

  // ── Connection logic ──────────────────────────────────────────────────────

  Future<void> _doConnect() async {
    _cleanup();
    _emit(const SocketConnecting());

    try {
      final headers = <String, String>{};

      final basic = await _storage.getBasicAuthHeader();
      if (basic != null && basic.isNotEmpty) {
        headers['Authorization'] = basic;
      } else {
        final token = await _storage.getAccessToken();
        if (token != null && token.isNotEmpty) {
          headers['Authorization'] = 'Bearer $token';
        }
      }

      final jsessionId = await _storage.getJsessionId();
      if (jsessionId != null && jsessionId.isNotEmpty) {
        headers['Cookie'] = 'JSESSIONID=$jsessionId';
      }

      _channel = IOWebSocketChannel.connect(
        Uri.parse(ApiConfig.socketUrl),
        headers: headers,
        pingInterval: ApiConfig.socketPingInterval,
        protocols: const ['json'],
      );

      // Must await [ready]: connection failures complete [WebSocketChannel.ready]
      // with an error. If that Future is not awaited, the same error is still
      // sent on [stream] but [ready] also becomes an unhandled async error.
      await _channel!.ready;

      _reconnectAttempt = 0;
      _lastErrorSummary = null;
      _emit(const SocketConnected());
      _startPing();

      _subscription = _channel!.stream.listen(
        _onData,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );

      if (kDebugMode) {
        debugPrint('[Socket] Connected → ${ApiConfig.socketUrl}');
      }
    } catch (e) {
      _onError(e);
      // Do not call [_cleanup] here: it cancels [_reconnectTimer] that
      // [_onError] may have just scheduled. Only drop the failed channel.
      _pingTimer?.cancel();
      _pingTimer = null;
      _subscription?.cancel();
      _subscription = null;
      try {
        _channel?.sink.close(WebSocketStatus.normalClosure);
      } catch (_) {}
      _channel = null;
    }
  }

  void _onData(dynamic raw) {
    if (raw is! String) return;
    final msg = _parser.parse(raw);
    if (!msg.isEmpty) {
      _messageController.add(msg);
    }
  }

  void _onError(Object error) {
    if (kDebugMode) debugPrint('[Socket] Error: $error');
    _lastErrorSummary = error.toString();
    _scheduleReconnect();
  }

  void _onDone() {
    if (kDebugMode) debugPrint('[Socket] Connection closed');
    if (!_manualDisconnect) _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_manualDisconnect) return;

    final maxAttempts = ApiConfig.maxSocketReconnectAttempts;
    _reconnectAttempt++;

    if (_reconnectAttempt > maxAttempts) {
      _emit(const SocketError('Reconnect limit reached. Check your connection.'));
      return;
    }

    _emit(SocketReconnecting(
      attempt: _reconnectAttempt,
      maxAttempts: maxAttempts,
    ));

    final delay = _reconnectDelay(_reconnectAttempt);
    if (kDebugMode) {
      debugPrint(
        '[Socket] Reconnecting in ${delay.inSeconds}s '
        '($_reconnectAttempt/$maxAttempts)',
      );
    }

    _reconnectTimer = Timer(
      delay,
      () {
        // Dropping a Future from an async [Timer] callback can surface
        // as a global "Unhandled Exception" if the Future completes with
        // an error; route any such errors through the same handler as the stream.
        unawaited(
          _doConnect().then<void>(
            (_) {},
            onError: (e, st) {
              if (e is Object) {
                _onError(e);
              } else {
                _onError(Exception('Socket: $e'));
              }
            },
          ),
        );
      },
    );
  }

  /// Exponential backoff: 5s, 10s, 20s … capped at 60s.
  /// After HTTP 429 / 503, wait longer to avoid rate limits and overload thundering herds.
  Duration _reconnectDelay(int attempt) {
    final base = _exponentialBackoffSeconds(attempt);
    final s = _lastErrorSummary ?? '';
    final is429 = s.contains('429') || s.contains('Too Many Requests');
    final is503 = s.contains('503') || s.contains('Service Unavailable');
    if (is429) {
      return Duration(seconds: base > 90 ? base : 90);
    }
    if (is503) {
      return Duration(seconds: base > 45 ? base : 45);
    }
    return Duration(seconds: base);
  }

  int _exponentialBackoffSeconds(int attempt) {
    final base = ApiConfig.socketReconnectDelay.inSeconds;
    return (base * (1 << (attempt - 1))).clamp(base, 60);
  }

  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(ApiConfig.socketPingInterval, (_) {
      try {
        _channel?.sink.add('ping');
      } catch (_) {}
    });
  }

  void _cleanup() {
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    try {
      _channel?.sink.close(WebSocketStatus.normalClosure);
    } catch (_) {}
    _channel = null;
  }

  void _emit(SocketState state) {
    _currentState = state;
    if (!_stateController.isClosed) {
      _stateController.add(state);
    }
  }
}
