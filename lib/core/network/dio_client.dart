import 'dart:io';
import 'package:dio/dio.dart';
import '../api/api_config.dart';
import '../network/auth_interceptor.dart';
import '../network/network_exception.dart';
import '../storage/secure_storage_service.dart';

/// Legacy HTTP client kept for backward compatibility.
/// All new code should use [TraccarClient] which returns [Result<T, AppException>].
class DioClient {
  DioClient(SecureStorageService storage)
      : _dio = _buildDio(storage);

  final Dio _dio;

  Dio get instance => _dio;

  static Dio _buildDio(SecureStorageService storage) {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: ApiConfig.defaultHeaders,
      ),
    );

    // Auth interceptor references dio itself for refresh retry
    final authInterceptor = AuthInterceptor(storage, dio);

    dio.interceptors.addAll([
      authInterceptor,
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (_) {}, // silence in prod; swap with debugPrint for dev
      ),
    ]);

    return dio;
  }

  NetworkException _handleError(DioException e) {
    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        NetworkException.timeout(),
      DioExceptionType.cancel => NetworkException.cancelled(),
      DioExceptionType.connectionError => _handleConnectionError(e),
      DioExceptionType.badResponse => NetworkException.fromStatusCode(
          e.response?.statusCode ?? 0,
          _extractMessage(e.response?.data),
        ),
      _ => NetworkException(message: e.message ?? 'Unexpected error'),
    };
  }

  /// Distinguishes between true "no internet" and "server unreachable".
  static NetworkException _handleConnectionError(DioException e) {
    final inner = e.error;

    if (inner is SocketException) {
      final msg = inner.message.toLowerCase();
      // DNS failure → host does not exist at all
      if (msg.contains('failed host lookup') ||
          msg.contains('no address associated') ||
          msg.contains('nodename nor servname')) {
        return NetworkException(
          message: 'Server not found: "${e.requestOptions.baseUrl}"\n'
              'Check the server URL in AppConfig.',
          code: 'HOST_NOT_FOUND',
        );
      }
      // Connection refused → server exists but is not listening
      if (msg.contains('connection refused')) {
        return const NetworkException(
          message: 'Connection refused by the server. '
              'Make sure the ELMOGPS platform is running.',
          code: 'CONNECTION_REFUSED',
        );
      }
      // Network unreachable → truly no internet
      if (msg.contains('network is unreachable') ||
          msg.contains('no route to host')) {
        return NetworkException.noConnection();
      }
      // Fallback with the actual OS message for debugging
      return NetworkException(
        message: 'Connection error: ${inner.message}',
        code: 'CONNECTION_ERROR',
      );
    }

    // Generic fallback
    return NetworkException.noConnection();
  }

  String? _extractMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['message'] as String? ?? data['error'] as String?;
    }
    return null;
  }

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return fromJson != null ? fromJson(response.data) : response.data as T;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<T> post<T>(
    String path, {
    dynamic data,
    T Function(dynamic)? fromJson,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(path, data: data, options: options);
      return fromJson != null ? fromJson(response.data) : response.data as T;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<T> put<T>(
    String path, {
    dynamic data,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.put(path, data: data);
      return fromJson != null ? fromJson(response.data) : response.data as T;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<T> patch<T>(
    String path, {
    dynamic data,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.patch(path, data: data);
      return fromJson != null ? fromJson(response.data) : response.data as T;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> delete(String path, {Options? options}) async {
    try {
      await _dio.delete(path, options: options);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
}
