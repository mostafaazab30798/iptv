import 'package:iptv/core/errors/app_error.dart';

/// Exception thrown by [ApiClient] — always wraps an [AppError].
class ApiException implements Exception {
  const ApiException(this.error);

  final AppError error;

  @override
  String toString() => 'ApiException(${error.message})';
}
