/// Unified exception hierarchy for the entire application.
///
/// All network / domain / storage errors are converted to [AppException]
/// before reaching the UI layer.
sealed class AppException implements Exception {
  const AppException({
    required this.message,
    this.statusCode,
    this.code,
    this.details,
  });

  final String message;
  final int? statusCode;
  final String? code;

  /// Raw server response body or extra context.
  final dynamic details;

  // ── Factories ─────────────────────────────────────────────────────────────

  factory AppException.fromStatusCode(int statusCode, [String? message]) {
    return switch (statusCode) {
      400 => ValidationException(
          message: message ?? 'Bad request',
          statusCode: statusCode,
        ),
      401 => const AuthException(),
      403 => const PermissionException(),
      404 => NotFoundException(
          message: message ?? 'Resource not found.',
          statusCode: statusCode,
        ),
      408 => const TimeoutException(),
      409 => ConflictException(
          message: message ?? 'Conflict with existing data.',
          statusCode: statusCode,
        ),
      422 => ValidationException(
          message: message ?? 'Validation error.',
          statusCode: statusCode,
        ),
      429 => const RateLimitException(),
      >= 500 => ServerException(
          message: message ?? 'Server error. Please try again later.',
          statusCode: statusCode,
        ),
      _ => UnknownException(
          message: message ?? 'Unexpected error (HTTP $statusCode)',
          statusCode: statusCode,
        ),
    };
  }

  factory AppException.noConnection() => const NoConnectionException();

  factory AppException.timeout() => const TimeoutException();

  factory AppException.cancelled() => const CancelledRequestException();

  // ── Type helpers ──────────────────────────────────────────────────────────

  bool get isAuth => this is AuthException;
  bool get isNetwork => this is NoConnectionException || this is TimeoutException;
  bool get isServer => this is ServerException;
  bool get isNotFound => this is NotFoundException;
  bool get isValidation => this is ValidationException;

  @override
  String toString() =>
      '$runtimeType(code: $code, status: $statusCode, message: $message)';
}

// ── Concrete types ────────────────────────────────────────────────────────────

/// 401 — Session expired or invalid token
final class AuthException extends AppException {
  const AuthException({super.message = 'Authentication required.', super.statusCode})
      : super(code: 'UNAUTHORIZED');
}

/// 403 — Authenticated but forbidden
final class PermissionException extends AppException {
  const PermissionException({super.message = 'Access denied.', super.statusCode})
      : super(code: 'FORBIDDEN');
}

/// 404 — Entity not found
final class NotFoundException extends AppException {
  const NotFoundException({super.message = 'Not found.', super.statusCode})
      : super(code: 'NOT_FOUND');
}

/// 409 — Duplicate or state conflict
final class ConflictException extends AppException {
  const ConflictException({super.message = 'Conflict.', super.statusCode})
      : super(code: 'CONFLICT');
}

/// 400 / 422 — Validation / bad input
final class ValidationException extends AppException {
  const ValidationException({
    super.message = 'Validation error.',
    super.statusCode,
    this.fieldErrors,
  }) : super(code: 'VALIDATION');

  final Map<String, String>? fieldErrors;
}

/// 429 — Rate limited
final class RateLimitException extends AppException {
  const RateLimitException({super.message = 'Too many requests.', super.statusCode})
      : super(code: 'RATE_LIMITED');
}

/// 5xx — Server-side failure
final class ServerException extends AppException {
  const ServerException({
    super.message = 'Server error.',
    super.statusCode,
    super.details,
  }) : super(code: 'SERVER_ERROR');
}

/// No internet connectivity
final class NoConnectionException extends AppException {
  const NoConnectionException()
      : super(message: 'No internet connection.', code: 'NO_CONNECTION');
}

/// Request / socket timed out
final class TimeoutException extends AppException {
  const TimeoutException({super.message = 'Request timed out.'})
      : super(code: 'TIMEOUT');
}

/// Request deliberately cancelled
final class CancelledRequestException extends AppException {
  const CancelledRequestException()
      : super(message: 'Request was cancelled.', code: 'CANCELLED');
}

/// Parse / deserialization error
final class ParseException extends AppException {
  const ParseException({super.message = 'Failed to parse response.', super.details})
      : super(code: 'PARSE_ERROR');
}

/// Catch-all for anything else
final class UnknownException extends AppException {
  const UnknownException({
    super.message = 'An unexpected error occurred.',
    super.statusCode,
    super.details,
  }) : super(code: 'UNKNOWN');
}
