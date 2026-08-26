import 'package:dio/dio.dart';
import 'package:iptv/core/logging/app_logger.dart';

/// Logs request/response details in debug mode.
/// Never logs credentials or full authenticated URLs.
class LoggingInterceptor extends Interceptor {
  const LoggingInterceptor();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    AppLogger.debug(
      'HTTP → ${options.method} ${_sanitizeUrl(options.uri.toString())}',
      feature: 'network',
      operation: 'request',
    );
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    AppLogger.debug(
      'HTTP ← ${response.statusCode} ${_sanitizeUrl(response.requestOptions.uri.toString())}',
      feature: 'network',
      operation: 'response',
      data: {'bytes': response.data.toString().length},
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    AppLogger.warning(
      'HTTP ✗ ${err.response?.statusCode} ${_sanitizeUrl(err.requestOptions.uri.toString())}',
      feature: 'network',
      operation: 'error',
      error: err,
    );
    handler.next(err);
  }

  /// Strips username/password query params from URLs before logging.
  String _sanitizeUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final cleanParams = Map<String, String>.from(uri.queryParameters)
        ..remove('username')
        ..remove('password');
      return uri.replace(queryParameters: cleanParams).toString();
    } catch (_) {
      return '[url redacted]';
    }
  }
}
