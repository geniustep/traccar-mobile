import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../network/auth_interceptor.dart';
import '../network/network_exception.dart';
import '../storage/secure_storage_service.dart';

class DioClient {
  DioClient(AppConfig config, SecureStorageService storage)
      : _dio = _buildDio(config, storage);

  final Dio _dio;

  Dio get instance => _dio;

  static Dio _buildDio(AppConfig config, SecureStorageService storage) {
    final dio = Dio(
      BaseOptions(
        baseUrl: config.baseUrl,
        connectTimeout: Duration(milliseconds: config.connectTimeoutMs),
        receiveTimeout: Duration(milliseconds: config.receiveTimeoutMs),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
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
      DioExceptionType.connectionError => NetworkException.noConnection(),
      DioExceptionType.badResponse => NetworkException.fromStatusCode(
          e.response?.statusCode ?? 0,
          _extractMessage(e.response?.data),
        ),
      _ => NetworkException(message: e.message ?? 'Unexpected error'),
    };
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
  }) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return fromJson != null ? fromJson(response.data) : response.data as T;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<T> post<T>(
    String path, {
    dynamic data,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.post(path, data: data);
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

  Future<void> delete(String path) async {
    try {
      await _dio.delete(path);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
}
