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
                connectTimeout: const Duration(seconds: 20),
                receiveTimeout: const Duration(seconds: 20),
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
      'https://matches.hope-tv.site/matches.json';

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
    if (!isLocal && target.contains(pageHost)) {
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

    final normalizedEndpoint = _endpointUrl.replaceAll(RegExp(r'/+$'), '');
    final urlsToTry = <String>{
      _resolveUrl(_endpointUrl),
      if (!normalizedEndpoint.endsWith('/matches.json'))
        '$normalizedEndpoint/matches.json',
      fallbackEndpointUrl,
    }.toList();

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

        if (models.isNotEmpty) {
          _cachedModels = models;
          _cachedFixtures = null;
          _cachedAt = now;

          AppLogger.info(
            'Fetched ${models.length} matches from $url',
            feature: 'sports',
          );
          return models;
        }

        AppLogger.warning(
          'Received empty or non-match response from $url, trying next candidate...',
          feature: 'sports',
        );
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
  Future<List<LiveFixture>> fetchLiveBigMatches({bool forceRefresh = false}) async {
    final now = DateTime.now();
    if (!forceRefresh &&
        _cachedFixtures != null &&
        _cachedAt != null &&
        now.difference(_cachedAt!) < _cacheTtl) {
      return _cachedFixtures!;
    }

    final models = await fetchTodayMatches(forceRefresh: forceRefresh);
    // Filter to ONLY Barcelona, Real Madrid, and the Premier League Big Six clubs
    final bigMatchFixtures = models
        .map((m) => m.toLiveFixture(now: now))
        .where((fixture) => fixture.teams.isNotEmpty)
        .toList();

    // Sort order:
    // 1. Live Now matches first (real time >= start time or explicit live status)
    // 2. Upcoming matches next (sorted chronologically by scheduled start time)
    // 3. Finished matches last
    bigMatchFixtures.sort((a, b) {
      if (a.isLive && !b.isLive) return -1;
      if (!a.isLive && b.isLive) return 1;
      if (a.isUpcoming && b.isFinished) return -1;
      if (a.isFinished && b.isUpcoming) return 1;
      return (a.scheduledTime ?? '').compareTo(b.scheduledTime ?? '');
    });

    _cachedFixtures = bigMatchFixtures;
    return bigMatchFixtures;
  }
}
