class NetworkException implements Exception {
  const NetworkException({
    required this.message,
    this.statusCode,
    this.code,
  });

  final String message;
  final int? statusCode;
  final String? code;

  factory NetworkException.fromStatusCode(int code, [String? message]) {
    return switch (code) {
      400 => NetworkException(message: message ?? 'Bad request', statusCode: code, code: 'BAD_REQUEST'),
      401 => NetworkException(message: 'Unauthorized. Please log in again.', statusCode: code, code: 'UNAUTHORIZED'),
      403 => NetworkException(message: 'Access denied.', statusCode: code, code: 'FORBIDDEN'),
      404 => NetworkException(message: 'Resource not found.', statusCode: code, code: 'NOT_FOUND'),
      422 => NetworkException(message: message ?? 'Validation error.', statusCode: code, code: 'UNPROCESSABLE'),
      429 => NetworkException(message: 'Too many requests. Please slow down.', statusCode: code, code: 'RATE_LIMITED'),
      500 => NetworkException(message: 'Server error. Please try again later.', statusCode: code, code: 'SERVER_ERROR'),
      503 => NetworkException(message: 'Service unavailable.', statusCode: code, code: 'UNAVAILABLE'),
      _ => NetworkException(message: message ?? 'Unexpected error (HTTP $code)', statusCode: code),
    };
  }

  factory NetworkException.noConnection() => const NetworkException(
        message: 'No internet connection.',
        code: 'NO_CONNECTION',
      );

  factory NetworkException.timeout() => const NetworkException(
        message: 'Request timed out. Please try again.',
        code: 'TIMEOUT',
      );

  factory NetworkException.cancelled() => const NetworkException(
        message: 'Request was cancelled.',
        code: 'CANCELLED',
      );

  bool get isUnauthorized => statusCode == 401;
  bool get isNotFound => statusCode == 404;
  bool get isServerError => (statusCode ?? 0) >= 500;

  @override
  String toString() => 'NetworkException(statusCode: $statusCode, message: $message)';
}
