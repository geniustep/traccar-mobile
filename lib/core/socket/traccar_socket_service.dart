import 'dart:async';
import 'dart:io';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../api/api_config.dart';
import '../logging/app_logger.dart';
import '../storage/secure_storage_service.dart';
import 'socket_event_parser.dart';
import 'socket_state.dart';

/// Authentication mode used for the current WebSocket connection.
enum SocketAuthMode {
  /// Cookie header: `Cookie: JSESSIONID=...`
  sessionCookieHeader,

  /// Query parameter fallback: `?session=...`
  sessionQueryFallback,

  /// Token-based auth: `?token=...`
  token,

  /// No auth available
  none,
}

/// Manages the ELMOGPS WebSocket connection with:
/// - Explicit JSESSIONID Cookie header for WebSocket handshake
/// - Fallback to ?session= query parameter if Cookie header fails
/// - Automatic reconnection with exponential backoff
/// - WebSocket protocol ping (via [IOWebSocketChannel] pingInterval)
/// - Stream of [SocketMessage] for consumers
/// - Structured diagnostics for Debug Console
class TraccarSocketService {
  TraccarSocketService({required SecureStorageService storage})
      : _storage = storage,
        _parser = const SocketEventParser();

  final SecureStorageService _storage;
  final SocketEventParser _parser;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _reconnectTimer;

  int _reconnectAttempt = 0;
  bool _manualDisconnect = false;
  String? _lastErrorSummary;

  /// Tracks whether Cookie header failed so fallback is used on retry.
  bool _cookieHeaderFailed = false;

  /// Structured diagnostics exposed to Debug Console.
  final WebSocketDiagnostics diagnostics = WebSocketDiagnostics();

  // ── Public streams ────────────────────────────────────────────────────────

  final _messageController = StreamController<SocketMessage>.broadcast();
  final _stateController = StreamController<SocketState>.broadcast();

  Stream<SocketMessage> get messageStream => _messageController.stream;
  Stream<SocketState> get stateStream => _stateController.stream;

  SocketState _currentState = const SocketDisconnected();
  SocketState get currentState => _currentState;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  Future<void> connect() async {
    _manualDisconnect = false;
    _reconnectAttempt = 0;
    _cookieHeaderFailed = false;
    diagnostics.retryAttempt = 0;
    await _doConnect();
  }

  /// Force reconnect — callable from Debug Console "Reconnect now" button.
  Future<void> reconnectNow() async {
    AppLogger.websocket('Manual reconnect requested from Debug Console');
    _manualDisconnect = false;
    _reconnectAttempt = 0;
    _cookieHeaderFailed = false;
    diagnostics.retryAttempt = 0;
    _cleanup();
    await _doConnect();
  }

  void disconnect() {
    _manualDisconnect = true;
    _cleanup();
    _emit(const SocketDisconnected());
    diagnostics.connectionState = 'disconnected';
  }

  void dispose() {
    _manualDisconnect = true;
    _cleanup();
    _messageController.close();
    _stateController.close();
  }

  /// Test session validity by calling GET /session.
  /// Returns a map with status info for the Debug Console.
  Future<Map<String, dynamic>> testSession() async {
    AppLogger.websocket('Test session requested');
    try {
      final client = HttpClient();
      final uri = Uri.parse('${ApiConfig.baseUrl}/session');
      final request = await client.getUrl(uri);

      final jsessionId = await _storage.getJsessionId();
      if (jsessionId != null && jsessionId.isNotEmpty) {
        request.headers.add('Cookie', 'JSESSIONID=$jsessionId');
      }

      final response = await request.close();
      final status = response.statusCode;
      client.close();

      String result;
      if (status == 200) {
        result = 'Session valid (200 OK)';
        AppLogger.websocket('Test session: 200 OK — session valid');
      } else if (status == 401 || status == 403) {
        result = 'Session expired or invalid ($status)';
        AppLogger.websocketError('Test session: $status — session invalid');
      } else {
        result = 'Unexpected status: $status';
        AppLogger.websocketError('Test session: unexpected status $status');
      }

      return {'status': status, 'result': result};
    } catch (e) {
      final result = 'Network error: ${_sanitizeError(e.toString())}';
      AppLogger.websocketError('Test session failed: $result');
      return {'status': null, 'result': result};
    }
  }

  // ── Connection logic ──────────────────────────────────────────────────────

