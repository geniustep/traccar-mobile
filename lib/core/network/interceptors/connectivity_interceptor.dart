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
    final result = await _connectivity.checkConnectivity();
    final hasConnection = result != ConnectivityResult.none;

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
