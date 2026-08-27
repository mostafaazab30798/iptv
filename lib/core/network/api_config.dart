import 'package:iptv/core/constants/app_constants.dart';

/// Configuration for the API client.
class ApiConfig {
  const ApiConfig({
    required this.baseUrl,
    required this.username,
    required this.password,
    this.connectTimeout = AppConstants.connectTimeout,
    this.receiveTimeout = AppConstants.receiveTimeout,
    this.sendTimeout = AppConstants.sendTimeout,
  });

  final String baseUrl;
  final String username;
  final String password;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final Duration sendTimeout;

  /// Builds the Xtream panel API base URL.
  String get panelUrl => '$baseUrl/player_api.php';

  @override
  String toString() =>
      'ApiConfig(host: ${Uri.parse(baseUrl).host}, user: $username)';
}
