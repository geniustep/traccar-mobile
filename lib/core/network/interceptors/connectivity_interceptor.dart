import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import '../../error/app_exception.dart';

/// Checks network connectivity before every request.
/// Throws [AppException.noConnection] immediately if offline,
/// avoiding a lengthy timeout wait.
class ConnectivityInterceptor extends Interceptor {
  ConnectivityInterceptor(this._connectivity);

  final Connectivity _connectivity;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // connectivity_plus v5+ returns List<ConnectivityResult>; earlier versions
    // returned a single ConnectivityResult. Handle both shapes defensively.
    final dynamic result = await _connectivity.checkConnectivity();
    final bool hasConnection = switch (result) {
      final List<dynamic> list =>
          list.any((r) => r != ConnectivityResult.none),
      ConnectivityResult.none => false,
      _ => true,
    };

    if (!hasConnection) {
      return handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          error: AppException.noConnection(),
          message: 'No internet connection.',
        ),
        true,
      );
    }
    handler.next(options);
  }
}
