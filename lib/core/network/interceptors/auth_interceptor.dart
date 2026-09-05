import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:iptv/core/network/api_config.dart';
import 'package:iptv/core/constants/api_constants.dart';
import 'package:iptv/core/network/url_helpers.dart';

/// Attaches Xtream-style auth params to every request.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._config);

  final ApiConfig _config;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Merge credentials into query params for panel API requests only.
    if (options.path.contains('player_api')) {
      options.queryParameters['username'] = _config.username;
      options.queryParameters['password'] = _config.password;
    }
    if (!kIsWeb) {
      options.headers[ApiConstants.userAgentHeader] =
          ApiConstants.defaultUserAgent;
    } else {
      options.headers.remove('User-Agent');
      options.headers.remove('user-agent');
      options.headers.remove('Referer');
      options.headers.remove('referer');

      // On Web: when deployed to HTTPS (like Cloudflare), proxy HTTP requests to avoid Mixed Content blocks.
      final isLocal = UrlHelpers.isLocalHost();
      final isHttpsOrigin = Uri.base.scheme == 'https';
      final isTargetHttp = options.uri.scheme == 'http';

      if (!isLocal && isHttpsOrigin && isTargetHttp) {
        final targetUrl = options.uri.toString();
        options.extra['original_target_url'] = targetUrl;
        final proxyUri = Uri.parse(UrlHelpers.proxyBaseUrl);
        options.baseUrl = '${proxyUri.scheme}://${proxyUri.authority}';
        options.path = proxyUri.path.isNotEmpty ? proxyUri.path : '/proxy';
        options.queryParameters = {'url': targetUrl};
      }
    }
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) async {
    final status = response.statusCode;
    final isProxyFailure = status == 404 ||
        (status != null && status >= 500 && status <= 526);

    if (kIsWeb &&
        isProxyFailure &&
        response.requestOptions.extra.containsKey('original_target_url')) {
      final originalTargetUrl =
          response.requestOptions.extra['original_target_url'] as String?;
      if (originalTargetUrl != null) {
        try {
          final fallbackDio = Dio(
            BaseOptions(
              connectTimeout: response.requestOptions.connectTimeout,
              receiveTimeout: response.requestOptions.receiveTimeout,
              sendTimeout: response.requestOptions.sendTimeout,
              responseType: response.requestOptions.responseType,
              validateStatus: response.requestOptions.validateStatus,
            ),
          );
          final directResponse = await fallbackDio.get<dynamic>(originalTargetUrl);
          return handler.resolve(directResponse);
        } catch (_) {
          // Direct fallback failed, continue with original response
        }
      }
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final status = err.response?.statusCode;
    final isProxyFailure = status == 404 ||
        (status != null && status >= 500 && status <= 526) ||
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError;

    if (kIsWeb &&
        isProxyFailure &&
        err.requestOptions.extra.containsKey('original_target_url')) {
      final originalTargetUrl =
          err.requestOptions.extra['original_target_url'] as String?;
      if (originalTargetUrl != null) {
        try {
          final fallbackDio = Dio(
            BaseOptions(
              connectTimeout: err.requestOptions.connectTimeout,
              receiveTimeout: err.requestOptions.receiveTimeout,
              sendTimeout: err.requestOptions.sendTimeout,
              responseType: err.requestOptions.responseType,
              validateStatus: err.requestOptions.validateStatus,
            ),
          );
          final directResponse = await fallbackDio.get<dynamic>(originalTargetUrl);
          return handler.resolve(directResponse);
        } catch (_) {
          // Fall through to error handler
        }
      }
    }
    handler.next(err);
  }
}
