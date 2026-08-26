/// Typed wrapper around an API response.
///
/// Use [ApiResult.ok] and [ApiResult.err] to construct.
/// Prefer [Result] in domain / use-case layers; use [ApiResult] at the
/// data / API boundary.
sealed class ApiResult<T> {
  const ApiResult();

  factory ApiResult.ok(T data) = ApiResultOk<T>;
  factory ApiResult.err(String message, {int? statusCode}) =
      ApiResultErr<T>;

  bool get isOk => this is ApiResultOk<T>;
  bool get isErr => this is ApiResultErr<T>;

  R when<R>({
    required R Function(T data) ok,
    required R Function(String message, int? statusCode) err,
  }) {
    return switch (this) {
      ApiResultOk<T>(:final data) => ok(data),
      ApiResultErr<T>(:final message, :final statusCode) =>
        err(message, statusCode),
    };
  }
}

final class ApiResultOk<T> extends ApiResult<T> {
  const ApiResultOk(this.data);
  final T data;
}

final class ApiResultErr<T> extends ApiResult<T> {
  const ApiResultErr(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
}
