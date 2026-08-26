import 'package:flutter/foundation.dart' show kIsWeb;
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

  /// Full stream URL for a live channel.
  String liveStreamUrl(int streamId, {String format = 'ts'}) =>
      _wrapWebUrl('$baseUrl/live/$username/$password/$streamId.$format');

  /// Full stream URL for a VOD item.
  String vodStreamUrl(int streamId, {String format = 'mp4'}) =>
      _wrapWebUrl('$baseUrl/movie/$username/$password/$streamId.$format');

  /// Full stream URL for a series episode.
  String seriesStreamUrl(int streamId, {String format = 'mkv'}) =>
      _wrapWebUrl('$baseUrl/series/$username/$password/$streamId.$format');

  /// XMLTV EPG URL.
  String get xmltvUrl => '$baseUrl/xmltv.php?username=$username&password=$password';

  static String _wrapWebUrl(String rawUrl) {
    if (!kIsWeb) return rawUrl;
    final isLocalhost =
        Uri.base.host == 'localhost' || Uri.base.host == '127.0.0.1';
    if (!isLocalhost &&
        (Uri.base.scheme == 'https' || rawUrl.startsWith('http://'))) {
      return '${Uri.base.origin}/proxy?url=${Uri.encodeComponent(rawUrl)}';
    }
    return rawUrl;
  }

  @override
  String toString() =>
      'ApiConfig(host: ${Uri.parse(baseUrl).host}, user: $username)';
}
