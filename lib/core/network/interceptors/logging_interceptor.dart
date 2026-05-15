import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../api/api_config.dart';
import '../../logging/app_logger.dart';

/// Safe HTTP observability: method, path, status, duration — no bodies, no
/// sensitive headers. Active only when [kDebugMode] and [ApiConfig.loggingEnabled].
///
/// Phase 5: Adds performance classification:
///   < 1000ms = normal
///   1000–3000ms = medium
///   > 3000ms = slow
///   > 8000ms = critical slow
class LoggingInterceptor extends Interceptor {
  LoggingInterceptor({bool? enabled})
      : enabled = enabled ?? (kDebugMode && ApiConfig.loggingEnabled);

  final bool enabled;

  static const _kStartKey = '__elmo_req_start_ms';
  static const _kSourceKey = '__elmo_req_source';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (enabled) {
      options.extra[_kStartKey] =
          DateTime.now().millisecondsSinceEpoch;
      final label = _endpointLabel(options);
      AppLogger.api('${options.method.toUpperCase()} $label — started');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (enabled) {
      final ms = _elapsedMs(response.requestOptions);
      final label = _endpointLabel(response.requestOptions);
      final code = response.statusCode ?? 0;
      final source = response.requestOptions.extra[_kSourceKey] as String?;
      final perfLabel = _performanceLabel(ms);

      AppLogger.api(
        '${response.requestOptions.method.toUpperCase()} $label — '
        'status=$code durationMs=$ms $perfLabel'
        '${source != null ? ' source=$source' : ''}',
        durationMs: ms > 0 ? ms : null,
        source: source,
      );

      if (ms > 3000) {
        AppLogger.performance(
          '${response.requestOptions.method.toUpperCase()} $label — '
          '${ms}ms — $perfLabel'
          '${source != null ? ' — source=$source' : ''}',
          durationMs: ms,
          source: source,
        );
      }
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (enabled) {
      final ms = _elapsedMs(err.requestOptions);
      final label = _endpointLabel(err.requestOptions);
      final code = err.response?.statusCode;
      final reason = err.response?.statusMessage ??
          err.message ??
          err.type.name;
      final source = err.requestOptions.extra[_kSourceKey] as String?;

      AppLogger.apiError(
        '${err.requestOptions.method.toUpperCase()} $label — '
        'status=${code ?? 'ERR'} durationMs=$ms — $reason'
        '${source != null ? ' source=$source' : ''}',
        durationMs: ms > 0 ? ms : null,
        source: source,
      );
    }
    handler.next(err);
  }

  static int _elapsedMs(RequestOptions o) {
    final start = o.extra[_kStartKey] as int?;
    if (start == null) return -1;
    return DateTime.now().millisecondsSinceEpoch - start;
  }

  static String _endpointLabel(RequestOptions o) {
    var path = o.uri.path;
    if (path.isEmpty) path = '/';
    final q = _safeQuery(o.queryParameters);
    if (q.isEmpty) return path;
    return '$path?$q';
  }

  static String _performanceLabel(int ms) {
    if (ms < 0) return '';
    if (ms > 8000) return '[CRITICAL SLOW]';
    if (ms > 3000) return '[SLOW]';
    if (ms > 1000) return '[MEDIUM]';
    return '';
  }

  /// Drops sensitive query keys; never prints full raw map.
  static String _safeQuery(Map<String, dynamic> query) {
    if (query.isEmpty) return '';
    final buf = <String>[];
    for (final e in query.entries) {
      final k = e.key.toLowerCase();
      if (_sensitiveKey(k)) continue;
      buf.add('${e.key}=${_truncateValue('${e.value}', 48)}');
    }
    return buf.join('&');
  }

  static bool _sensitiveKey(String k) {
    return k.contains('password') ||
        k.contains('token') ||
        k.contains('secret') ||
        k.contains('session') ||
        k.contains('cookie') ||
        k.contains('auth');
  }

  static String _truncateValue(String v, int max) {
    if (v.length <= max) return v;
    return '${v.substring(0, max)}…';
  }
}
