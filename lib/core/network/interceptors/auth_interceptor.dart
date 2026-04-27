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
    if (err.response?.statusCode == 401) {
      // Credentials are wrong or expired — force re-login
      await _storage.clearAll();
    }
    handler.next(err);
  }
}
