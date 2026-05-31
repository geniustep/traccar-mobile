import 'package:flutter/foundation.dart';

import '../debug/debug_log_entry.dart';
import '../debug/debug_log_store.dart';

/// Central debug-only logging for ELMO GPS observability (Phase 5).
///
/// - Emits to [debugPrint] only in [kDebugMode].
/// - Persists a bounded ring buffer for the in-app Debug Console (debug only).
/// - Never logs raw tokens, cookies, or Authorization values (callers must not
///   pass them; [sanitizeLogMessage] helps strip common leak patterns).
abstract final class AppLogger {
  AppLogger._();

  /// When true (default), non-fatal errors log a short stack in debug.
  static bool logShortStackTracesInDebug = true;

  static bool get _emit => kDebugMode;

  // ── Domain channels ─────────────────────────────────────────────────────

  static void navigation(String message) =>
      _log('Navigation', message, category: DebugLogCategory.navigation);

  static void api(String message, {int? durationMs, String? source}) => _log(
        'API',
        message,
        category: DebugLogCategory.api,
        durationMs: durationMs,
        source: source,
      );

  static void apiError(String message, {int? durationMs, String? source}) =>
      _log(
        'API ERROR',
        message,
        isError: true,
        category: DebugLogCategory.api,
        durationMs: durationMs,
        source: source,
      );

  static void alerts(String message) =>
      _log('Alerts', message, category: DebugLogCategory.alerts);

  static void alertsError(String message) =>
      _log('Alerts ERROR', message, isError: true, category: DebugLogCategory.alerts);

  static void fcm(String message) =>
      _log('FCM', message, category: DebugLogCategory.fcm);

  static void fcmError(String message) =>
      _log('FCM ERROR', message, isError: true, category: DebugLogCategory.fcm);

  static void map(String message) => _log('Map', message);

  static void mapError(String message) =>
      _log('Map ERROR', message, isError: true);

  static void comparison(
    String message, {
    int? durationMs,
    String? source,
  }) =>
      _log(
        'Comparison',
        message,
        category: DebugLogCategory.performance,
        durationMs: durationMs,
        source: source,
      );

  static void replay(
    String message, {
    int? durationMs,
    String? source,
  }) =>
      _log(
        'Replay',
        message,
        category: DebugLogCategory.performance,
        durationMs: durationMs,
        source: source,
      );

  static void auth(String message) => _log('Auth', message);

  static void authError(String message) =>
      _log('Auth ERROR', message, isError: true);

  static void dashboard(String message, {int? durationMs}) =>
      _log('Dashboard', message, category: DebugLogCategory.dashboard, durationMs: durationMs);

  static void reports(String message, {int? durationMs, String? source}) =>
      _log(
        'Reports',
        message,
        category: DebugLogCategory.api,
        durationMs: durationMs,
        source: source,
      );

  static void reportsError(String message, {String? source}) =>
      _log(
        'Reports ERROR',
        message,
        isError: true,
        category: DebugLogCategory.api,
        source: source,
      );

  static void liveSyncStale(String message) => liveSync(message);

  static void fleetIntel(String message) => _log('FleetIntel', message);

  static void connection(String message) => _log('Connection', message);

  static void liveSync(String message) => _log('LiveSync', message);

  static void commands(String message) =>
      _log('Commands', message, category: DebugLogCategory.general);

  static void commandsError(String message) =>
      _log('Commands ERROR', message, isError: true, category: DebugLogCategory.general);

  static void websocket(String message) =>
      _log('WebSocket', message, category: DebugLogCategory.websocket);

  static void websocketError(String message) =>
      _log('WebSocket ERROR', message, isError: true, category: DebugLogCategory.websocket);

  static void performance(String message, {int? durationMs, String? source}) =>
      _log(
        'Performance',
        message,
        category: DebugLogCategory.performance,
        durationMs: durationMs,
        source: source,
      );

  /// Generic error channel, e.g. [AppLogger.error('Provider', 'message', e, st)].
  static void error(
    String scope,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    if (!_emit) return;
    final safe = sanitizeLogMessage(message);
    _record('ERROR', '[$scope] $safe', isError: true);
    debugPrint('[ERROR] [$scope] $safe');
    if (error != null) {
      debugPrint('[ERROR] [$scope] cause: ${sanitizeLogMessage('$error')}');
    }
    if (stackTrace != null && logShortStackTracesInDebug) {
      debugPrintStack(stackTrace: stackTrace, maxFrames: 10, label: scope);
    }
  }

  // ── Core ────────────────────────────────────────────────────────────────

  static void _log(
    String tag,
    String message, {
    bool isError = false,
    DebugLogCategory category = DebugLogCategory.general,
    int? durationMs,
    String? source,
  }) {
    if (!_emit) return;
    final safe = sanitizeLogMessage(message);
    _record(
      tag,
      safe,
      isError: isError,
      category: category,
      durationMs: durationMs,
      source: source,
    );
    debugPrint('[$tag] $safe');
  }

  static void _record(
    String tag,
    String message, {
    required bool isError,
    DebugLogCategory category = DebugLogCategory.general,
    int? durationMs,
    String? source,
  }) {
    DebugLogStore.instance.add(
      DebugLogEntry(
        at: DateTime.now(),
        tag: tag,
        message: message,
        isError: isError,
        category: category,
        durationMs: durationMs,
        source: source,
      ),
    );
  }

  /// Best-effort redaction for log lines (not a security boundary).
  static String sanitizeLogMessage(String input) {
    var s = input;
    const keys = [
      'authorization',
      'cookie',
      'set-cookie',
      'password',
      'token',
      'access_token',
      'refresh_token',
      'session',
      'sessionid',
      'secret',
    ];
    for (final k in keys) {
      final re = RegExp('$k["\']?\\s*[:=]\\s*[^,\\s\\]]+', caseSensitive: false);
      s = s.replaceAll(re, '$k=<redacted>');
    }
    // Bearer …
    s = s.replaceAll(
      RegExp(r'Bearer\s+\S+', caseSensitive: false),
      'Bearer <redacted>',
    );
    // crude email mask: keep domain
    s = s.replaceAllMapped(
      RegExp(r'\b([A-Za-z0-9._%+-]{1,2})[A-Za-z0-9._%+-]*@(\S+)\b'),
      (m) => '${m[1]}***@${m[2]}',
    );
    if (s.length > 600) {
      return '${s.substring(0, 600)}…';
    }
    return s;
  }
}
