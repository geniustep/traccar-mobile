import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import '../api/api_config.dart';
import '../error/app_exception.dart';
import '../response/api_response.dart';
import '../response/result.dart';
import '../storage/secure_storage_service.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/connectivity_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/logging_interceptor.dart';

/// Main HTTP client for all Traccar REST API communication.
///
/// All methods return [Result<T, AppException>] — callers never deal
/// with raw exceptions; they pattern-match on Success / Failure.
///
/// Usage:
/// ```dart
/// final result = await traccarClient.get<List<TraccarDevice>>(
///   TraccarEndpoints.devices,
///   fromJson: (data) => (data as List).map(TraccarDevice.fromJson).toList(),
/// );
/// result.when(
///   success: (devices) { /* use devices */ },
///   failure: (ex) { /* show error */ },
/// );
/// ```
class TraccarClient {
  TraccarClient({
    required SecureStorageService storage,
    required Connectivity connectivity,
  }) : _dio = _buildDio(storage, connectivity);

  final Dio _dio;

  /// Expose underlying [Dio] for advanced use-cases (file upload, etc.)
  Dio get dio => _dio;

  // ── Builder ───────────────────────────────────────────────────────────────

  static Dio _buildDio(
    SecureStorageService storage,
    Connectivity connectivity,
  ) {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: ApiConfig.defaultHeaders,
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    dio.interceptors.addAll([
      ConnectivityInterceptor(connectivity),
      AuthInterceptor(storage, dio),
      ErrorInterceptor(),
      LoggingInterceptor(enabled: ApiConfig.loggingEnabled),
    ]);

    return dio;
  }

  // ── HTTP Verbs ────────────────────────────────────────────────────────────

  /// GET request — returns [Result<T, AppException>]
  Future<Result<T, AppException>> get<T>(
    String path, {
    Map<String, dynamic>? query,
    T Function(dynamic json)? fromJson,
    Options? options,
  }) async {
    try {
      final res = await _dio.get(path,
          queryParameters: query, options: options);
      return Result.success(_decode<T>(res.data, fromJson));
    } on DioException catch (e) {
      return Result.failure(_extractException(e));
    } catch (e) {
      return Result.failure(UnknownException(message: e.toString()));
    }
  }

  /// POST request — returns [Result<T, AppException>]
  Future<Result<T, AppException>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? query,
    T Function(dynamic json)? fromJson,
    Options? options,
  }) async {
    try {
      final res = await _dio.post(path,
          data: data, queryParameters: query, options: options);
      return Result.success(_decode<T>(res.data, fromJson));
    } on DioException catch (e) {
      return Result.failure(_extractException(e));
    } catch (e) {
      return Result.failure(UnknownException(message: e.toString()));
    }
  }

  /// PUT request — returns [Result<T, AppException>]
  Future<Result<T, AppException>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? query,
    T Function(dynamic json)? fromJson,
    Options? options,
  }) async {
    try {
      final res = await _dio.put(path,
          data: data, queryParameters: query, options: options);
      return Result.success(_decode<T>(res.data, fromJson));
    } on DioException catch (e) {
      return Result.failure(_extractException(e));
    } catch (e) {
      return Result.failure(UnknownException(message: e.toString()));
    }
  }

  /// DELETE request — returns [Result<void, AppException>]
  Future<Result<void, AppException>> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? query,
    Options? options,
  }) async {
    try {
      await _dio.delete(path,
          data: data, queryParameters: query, options: options);
      return const Result<void, AppException>.success(null);
    } on DioException catch (e) {
      return Result.failure(_extractException(e));
    } catch (e) {
      return Result.failure(UnknownException(message: e.toString()));
    }
  }

  /// PATCH request — returns [Result<T, AppException>]
  Future<Result<T, AppException>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? query,
    T Function(dynamic json)? fromJson,
    Options? options,
  }) async {
    try {
      final res = await _dio.patch(path,
          data: data, queryParameters: query, options: options);
      return Result.success(_decode<T>(res.data, fromJson));
    } on DioException catch (e) {
      return Result.failure(_extractException(e));
    } catch (e) {
      return Result.failure(UnknownException(message: e.toString()));
    }
  }

  // ── Paginated GET ─────────────────────────────────────────────────────────

  /// GET request that returns a wrapped [ApiResponse<T>] with metadata.
  Future<Result<ApiResponse<T>, AppException>> getPaged<T>(
    String path, {
    Map<String, dynamic>? query,
    required T Function(dynamic json) fromJson,
    int page = 1,
    int pageSize = 20,
  }) async {
    final params = {
      ...?query,
      'page': page,
      'pageSize': pageSize,
    };
    try {
      final res = await _dio.get(path, queryParameters: params);
      final apiResponse = ApiResponse<T>.fromJson(
        res.data,
        fromJson,
        statusCode: res.statusCode,
      );
      return Result.success(apiResponse);
    } on DioException catch (e) {
      return Result.failure(_extractException(e));
    } catch (e) {
      return Result.failure(UnknownException(message: e.toString()));
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  T _decode<T>(dynamic data, T Function(dynamic)? fromJson) {
    if (fromJson != null) return fromJson(data);
    return data as T;
  }

  AppException _extractException(DioException e) {
    if (e.error is AppException) return e.error as AppException;
    return UnknownException(message: e.message ?? 'Unknown error');
  }
}
