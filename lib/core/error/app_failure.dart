import 'app_exception.dart';

/// Domain-layer failure types — decoupled from HTTP exceptions.
///
/// Repositories convert [AppException] → [AppFailure] so that the domain
/// layer never depends on network details.
sealed class AppFailure {
  const AppFailure(this.message);
  final String message;

  // ── Factories ─────────────────────────────────────────────────────────────

  factory AppFailure.fromException(AppException ex) => switch (ex) {
        AuthException() => AuthFailure(ex.message),
        PermissionException() => PermissionFailure(ex.message),
        NotFoundException() => NotFoundFailure(ex.message),
        ConflictException() => ConflictFailure(ex.message),
        ValidationException(:final fieldErrors) =>
          ValidationFailure(ex.message, fieldErrors: fieldErrors),
        NoConnectionException() => const NetworkFailure(),
        TimeoutException() => const TimeoutFailure(),
        CancelledRequestException() => const CancelledFailure(),
        ServerException() => ServerFailure(ex.message),
        RateLimitException() => const RateLimitFailure(),
        ParseException() => ParseFailure(ex.message),
        UnknownException() => UnknownFailure(ex.message),
      };

  // ── Helpers ───────────────────────────────────────────────────────────────

  bool get isAuth => this is AuthFailure;
  bool get isNetwork =>
      this is NetworkFailure || this is TimeoutFailure;

  @override
  String toString() => '$runtimeType($message)';
}

// ── Concrete failure types ────────────────────────────────────────────────────

final class AuthFailure extends AppFailure {
  const AuthFailure([super.message = 'Authentication required.']);
}

final class PermissionFailure extends AppFailure {
  const PermissionFailure([super.message = 'Access denied.']);
}

final class NotFoundFailure extends AppFailure {
  const NotFoundFailure([super.message = 'Not found.']);
}

final class ConflictFailure extends AppFailure {
  const ConflictFailure([super.message = 'Conflict.']);
}

final class ValidationFailure extends AppFailure {
  const ValidationFailure(
    super.message, {
    this.fieldErrors,
  });
  final Map<String, String>? fieldErrors;
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure([super.message = 'No internet connection.']);
}

final class TimeoutFailure extends AppFailure {
  const TimeoutFailure([super.message = 'Request timed out.']);
}

final class CancelledFailure extends AppFailure {
  const CancelledFailure([super.message = 'Request was cancelled.']);
}

final class ServerFailure extends AppFailure {
  const ServerFailure([super.message = 'Server error.']);
}

final class RateLimitFailure extends AppFailure {
  const RateLimitFailure([super.message = 'Too many requests.']);
}

final class ParseFailure extends AppFailure {
  const ParseFailure([super.message = 'Failed to parse response.']);
}

final class UnknownFailure extends AppFailure {
  const UnknownFailure([super.message = 'An unexpected error occurred.']);
}
