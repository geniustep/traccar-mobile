import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Logs every request and response in debug mode.
/// Automatically disabled in release/profile builds.
class LoggingInterceptor extends Interceptor {
  LoggingInterceptor({bool? enabled})
      : enabled = enabled ?? LoggingInterceptor._isDebugBuild();

  final bool enabled;

  /// Canonical assert-based debug detection — avoids const-eval analyzer issues.
  static bool _isDebugBuild() {
    var debug = false;
    assert(() {
      debug = true;
      return true;
    }());
    return debug;
  }

  static final _sep = '─' * 60;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (enabled) {
      debugPrint('\n$_sep');
      debugPrint('➡️  ${options.method.toUpperCase()} ${options.uri}');
      if (options.queryParameters.isNotEmpty) {
        debugPrint('   Query : ${options.queryParameters}');
      }
      if (options.data != null) {
        debugPrint('   Body  : ${options.data}');
      }
      debugPrint(_sep);
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (enabled) {
      debugPrint('\n$_sep');
      debugPrint(
        '✅  ${response.statusCode} ${response.requestOptions.method.toUpperCase()} '
        '${response.requestOptions.uri}',
      );
      debugPrint('   Data  : ${_truncate(response.data.toString())}');
      debugPrint(_sep);
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (enabled) {
      debugPrint('\n$_sep');
      debugPrint(
        '❌  ${err.response?.statusCode ?? "ERR"} '
        '${err.requestOptions.method.toUpperCase()} '
        '${err.requestOptions.uri}',
      );
      debugPrint('   Error : ${err.message}');
      if (err.response?.data != null) {
        debugPrint('   Body  : ${_truncate(err.response!.data.toString())}');
      }
      debugPrint(_sep);
    }
    handler.next(err);
  }

  String _truncate(String s, [int max = 500]) =>
      s.length > max ? '${s.substring(0, max)}…' : s;
}
