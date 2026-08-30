/// Analytics policy: forbidden properties and queue limits.
class AnalyticsPolicy {
  const AnalyticsPolicy._();

  static const maxQueueSize = 200;
  static const maxBatchSize = 50;
  static const flushIntervalSeconds = 30;
  static const heartbeatIntervalSeconds = 120;

  static const forbiddenPropertyKeys = {
    'password',
    'username',
    'server_url',
    'serverUrl',
    'stream_url',
    'streamUrl',
    'playlist',
    'playlist_url',
    'playlistUrl',
    'channel_title',
    'channelTitle',
    'movie_title',
    'movieTitle',
    'series_title',
    'seriesTitle',
    'email',
    'access_token',
    'accessToken',
    'refresh_token',
    'refreshToken',
    'token',
    'query_string',
    'queryString',
  };

  static bool isPropertyAllowed(String key, Object? value) {
    final lower = key.toLowerCase();
    for (final forbidden in forbiddenPropertyKeys) {
      if (lower.contains(forbidden.toLowerCase())) return false;
    }
    if (value is String && _urlLike.hasMatch(value)) return false;
    return true;
  }

  static final _urlLike = RegExp(r'^https?://', caseSensitive: false);
}
