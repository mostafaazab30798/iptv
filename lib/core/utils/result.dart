/// A lightweight Result type — [Ok] or [Err].
///
/// Forces callers to handle both success and failure paths explicitly.
///
/// ```dart
/// final result = await repo.getChannels();
/// result.when(
///   ok: (channels) => state = AsyncData(channels),
///   err: (e) => state = AsyncError(e, StackTrace.current),
/// );
/// ```
sealed class Result<T> {
  const Result();

  bool get isOk => this is Ok<T>;
  bool get isErr => this is Err<T>;

  T get value => (this as Ok<T>).data;
  AppResultError get error => (this as Err<T>).appError;

  R when<R>({
    required R Function(T data) ok,
    required R Function(AppResultError error) err,
  }) {
    return switch (this) {
      Ok<T>(:final data) => ok(data),
      Err<T>(:final appError) => err(appError),
    };
  }

  /// Maps the success value, leaving errors untouched.
  Result<R> map<R>(R Function(T data) mapper) {
    return switch (this) {
      Ok<T>(:final data) => Ok(mapper(data)),
      Err<T>(:final appError) => Err(appError),
    };
  }

  /// Async flat-map on success path.
  Future<Result<R>> flatMapAsync<R>(
    Future<Result<R>> Function(T data) mapper,
  ) async {
    return switch (this) {
      Ok<T>(:final data) => mapper(data),
      Err<T>(:final appError) => Err(appError),
    };
  }
}

final class Ok<T> extends Result<T> {
  const Ok(this.data);
  final T data;
}

final class Err<T> extends Result<T> {
  const Err(this.appError);
  final AppResultError appError;
}

/// Wrapper so [Result] doesn't depend on `app_error.dart` directly.
/// Use [AppError] subtypes in practice via the named constructors.
class AppResultError {
  const AppResultError(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'AppResultError: $message';
}
