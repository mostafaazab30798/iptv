import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:iptv/core/network/api_config.dart';
import 'package:iptv/core/constants/api_constants.dart';

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
      // On Web: when deployed to HTTPS (like Cloudflare), proxy HTTP requests to avoid Mixed Content / CORS blocks.
      final isLocalhost =
          Uri.base.host == 'localhost' || Uri.base.host == '127.0.0.1';
      final isHttpsOrigin = Uri.base.scheme == 'https';
      final isTargetHttp = options.uri.scheme == 'http';

      if (!isLocalhost && (isHttpsOrigin || isTargetHttp)) {
        final targetUrl = options.uri.toString();
        options.baseUrl = Uri.base.origin;
        options.path = '/proxy';
        options.queryParameters = {'url': targetUrl};
      }
    }
    handler.next(options);
  }
}