  Future<void> _doConnect() async {
    _cleanup();
    _emit(const SocketConnecting());
    diagnostics.connectionState = 'connecting';

    try {
      final jsessionId = await _storage.getJsessionId();
      final tokenValue = await _storage.getAccessToken();

      final hasSession = jsessionId != null && jsessionId.isNotEmpty;
      final hasToken = tokenValue != null && tokenValue.isNotEmpty;

      if (!hasSession && !hasToken) {
        AppLogger.websocket(
          'Skipped: no valid session cookie or token available',
        );
        _emit(const SocketError(
          'Live sync unavailable — no active session. '
          'REST API may still work.',
        ));
        diagnostics
          ..connectionState = 'failed'
          ..lastError = 'No session cookie or token available'
          ..lastErrorAt = DateTime.now()
          ..authMode = SocketAuthMode.none.name
          ..cookiePresent = false;
        return;
      }

      diagnostics.cookiePresent = hasSession;

      // Determine auth mode:
      // 1. sessionCookieHeader (preferred) — Cookie header with JSESSIONID
      // 2. sessionQueryFallback — ?session= query param (if cookie header failed)
      // 3. token — ?token= query param (if no session available)
      final SocketAuthMode authMode;
      final Map<String, String> headers = {};
      Uri socketUri;

      if (hasSession && !_cookieHeaderFailed) {
        // PRIMARY: Cookie header approach
        authMode = SocketAuthMode.sessionCookieHeader;
        headers['Cookie'] = 'JSESSIONID=$jsessionId';
        socketUri = ApiConfig.buildSocketUri(
          Uri.parse(ApiConfig.baseUrl),
          configuredSocketUrl: ApiConfig.socketUrl,
        );
      } else if (hasSession && _cookieHeaderFailed) {
        // FALLBACK: session query parameter
        authMode = SocketAuthMode.sessionQueryFallback;
        socketUri = _buildSocketUriWithSession(jsessionId);
      } else {
        // TOKEN: token query parameter
        authMode = SocketAuthMode.token;
        socketUri = ApiConfig.buildSocketUri(
          Uri.parse(ApiConfig.baseUrl),
          configuredSocketUrl: ApiConfig.socketUrl,
          token: tokenValue,
        );
      }

      diagnostics
        ..authMode = authMode.name
        ..endpoint = _sanitizeUri(socketUri)
        ..maxRetries = ApiConfig.maxSocketReconnectAttempts;

      AppLogger.websocket('URL built: ${_sanitizeUri(socketUri)}');
      AppLogger.websocket('Auth mode: ${authMode.name}');
      AppLogger.websocket('Cookie present: $hasSession');

      if (authMode == SocketAuthMode.sessionQueryFallback) {
        AppLogger.websocket('Connecting with session query fallback');
      } else {
        AppLogger.websocket('Connecting...');
      }

      _channel = IOWebSocketChannel.connect(
        socketUri,
        headers: headers.isNotEmpty ? headers : null,
        pingInterval: ApiConfig.socketPingInterval,
      );

      await _channel!.ready;

      // Connection succeeded
      _reconnectAttempt = 0;
      _lastErrorSummary = null;
      diagnostics
        ..retryAttempt = 0
        ..lastConnectedAt = DateTime.now()
        ..connectionState = 'connected'
        ..lastHttpStatus = null
        ..lastError = null
        ..nextRetrySeconds = 0;

      _emit(const SocketConnected());

      _subscription = _channel!.stream.listen(
        _onData,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );

      AppLogger.websocket('Connected');
    } catch (e) {
      final errStr = e.toString();

      // If Cookie header approach failed with 503, switch to query fallback
      if (!_cookieHeaderFailed &&
          diagnostics.authMode == SocketAuthMode.sessionCookieHeader.name &&
          _is503Error(errStr)) {
        AppLogger.websocket(
          'Cookie header auth returned 503 — switching to session query fallback',
        );
        _cookieHeaderFailed = true;
        // Clean up the failed attempt
        _subscription?.cancel();
        try {
          _channel?.sink.close(WebSocketStatus.normalClosure);
        } catch (_) {}
        _channel = null;
        // Retry immediately with fallback
        await _doConnect();
        return;
      }

      _onError(e);
      _subscription?.cancel();
      _subscription = null;
      try {
        _channel?.sink.close(WebSocketStatus.normalClosure);
      } catch (_) {}
      _channel = null;
    }
  }

