import 'package:dio/dio.dart';
import '../../storage/secure_storage_service.dart';

/// Attaches `Authorization: Basic <base64(email:password)>` to every request.
///
/// Traccar uses HTTP Basic Authentication — no JWT refresh cycle needed.
/// On 401: credentials are invalid → clear storage so the user is redirected
/// to the login screen by the router.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage, this._dio);

  final SecureStorageService _storage;
  // ignore: unused_field
  final Dio _dio;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final authHeader = await _storage.getBasicAuthHeader();
    if (authHeader != null) {
      options.headers['Authorization'] = authHeader;
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Clear stored credentials on 401, but only when this is NOT the login
    // request itself (login sends Authorization: null explicitly, but check
    // the path as an extra guard to avoid clearing on wrong-password attempts).
    final isLoginPath = err.requestOptions.path.contains('/session') &&
        err.requestOptions.method == 'POST';
    if (err.response?.statusCode == 401 && !isLoginPath) {
      await _storage.clearAll();
    }
    handler.next(err);
  }
}
