import 'package:dio/dio.dart';
import '../storage/secure_storage_service.dart';

/// Attaches `Authorization: Basic <base64(email:password)>` to every request.
///
/// Traccar uses HTTP Basic Authentication — no token refresh needed.
/// Credentials are stored encrypted via [SecureStorageService].
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
}
