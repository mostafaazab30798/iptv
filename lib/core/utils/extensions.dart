import 'package:iptv/core/utils/result.dart';

/// General utility extensions.
extension ResultFutureX<T> on Future<T> {
  /// Converts a throwing future into a [Result<T>].
  Future<Result<T>> toResult([String? defaultErrorMessage]) async {
    try {
      final value = await this;
      return Ok(value);
    } catch (e) {
      return Err(AppResultError(defaultErrorMessage ?? e.toString(), cause: e));
    }
  }
}
