/// A discriminated union representing either [Success] or [Failure].
///
/// Use [Result.success] / [Result.failure] to construct.
/// Use [when], [map], [getOrElse] to consume.
sealed class Result<S, F> {
  const Result();

  const factory Result.success(S value) = Success<S, F>;
  const factory Result.failure(F error) = Failure<S, F>;

  // ── Accessors ─────────────────────────────────────────────────────────────

  bool get isSuccess => this is Success<S, F>;
  bool get isFailure => this is Failure<S, F>;

  S? get valueOrNull => switch (this) {
        Success(:final value) => value,
        Failure() => null,
      };

  F? get errorOrNull => switch (this) {
        Failure(:final error) => error,
        Success() => null,
      };

  // ── Pattern matching ──────────────────────────────────────────────────────

  T when<T>({
    required T Function(S value) success,
    required T Function(F error) failure,
  }) =>
      switch (this) {
        Success(:final value) => success(value),
        Failure(:final error) => failure(error),
      };

  T? whenSuccess<T>(T Function(S value) fn) => switch (this) {
        Success(:final value) => fn(value),
        Failure() => null,
      };

  T? whenFailure<T>(T Function(F error) fn) => switch (this) {
        Failure(:final error) => fn(error),
        Success() => null,
      };

  // ── Transformations ───────────────────────────────────────────────────────

  Result<T, F> map<T>(T Function(S value) transform) => switch (this) {
        Success(:final value) => Result.success(transform(value)),
        Failure(:final error) => Result.failure(error),
      };

  Result<S, T> mapError<T>(T Function(F error) transform) => switch (this) {
        Success(:final value) => Result.success(value),
        Failure(:final error) => Result.failure(transform(error)),
      };

  Result<T, F> flatMap<T>(Result<T, F> Function(S value) transform) =>
      switch (this) {
        Success(:final value) => transform(value),
        Failure(:final error) => Result.failure(error),
      };

  S getOrElse(S Function(F error) fallback) => switch (this) {
        Success(:final value) => value,
        Failure(:final error) => fallback(error),
      };

  S getOrDefault(S defaultValue) => switch (this) {
        Success(:final value) => value,
        Failure() => defaultValue,
      };

  /// Unwraps the value or throws the failure as an exception.
  ///
  /// Useful inside data-source layers that still follow a throw-on-error
  /// contract while benefiting from [TraccarClient]'s [Result] return type.
  S getOrThrow() => switch (this) {
        Success(:final value) => value,
        Failure(:final error) =>
          throw (error is Exception ? error : Exception(error.toString())),
      };
}

/// Success variant.
final class Success<S, F> extends Result<S, F> {
  const Success(this.value);
  final S value;

  @override
  String toString() => 'Result.success($value)';
}

/// Failure variant.
final class Failure<S, F> extends Result<S, F> {
  const Failure(this.error);
  final F error;

  @override
  String toString() => 'Result.failure($error)';
}
