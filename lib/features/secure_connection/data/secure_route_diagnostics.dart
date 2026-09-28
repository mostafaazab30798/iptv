import 'dart:async';

import 'package:dio/dio.dart';

/// Verifies that the exact endpoint which failed is reachable again.
abstract interface class SecureRouteDiagnostics {
  Future<bool> endpointReachable(
    Uri endpoint, {
    Map<String, String> headers = const {},
  });
}

/// Lightweight route verification that stops after response headers arrive.
final class DioSecureRouteDiagnostics implements SecureRouteDiagnostics {
  DioSecureRouteDiagnostics({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 4),
              receiveTimeout: const Duration(seconds: 5),
              followRedirects: true,
              maxRedirects: 5,
              responseType: ResponseType.stream,
              validateStatus: (status) =>
                  status != null && status >= 200 && status < 400,
            ),
          );

  final Dio _dio;

  @override
  Future<bool> endpointReachable(
    Uri endpoint, {
    Map<String, String> headers = const {},
  }) async {
    try {
      final response = await _dio.get<ResponseBody>(
        endpoint.toString(),
        options: Options(
          headers: {...headers, 'Range': 'bytes=0-0'},
          responseType: ResponseType.stream,
        ),
      );
      final body = response.data;
      if (body != null) {
        final subscription = body.stream.listen((_) {});
        await subscription.cancel();
      }
      final status = response.statusCode;
      return status != null && status >= 200 && status < 400;
    } on DioException {
      return false;
    } on TimeoutException {
      return false;
    }
  }
}
