import 'package:dio/dio.dart';

import '../../connection/app_connection_monitor.dart';

/// Reports every REST response (success or failure) to [AppConnectionMonitor]
/// so that [AppConnectionStatus] stays up-to-date without polling.
class ConnectionStatusInterceptor extends Interceptor {
  ConnectionStatusInterceptor(this._monitor);

  final AppConnectionMonitor _monitor;

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _monitor.recordApiSuccess();
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final statusCode = err.response?.statusCode;
    _monitor.recordApiFailure(
      isAuthError: statusCode == 401,
      isServerError: statusCode != null && statusCode >= 500,
      isNoConnection: err.type == DioExceptionType.connectionError,
    );
    handler.next(err);
  }
}
