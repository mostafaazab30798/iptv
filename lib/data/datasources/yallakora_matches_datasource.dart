import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:iptv/core/logging/app_logger.dart';
import 'package:iptv/data/models/match_model.dart';
import 'package:iptv/domain/entities/live_fixture.dart';

/// Static JSON datasource that fetches matches scraped from Yallakora.
/// Serves as the primary [LiveScoreSource] implementation.
class YallakoraMatchesDataSource implements LiveScoreSource {
  YallakoraMatchesDataSource({Dio? dio, String? endpointUrl})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
                responseType: ResponseType.json,
                headers: const {
                  'Accept': 'application/json',
                  'User-Agent': 'HOPE-IPTV-App/1.0',
                },
              ),
            ),
        _endpointUrl = endpointUrl ?? defaultEndpointUrl;

  final Dio _dio;
  final String _endpointUrl;

  /// Default production URL for matches.json hosted on Cloudflare Pages / Worker / GitHub.
  static const String defaultEndpointUrl =
      'https://hope-tv.site/matches.json';

  /// Fallback URL (e.g. raw GitHub content)
  static const String fallbackEndpointUrl =
      'https://raw.githubusercontent.com/mostafaazab30798/iptv/main/matches.json';

  static List<LiveFixture>? _cachedFixtures;
  static List<MatchModel>? _cachedModels;
  static DateTime? _cachedAt;
  static const Duration _cacheTtl = Duration(seconds: 60);

  /// Resolves the URL for the current platform (respects web proxy if needed).
  String _resolveUrl(String target) {
    if (!kIsWeb) return target;
    final pageHost = Uri.base.host;
    final isLocal = pageHost == 'localhost' || pageHost == '127.0.0.1';
    if (!isLocal && Uri.base.scheme == 'https') {
      return '${Uri.base.origin}/matches.json';
    }
    return target;
  }

  /// Fetches raw [MatchModel] instances.
  Future<List<MatchModel>> fetchTodayMatches({bool forceRefresh = false}) async {
    final now = DateTime.now();
    if (!forceRefresh &&
        _cachedModels != null &&
        _cachedAt != null &&
        now.difference(_cachedAt!) < _cacheTtl) {
      return _cachedModels!;
    }

    final urlsToTry = <String>[
      _resolveUrl(_endpointUrl),
      fallbackEndpointUrl,
    ];

    for (final url in urlsToTry) {
      try {
        final response = await _dio.get<dynamic>(url);
        final dynamic data = response.data;

        List<dynamic> list = const [];
        if (data is List) {
          list = data;
        } else if (data is Map && data['matches'] is List) {
          list = data['matches'] as List;
        }

        final models = list
            .whereType<Map<dynamic, dynamic>>()
            .map((item) => MatchModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();

        _cachedModels = models;
        _cachedFixtures = models.map((m) => m.toLiveFixture()).toList();
        _cachedAt = now;

        AppLogger.info(
          'Fetched ${models.length} matches from $url',
          feature: 'sports',
        );
        return models;
      } catch (e) {
        AppLogger.warning(
          'Failed fetching matches from $url: $e',
          feature: 'sports',
        );
      }
    }

    // Safe fallback to previous cached data or empty list
    return _cachedModels ?? const [];
  }

  @override
  Future<List<LiveFixture>> fetchLiveBigMatches() async {
    final now = DateTime.now();
    if (_cachedFixtures != null &&
        _cachedAt != null &&
        now.difference(_cachedAt!) < _cacheTtl) {
      return _cachedFixtures!;
    }

    final models = await fetchTodayMatches();
    final fixtures = models.map((m) => m.toLiveFixture()).toList();
    _cachedFixtures = fixtures;
    return fixtures;
  }
}
