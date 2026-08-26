import 'package:iptv/core/constants/api_constants.dart';
import 'package:iptv/core/network/api_client.dart';

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

  /// Short EPG for a specific live stream.
  Future<List<Map<String, dynamic>>> getShortEpg(int streamId, {int limit = 10}) async {
    try {
      final res = await _client.get<Map<String, dynamic>>(
        'player_api.php',
        params: {
          'action': ApiConstants.actionGetShortEpgForStream,
          'stream_id': streamId.toString(),
          'limit': limit.toString(),
        },
      );
      final epgList = res['epg_listings'] as List<dynamic>? ?? [];
      return epgList.whereType<Map<dynamic, dynamic>>().map(Map<String, dynamic>.from).toList();
    } catch (_) {
      return [];
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
    final base = serverUrl.endsWith('/') ? serverUrl.substring(0, serverUrl.length - 1) : serverUrl;
    return '$base/live/$username/$password/$streamId.$extension';
  }

  static String buildVodStreamUrl({
    required String serverUrl,
    required String username,
    required String password,
    required int streamId,
    String extension = 'mp4',
  }) {
    final base = serverUrl.endsWith('/') ? serverUrl.substring(0, serverUrl.length - 1) : serverUrl;
    return '$base/movie/$username/$password/$streamId.$extension';
  }

  static String buildSeriesStreamUrl({
    required String serverUrl,
    required String username,
    required String password,
    required int streamId,
    String extension = 'mp4',
  }) {
    final base = serverUrl.endsWith('/') ? serverUrl.substring(0, serverUrl.length - 1) : serverUrl;
    return '$base/series/$username/$password/$streamId.$extension';
  }
}
