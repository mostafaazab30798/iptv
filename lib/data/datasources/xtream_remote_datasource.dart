import 'package:iptv/core/constants/api_constants.dart';
import 'package:iptv/core/network/api_client.dart';
import 'package:iptv/core/network/url_helpers.dart';

/// Remote datasource communicating with Xtream-compatible IPTV server APIs.
class XtreamRemoteDataSource {
  const XtreamRemoteDataSource(this._client);

  final ApiClient _client;

  /// Validates credentials and fetches account/server info.
  Future<Map<String, dynamic>> authenticate() async {
    final res = await _client.get<Map<String, dynamic>>('player_api.php');
    return res;
  }

  /// Live streams categories.
  Future<List<Map<String, dynamic>>> getLiveCategories() async {
    try {
      final res = await _client.get<List<dynamic>>(
        'player_api.php',
        params: {'action': ApiConstants.actionGetLiveCategories},
      );
      return res.whereType<Map<dynamic, dynamic>>().map(Map<String, dynamic>.from).toList();
    } catch (_) {
      return [];
    }
  }

  /// Live streams per category (or all if categoryId is null).
  Future<List<Map<String, dynamic>>> getLiveStreams({int? categoryId}) async {
    try {
      final params = <String, dynamic>{
        'action': ApiConstants.actionGetLiveStreams,
        if (categoryId != null && categoryId > 0) 'category_id': categoryId.toString(),
      };
      final res = await _client.get<List<dynamic>>(
        'player_api.php',
        params: params,
      );
      return res.whereType<Map<dynamic, dynamic>>().map(Map<String, dynamic>.from).toList();
    } catch (_) {
      return [];
    }
  }

  /// VOD (Movies) categories.
  Future<List<Map<String, dynamic>>> getVodCategories() async {
    try {
      final res = await _client.get<List<dynamic>>(
        'player_api.php',
        params: {'action': ApiConstants.actionGetVodCategories},
      );
      return res.whereType<Map<dynamic, dynamic>>().map(Map<String, dynamic>.from).toList();
    } catch (_) {
      return [];
    }
  }

  /// VOD (Movies) streams per category.
  Future<List<Map<String, dynamic>>> getVodStreams({int? categoryId}) async {
    try {
      final params = <String, dynamic>{
        'action': ApiConstants.actionGetVodStreams,
        if (categoryId != null && categoryId > 0) 'category_id': categoryId.toString(),
      };
      final res = await _client.get<List<dynamic>>(
        'player_api.php',
        params: params,
      );
      return res.whereType<Map<dynamic, dynamic>>().map(Map<String, dynamic>.from).toList();
    } catch (_) {
      return [];
    }
  }

  /// Series categories.
  Future<List<Map<String, dynamic>>> getSeriesCategories() async {
    try {
      final res = await _client.get<List<dynamic>>(
        'player_api.php',
        params: {'action': ApiConstants.actionGetSeriesCategories},
      );
      return res.whereType<Map<dynamic, dynamic>>().map(Map<String, dynamic>.from).toList();
    } catch (_) {
      return [];
    }
  }

  /// Series list per category.
  Future<List<Map<String, dynamic>>> getSeries({int? categoryId}) async {
    try {
      final params = <String, dynamic>{
        'action': ApiConstants.actionGetSeries,
        if (categoryId != null && categoryId > 0) 'category_id': categoryId.toString(),
      };
      final res = await _client.get<List<dynamic>>(
        'player_api.php',
        params: params,
      );
      return res.whereType<Map<dynamic, dynamic>>().map(Map<String, dynamic>.from).toList();
    } catch (_) {
      return [];
    }
  }

  /// Current / upcoming EPG rows for a live stream.
  ///
  /// Returns an empty list when the panel has no guide data.
  Future<List<Map<String, dynamic>>> getShortEpg(
    int streamId, {
    int limit = 4,
  }) async {
    try {
      final res = await _client.get<Map<String, dynamic>>(
        'player_api.php',
        params: {
          'action': ApiConstants.actionGetShortEpg,
          'stream_id': streamId.toString(),
          'limit': limit.toString(),
        },
      );
      final listings = res['epg_listings'];
      if (listings is! List) return const [];
      return listings
          .whereType<Map<dynamic, dynamic>>()
          .map(Map<String, dynamic>.from)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// Detailed series metadata including seasons & episodes.
  Future<Map<String, dynamic>> getSeriesInfo(int seriesId) async {
    try {
      final res = await _client.get<Map<String, dynamic>>(
        'player_api.php',
        params: {
          'action': ApiConstants.actionGetSeriesInfo,
          'series_id': seriesId.toString(),
        },
      );
      return res;
    } catch (_) {
      return {};
    }
  }

  /// Helper to build direct playback stream URLs.
  static String buildLiveStreamUrl({
    required String serverUrl,
    required String username,
    required String password,
    required int streamId,
    String extension = 'ts',
  }) {
    final base = UrlHelpers.normalizeServerUrl(serverUrl);
    final raw = '$base/live/$username/$password/$streamId.$extension';
    return UrlHelpers.wrapWebProxy(raw);
  }

  static String buildVodStreamUrl({
    required String serverUrl,
    required String username,
    required String password,
    required int streamId,
    String extension = 'mp4',
  }) {
    final base = UrlHelpers.normalizeServerUrl(serverUrl);
    final raw = '$base/movie/$username/$password/$streamId.$extension';
    return UrlHelpers.wrapWebProxy(raw);
  }

  static String buildSeriesStreamUrl({
    required String serverUrl,
    required String username,
    required String password,
    required int streamId,
    String extension = 'mp4',
  }) {
    final base = UrlHelpers.normalizeServerUrl(serverUrl);
    final raw = '$base/series/$username/$password/$streamId.$extension';
    return UrlHelpers.wrapWebProxy(raw);
  }
}
