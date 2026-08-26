import 'package:dio/dio.dart';
import 'package:iptv/core/network/api_config.dart';
import 'package:iptv/core/constants/api_constants.dart';

/// Attaches Xtream-style auth params to every request.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._config);

  final ApiConfig _config;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Merge credentials into query params for panel API requests only.
    if (options.path.contains('player_api') ||
        options.path.contains('xmltv')) {
      options.queryParameters['username'] = _config.username;
      options.queryParameters['password'] = _config.password;
    }
    options.headers[ApiConstants.userAgentHeader] = ApiConstants.defaultUserAgent;
    handler.next(options);
  }
}
