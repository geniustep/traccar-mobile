import 'package:dio/dio.dart';
import '../../error/app_exception.dart';

/// Converts every [DioException] into an [AppException] before it
/// propagates to the caller.  The caller only ever sees [AppException].
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final appEx = _convert(err);
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: appEx,
        message: appEx.message,
      ),
    );
  }

  AppException _convert(DioException e) {
    if (e.error is AppException) return e.error as AppException;

    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        AppException.timeout(),
      DioExceptionType.cancel => AppException.cancelled(),
      DioExceptionType.connectionError => AppException.noConnection(),
      DioExceptionType.badResponse => AppException.fromStatusCode(
          e.response?.statusCode ?? 0,
          _extractMessage(e.response?.data),
        ),
      _ => UnknownException(message: e.message ?? 'Unexpected error occurred'),
    };
  }

  String? _extractMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['message'] as String? ??
          data['error'] as String? ??
          data['reason'] as String?;
    }
    if (data is String && data.isNotEmpty) return data;
    return null;
  }
}
