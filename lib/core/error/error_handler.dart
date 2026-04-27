import 'package:flutter/foundation.dart';
import 'app_exception.dart';
import 'app_failure.dart';
import '../response/result.dart';

/// Central utility for converting raw errors into [AppException] / [AppFailure].
///
/// Use in:
/// - `catch` blocks outside [TraccarClient]
/// - Repository `impl` classes to map [Result<T, AppException>] → [Result<T, AppFailure>]
class ErrorHandler {
  ErrorHandler._();

  // ── Exception conversion ──────────────────────────────────────────────────

  /// Converts any [Object] thrown at runtime into an [AppException].
  static AppException toException(Object error, [StackTrace? stack]) {
    if (error is AppException) return error;
    if (error is FormatException) {
      return ParseException(message: 'Parse error: ${error.message}');
    }
    if (kDebugMode && stack != null) {
      debugPrint('[ErrorHandler] $error\n$stack');
    }
    return UnknownException(message: error.toString());
  }

  // ── Failure conversion ────────────────────────────────────────────────────

  /// Maps a [Result<T, AppException>] to [Result<T, AppFailure>].
  ///
  /// Typical use in repository implementations:
  /// ```dart
  /// final result = await _client.get<List<TraccarDevice>>(...);
  /// return ErrorHandler.mapResult(result);
  /// ```
  static Result<T, AppFailure> mapResult<T>(
    Result<T, AppException> result,
  ) =>
      result.mapError(AppFailure.fromException);

  /// Wraps a [Future] that may throw, converting errors to [AppFailure].
  static Future<Result<T, AppFailure>> guard<T>(
    Future<T> Function() fn,
  ) async {
    try {
      return Result.success(await fn());
    } on AppException catch (e) {
      return Result.failure(AppFailure.fromException(e));
    } catch (e, s) {
      final ex = toException(e, s);
      return Result.failure(AppFailure.fromException(ex));
    }
  }

  // ── User-facing messages ──────────────────────────────────────────────────

  /// Returns a user-friendly string for any [AppFailure].
  static String userMessage(AppFailure failure) => switch (failure) {
        NetworkFailure() =>
          'No internet connection. Check your network and try again.',
        TimeoutFailure() =>
          'Connection timed out. Please try again.',
        AuthFailure() =>
          'Your session has expired. Please log in again.',
        PermissionFailure() =>
          'You do not have permission to perform this action.',
        NotFoundFailure() =>
          'The requested resource was not found.',
        ServerFailure() =>
          'Server error. Our team has been notified.',
        RateLimitFailure() =>
          'Too many requests. Please wait a moment.',
        ValidationFailure(:final message) => message,
        _ => failure.message,
      };

  /// Returns a user-friendly string for any [AppException].
  static String exceptionMessage(AppException ex) =>
      userMessage(AppFailure.fromException(ex));
}