  /// Builds socket URI with session as query parameter (fallback method).
  Uri _buildSocketUriWithSession(String jsessionId) {
    final baseUri = ApiConfig.buildSocketUri(
      Uri.parse(ApiConfig.baseUrl),
      configuredSocketUrl: ApiConfig.socketUrl,
    );
    return baseUri.replace(
      queryParameters: {'session': jsessionId},
    );
  }

  /// Sanitizes URI for logging — removes session/token query values.
  String _sanitizeUri(Uri uri) {
    if (uri.queryParameters.isEmpty) return uri.toString();
    final sanitizedParams = uri.queryParameters.map((key, value) {
      if (key == 'session' || key == 'token') {
        return MapEntry(key, '<redacted>');
      }
      return MapEntry(key, value);
    });
    return uri.replace(queryParameters: sanitizedParams).toString();
  }

  bool _is503Error(String msg) {
    return msg.contains('503') || msg.contains('Service Unavailable');
  }

  void _onData(dynamic raw) {
    if (raw is! String) return;
    final msg = _parser.parse(raw);
    if (!msg.isEmpty) {
      _messageController.add(msg);
    }
  }

  void _onError(Object error) {
    final summary = error.toString();
    _lastErrorSummary = summary;
    diagnostics.lastErrorAt = DateTime.now();

    final httpStatus = _extractHttpStatus(summary);
    diagnostics.lastHttpStatus = httpStatus;

    if (httpStatus == 503) {
      diagnostics.lastError =
          'WebSocket endpoint returned 503. Possible causes: '
          'socket service unavailable, proxy upgrade issue, '
          'expired session, or missing session cookie.';
      AppLogger.websocketError(diagnostics.structuredLog);
    } else {
      diagnostics.lastError = _sanitizeError(summary);
      AppLogger.websocketError(
        '[WebSocket] Error: ${diagnostics.lastError} '
        'endpoint=${diagnostics.endpoint} '
        'authMode=${diagnostics.authMode} '
        'cookiePresent=${diagnostics.cookiePresent}',
      );
    }
    _scheduleReconnect();
  }

  int? _extractHttpStatus(String msg) {
    if (msg.contains('503') || msg.contains('Service Unavailable')) return 503;
    if (msg.contains('502') || msg.contains('Bad Gateway')) return 502;
    if (msg.contains('401') || msg.contains('Unauthorized')) return 401;
    if (msg.contains('403') || msg.contains('Forbidden')) return 403;
    if (msg.contains('429') || msg.contains('Too Many Requests')) return 429;
    return null;
  }

  String _sanitizeError(String msg) {
    return msg
        .replaceAll(RegExp(r'JSESSIONID=[^\s;]+'), 'JSESSIONID=<redacted>')
        .replaceAll(RegExp(r'session=[^\s&]+'), 'session=<redacted>')
        .replaceAll(RegExp(r'token=[^\s&]+'), 'token=<redacted>')
        .replaceAll(RegExp(r'Basic\s+\S+'), 'Basic <redacted>');
  }

  void _onDone() {
    AppLogger.websocket('Connection closed');
    if (!_manualDisconnect) _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_manualDisconnect) return;

    final maxAttempts = ApiConfig.maxSocketReconnectAttempts;
    _reconnectAttempt++;
    diagnostics.retryAttempt = _reconnectAttempt;

    if (_reconnectAttempt > maxAttempts) {
      diagnostics.connectionState = 'failed';
      diagnostics.nextRetrySeconds = 0;
      _emit(const SocketError('Reconnect limit reached. Check your connection.'));
      AppLogger.websocketError(
        '[WebSocket] Reconnect limit reached: '
        'retry=$_reconnectAttempt/$maxAttempts '
        'endpoint=${diagnostics.endpoint}',
      );
      return;
    }

    diagnostics.connectionState = 'reconnecting';
    final delay = _reconnectDelay(_reconnectAttempt);
    diagnostics.nextRetrySeconds = delay.inSeconds;

    _emit(SocketReconnecting(
      attempt: _reconnectAttempt,
      maxAttempts: maxAttempts,
      nextRetrySeconds: delay.inSeconds,
    ));

    AppLogger.websocket(
      '[WebSocket] Reconnect scheduled: '
      'retry=$_reconnectAttempt/$maxAttempts '
      'nextRetry=${delay.inSeconds}s '
      'endpoint=${diagnostics.endpoint}',
    );

    _reconnectTimer = Timer(
      delay,
      () {
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

  void _cleanup() {
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
