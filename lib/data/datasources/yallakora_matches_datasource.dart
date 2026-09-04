import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:iptv/core/logging/app_logger.dart';
import 'package:iptv/data/datasources/fotmob_realtime_datasource.dart';
import 'package:iptv/data/models/match_model.dart';
import 'package:iptv/domain/entities/live_fixture.dart';

/// Static JSON datasource that fetches matches scraped from Yallakora.
/// Serves as the primary [LiveScoreSource] implementation, enriched with
/// real-time scores, clock, HT, FT, ET, and penalties from FotMob.
class YallakoraMatchesDataSource implements LiveScoreSource {
  YallakoraMatchesDataSource({
    Dio? dio,
    String? endpointUrl,
    FotmobRealtimeDataSource? fotmobDataSource,
  })  : _dio = dio ??
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
        _endpointUrl = endpointUrl ?? defaultEndpointUrl,
        _fotmob = fotmobDataSource ?? FotmobRealtimeDataSource();

  final Dio _dio;
  final String _endpointUrl;
  final FotmobRealtimeDataSource _fotmob;

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

        var models = list
            .whereType<Map<dynamic, dynamic>>()
            .map((item) => MatchModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();

        if (models.isNotEmpty) {
          // Enrich with FotMob real-time scores, clock, HT, FT, ET, penalties
          try {
            final targetTeams = models
                .expand((m) => [m.teamHome, m.teamAway])
                .where((t) => t.trim().isNotEmpty)
                .toSet();
            final fotmobMatches = await _fotmob.fetchMatches(
              forceRefresh: forceRefresh,
              targetTeams: targetTeams,
            );
            if (fotmobMatches.isNotEmpty) {
              models = await Future.wait(
                models.map((m) async {
                  final fm = _fotmob.findMatchFor(
                    fotmobMatches: fotmobMatches,
                    homeName: m.teamHome,
                    awayName: m.teamAway,
                  );
                  if (fm == null) return m;

                  List<MatchGoal> homeGoals = m.homeGoals;
                  List<MatchGoal> awayGoals = m.awayGoals;
                  final hasGoals = (fm.homeScore != null && fm.homeScore! > 0) ||
                      (fm.awayScore != null && fm.awayScore! > 0);
                  if (hasGoals && fm.id > 0) {
                    try {
                      final goals = await _fotmob.fetchMatchGoals(
                        fm.id,
                        forceRefresh: forceRefresh,
                      );
                      homeGoals = goals.homeGoals;
                      awayGoals = goals.awayGoals;
                    } catch (_) {}
                  }

                  return m.copyWith(
                    scoreHome: fm.homeScore != null
                        ? fm.homeScore.toString()
                        : m.scoreHome,
                    scoreAway: fm.awayScore != null
                        ? fm.awayScore.toString()
                        : m.scoreAway,
                    homePenScore: fm.homePenScore,
                    awayPenScore: fm.awayPenScore,
                    status: fm.resolveClock(fallbackTime: m.time),
                    homeGoals: homeGoals,
                    awayGoals: awayGoals,
                  );
                }),
              );
            }
          } catch (_) {
            // Silently fall back to raw matches.json data on any network or parsing error
          }

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
          'Matches fetch candidate failed ($url): $e',
          feature: 'sports',
        );
      }
    }

    AppLogger.error(
      'All matches sources failed. Falling back to empty or stale cache.',
      feature: 'sports',
    );
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

    final allMatches = await fetchTodayMatches(forceRefresh: forceRefresh);
    var bigMatchFixtures = allMatches
        .map((m) => m.toLiveFixture(now: now))
        .where((fixture) => fixture.teams.isNotEmpty)
        .toList();

    // Enrich filtered big matches with FotMob real-time data
    try {
      final targetTeams = bigMatchFixtures
          .expand((f) => [f.homeName, f.awayName, ...f.teams.map((t) => t.toString())])
          .where((t) => t.trim().isNotEmpty)
          .toSet();
      final fotmobMatches = await _fotmob.fetchMatches(
        forceRefresh: forceRefresh,
        targetTeams: targetTeams,
      );
      if (fotmobMatches.isNotEmpty) {
        bigMatchFixtures = await Future.wait(
          bigMatchFixtures.map((fixture) async {
            final fm = _fotmob.findMatchFor(
              fotmobMatches: fotmobMatches,
              homeName: fixture.homeName,
              awayName: fixture.awayName,
              teams: fixture.teams,
            );
            if (fm == null) return fixture;

            final homeScore = fm.homeScore != null
                ? fm.homeScore.toString()
                : fixture.homeScore;
            final awayScore = fm.awayScore != null
                ? fm.awayScore.toString()
                : fixture.awayScore;
            final clock = fm.resolveClock(fallbackTime: fixture.scheduledTime);
            final state = fm.state;

            List<MatchGoal> homeGoals = fixture.homeGoals;
            List<MatchGoal> awayGoals = fixture.awayGoals;

            final hasGoals = (fm.homeScore != null && fm.homeScore! > 0) ||
                (fm.awayScore != null && fm.awayScore! > 0);
            if (hasGoals && fm.id > 0) {
              try {
                final goals = await _fotmob.fetchMatchGoals(
                  fm.id,
                  forceRefresh: forceRefresh,
                );
                homeGoals = goals.homeGoals;
                awayGoals = goals.awayGoals;
              } catch (_) {}
            }

            return fixture.copyWith(
              homeScore: homeScore,
              awayScore: awayScore,
              homePenScore: fm.homePenScore,
              awayPenScore: fm.awayPenScore,
              clock: clock,
              state: state,
              rawStatus: fm.scoreStr ?? fm.reasonLong ?? fixture.rawStatus,
              homeGoals: homeGoals,
              awayGoals: awayGoals,
            );
          }),
        );
      }
    } catch (e) {
      AppLogger.warning(
        'Failed to enrich big matches with FotMob: $e',
        feature: 'sports',
      );
    }

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
