/// Xtream-style API path constants.
abstract final class ApiConstants {
  // Panel API actions
  static const String actionGetLiveCategories = 'get_live_categories';
  static const String actionGetLiveStreams = 'get_live_streams';
  static const String actionGetVodCategories = 'get_vod_categories';
  static const String actionGetVodStreams = 'get_vod_streams';
  static const String actionGetSeriesCategories = 'get_series_categories';
  static const String actionGetSeries = 'get_series';
  static const String actionGetSeriesInfo = 'get_series_info';
  static const String actionGetVodInfo = 'get_vod_info';
  static const String actionGetSimpleDataTable = 'get_simple_data_table';
  static const String actionGetShortEpg = 'get_short_epg';

  // Stream URL templates
  static const String liveStreamPath = '/live/{username}/{password}/{streamId}.{format}';
  static const String vodStreamPath = '/movie/{username}/{password}/{streamId}.{format}';
  static const String seriesStreamPath = '/series/{username}/{password}/{streamId}.{format}';

  // Default stream formats
  static const String defaultLiveFormat = 'ts';
  static const String defaultVodFormat = 'mp4';

  // Headers
  static const String userAgentHeader = 'User-Agent';
  static const String defaultUserAgent = 'IPTVSmartersPro/3.1.5.1 (iPad; iOS 16.5; Scale/2.00)';
}

