import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:iptv/core/logging/app_logger.dart';
import 'package:iptv/core/sports/big_match_detector.dart';
import 'package:iptv/core/sports/sports_localization.dart';
import 'package:iptv/domain/entities/live_fixture.dart';

/// Representation of a match parsed from FotMob's real-time API.
class FotmobMatchItem {
  const FotmobMatchItem({
    required this.id,
    required this.homeName,
    required this.homeLongName,
    required this.awayName,
    required this.awayLongName,
    this.homeScore,
    this.awayScore,
    this.homePenScore,
    this.awayPenScore,
    this.started = false,
    this.ongoing = false,
    this.finished = false,
    this.cancelled = false,
    this.liveTimeShort,
    this.liveTimeLong,
    this.reasonShort,
    this.reasonLong,
    this.scoreStr,
    this.time,
    this.homeGoals = const [],
    this.awayGoals = const [],
  });

  final int id;
  final String homeName;
  final String homeLongName;
  final String awayName;
  final String awayLongName;
  final int? homeScore;
  final int? awayScore;
  final int? homePenScore;
  final int? awayPenScore;
  final bool started;
  final bool ongoing;
  final bool finished;
  final bool cancelled;
  final String? liveTimeShort;
  final String? liveTimeLong;
  final String? reasonShort;
  final String? reasonLong;
  final String? scoreStr;
  final String? time;
  final List<MatchGoal> homeGoals;
  final List<MatchGoal> awayGoals;

  /// Whether match is currently in progress.
  bool get isLive => ongoing;

  /// Normalized match state: 'in' (live), 'post' (finished), 'pre' (upcoming).
  String get state {
    if (finished) return 'post';
    if (ongoing) return 'in';
    return 'pre';
  }

  /// Clean, localized or standard clock / status label:
  /// Examples: "79'", "HT", "FT", "AET", "Pen (4-3)"
  String resolveClock({String? fallbackTime}) {
    if (finished) {
      if (reasonShort == 'Pen' || (homePenScore != null && awayPenScore != null)) {
        if (homePenScore != null && awayPenScore != null) {
          return 'Pen ($homePenScore-$awayPenScore)';
        }
        return 'Pen';
      }
      if (reasonShort == 'AET') {
        return 'AET';
      }
      return 'FT';
    }

    if (ongoing) {
      final lt = liveTimeShort?.replaceAll('\u200e', '').trim();
      if (lt != null && lt.isNotEmpty) {
        if (lt.toUpperCase() == 'HT' ||
            (liveTimeLong != null &&
                liveTimeLong!.toLowerCase().contains('half-time'))) {
          return 'HT';
        }
        return lt;
      }
      return 'LIVE';
    }

    return fallbackTime ?? time ?? '';
  }

  FotmobMatchItem copyWith({
    int? id,
    String? homeName,
    String? homeLongName,
    String? awayName,
    String? awayLongName,
    int? homeScore,
    int? awayScore,
    int? homePenScore,
    int? awayPenScore,
    bool? started,
    bool? ongoing,
    bool? finished,
    bool? cancelled,
    String? liveTimeShort,
    String? liveTimeLong,
    String? reasonShort,
    String? reasonLong,
    String? scoreStr,
    String? time,
    List<MatchGoal>? homeGoals,
    List<MatchGoal>? awayGoals,
  }) {
    return FotmobMatchItem(
      id: id ?? this.id,
      homeName: homeName ?? this.homeName,
      homeLongName: homeLongName ?? this.homeLongName,
      awayName: awayName ?? this.awayName,
      awayLongName: awayLongName ?? this.awayLongName,
      homeScore: homeScore ?? this.homeScore,
      awayScore: awayScore ?? this.awayScore,
      homePenScore: homePenScore ?? this.homePenScore,
      awayPenScore: awayPenScore ?? this.awayPenScore,
      started: started ?? this.started,
      ongoing: ongoing ?? this.ongoing,
      finished: finished ?? this.finished,
      cancelled: cancelled ?? this.cancelled,
      liveTimeShort: liveTimeShort ?? this.liveTimeShort,
      liveTimeLong: liveTimeLong ?? this.liveTimeLong,
      reasonShort: reasonShort ?? this.reasonShort,
      reasonLong: reasonLong ?? this.reasonLong,
      scoreStr: scoreStr ?? this.scoreStr,
      time: time ?? this.time,
      homeGoals: homeGoals ?? this.homeGoals,
      awayGoals: awayGoals ?? this.awayGoals,
    );
  }

  factory FotmobMatchItem.fromJson(Map<String, dynamic> json) {
    final home = json['home'] as Map<String, dynamic>? ?? const {};
    final away = json['away'] as Map<String, dynamic>? ?? const {};
    final status = json['status'] as Map<String, dynamic>? ?? const {};
    final liveTime = status['liveTime'] as Map<String, dynamic>?;
    final reason = status['reason'] as Map<String, dynamic>?;

    final homeScore = home['score'] is num ? (home['score'] as num).toInt() : null;
    final awayScore = away['score'] is num ? (away['score'] as num).toInt() : null;
    final homePen = home['penScore'] is num ? (home['penScore'] as num).toInt() : null;
    final awayPen = away['penScore'] is num ? (away['penScore'] as num).toInt() : null;

    final started = status['started'] == true;
    final ongoing = status['ongoing'] == true;
    final finished = status['finished'] == true;
    final cancelled = status['cancelled'] == true;

    final ltShort = liveTime?['short']?.toString();
    final ltLong = liveTime?['long']?.toString();
    final rShort = reason?['short']?.toString();
    final rLong = reason?['long']?.toString();
    final scoreStr = status['scoreStr']?.toString();

    return FotmobMatchItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      homeName: home['name']?.toString().trim() ?? '',
      homeLongName: home['longName']?.toString().trim() ?? '',
      awayName: away['name']?.toString().trim() ?? '',
      awayLongName: away['longName']?.toString().trim() ?? '',
      homeScore: homeScore,
      awayScore: awayScore,
      homePenScore: homePen,
      awayPenScore: awayPen,
      started: started,
      ongoing: ongoing,
      finished: finished,
      cancelled: cancelled,
      liveTimeShort: ltShort,
      liveTimeLong: ltLong,
      reasonShort: rShort,
      reasonLong: rLong,
      scoreStr: scoreStr,
      time: json['time']?.toString(),
    );
  }
}

/// Datasource that interacts directly with FotMob API to retrieve real-time
/// match scores, clock, half-time, extra-time, and penalty shootouts.
class FotmobRealtimeDataSource {
  FotmobRealtimeDataSource({
    Dio? dio,
    String? primaryEndpoint,
    String? proxyEndpoint,
    Duration cacheTtl = const Duration(seconds: 30),
  })  : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 12),
                receiveTimeout: const Duration(seconds: 12),
                responseType: ResponseType.json,
                headers: const {
                  'User-Agent':
                      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
                  'Accept': 'application/json, text/plain, */*',
                  'Referer': 'https://www.fotmob.com/',
                },
              ),
            ),
        _primaryEndpoint = primaryEndpoint ?? defaultPrimaryEndpoint,
        _proxyEndpoint = proxyEndpoint ?? defaultProxyEndpoint,
        _cacheTtl = cacheTtl;

  final Dio _dio;
  final String _primaryEndpoint;
  final String _proxyEndpoint;
  final Duration _cacheTtl;

  static const String defaultPrimaryEndpoint =
      'https://www.fotmob.com/api/data/matches';
  static const String defaultProxyEndpoint =
      'https://matches.hope-tv.site/fotmob/matches';
  static const String defaultMatchDetailsEndpoint =
      'https://www.fotmob.com/api/data/matchDetails';
  static const String defaultProxyMatchDetailsEndpoint =
      'https://matches.hope-tv.site/fotmob/matchDetails';

  static final Map<String, List<FotmobMatchItem>> _cachedMatchesByDate = {};
  static final Map<String, DateTime> _cachedAtByDate = {};
  static final Map<int, ({List<MatchGoal> homeGoals, List<MatchGoal> awayGoals})>
      _cachedGoalsByMatchId = {};
  static final Map<int, DateTime> _cachedGoalsAtByMatchId = {};

  /// Clears in-memory match and goal cache (useful for testing and manual resets).
  static void clearCache() {
    _cachedMatchesByDate.clear();
    _cachedAtByDate.clear();
    _cachedGoalsByMatchId.clear();
    _cachedGoalsAtByMatchId.clear();
  }

  static String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y$m$d';
  }

  /// Fetches goal events (scorers, minutes, penalties, own goals) for [matchId].
  Future<({List<MatchGoal> homeGoals, List<MatchGoal> awayGoals})> fetchMatchGoals(
    int matchId, {
    bool forceRefresh = false,
  }) async {
    if (matchId <= 0) {
      return (homeGoals: const <MatchGoal>[], awayGoals: const <MatchGoal>[]);
    }

    final now = DateTime.now();
    if (!forceRefresh) {
      final cached = _cachedGoalsByMatchId[matchId];
      final cachedAt = _cachedGoalsAtByMatchId[matchId];
      if (cached != null &&
          cachedAt != null &&
          now.difference(cachedAt) < _cacheTtl) {
        return cached;
      }
    }

    final endpointsToTry = kIsWeb
        ? [defaultProxyMatchDetailsEndpoint, defaultMatchDetailsEndpoint]
        : [defaultMatchDetailsEndpoint, defaultProxyMatchDetailsEndpoint];

    for (final base in endpointsToTry) {
      try {
        final url = '$base?matchId=$matchId';
        final response = await _dio.get<dynamic>(url);
        dynamic data = response.data;
        if (data is String) {
          try {
            data = jsonDecode(data);
          } catch (_) {}
        }

        if (data is Map) {
          final header = data['header'] as Map<String, dynamic>?;
          final events = (header?['events'] as Map<String, dynamic>?) ??
              (data['events'] as Map<String, dynamic>?);
          if (events != null) {
            final homeGoals = parseTeamGoals(events['homeTeamGoals']);
            final awayGoals = parseTeamGoals(events['awayTeamGoals']);
            final result = (homeGoals: homeGoals, awayGoals: awayGoals);
            _cachedGoalsByMatchId[matchId] = result;
            _cachedGoalsAtByMatchId[matchId] = now;
            AppLogger.info(
              'Fetched goals for match $matchId (${homeGoals.length} - ${awayGoals.length})',
              feature: 'sports',
            );
            return result;
          }
        }
      } catch (e) {
        AppLogger.warning(
          'FotMob matchDetails fetch failed ($base): $e',
          feature: 'sports',
        );
      }
    }

    return _cachedGoalsByMatchId[matchId] ??
        (homeGoals: const <MatchGoal>[], awayGoals: const <MatchGoal>[]);
  }

  /// Parses FotMob goal events map into a sorted list of [MatchGoal].
  static List<MatchGoal> parseTeamGoals(dynamic rawGoals) {
    if (rawGoals is! Map) return const [];
    final result = <MatchGoal>[];

    for (final entry in rawGoals.entries) {
      final events = entry.value;
      if (events is List) {
        for (final ev in events) {
          if (ev is Map) {
            if (ev['isPenaltyShootoutEvent'] == true) continue;

            final playerObj = ev['player'];
            final playerObjName =
                playerObj is Map ? playerObj['name']?.toString().trim() : null;
            final player = ev['nameStr']?.toString().trim() ??
                playerObjName ??
                ev['fullName']?.toString().trim() ??
                entry.key.toString().trim();

            final timeRaw = ev['timeStr'] ?? ev['time'];
            final minute = timeRaw != null ? "$timeRaw'" : '';
            final shotmap = ev['shotmapEvent'];
            final isShotmapOwn =
                shotmap is Map && shotmap['isOwnGoal'] == true;
            final isOwn = ev['ownGoal'] == true || isShotmapOwn;
            final isPen = ev['suffix']?.toString().toUpperCase() == 'P' ||
                ev['suffixKey']?.toString().toLowerCase() == 'penalty';

            if (player.isNotEmpty) {
              result.add(
                MatchGoal(
                  player: player,
                  minute: minute,
                  isOwnGoal: isOwn,
                  isPenalty: isPen,
                ),
              );
            }
          }
        }
      }
    }

    result.sort((a, b) {
      final minA =
          int.tryParse(a.minute.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      final minB =
          int.tryParse(b.minute.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      return minA.compareTo(minB);
    });

    return result;
  }

  /// Fetches matches for a specific date string with caching.
  Future<List<FotmobMatchItem>> _fetchMatchesForSingleDate(
    DateTime targetDate, {
    bool forceRefresh = false,
    Iterable<String>? targetTeams,
  }) async {
    final dateKey = _formatDate(targetDate);
    final targetsKey = (targetTeams != null && targetTeams.isNotEmpty)
        ? ':${(targetTeams.map((t) => t.trim().toLowerCase()).toList()..sort()).join(',')}'
        : '';
    final cacheKey = '$dateKey$targetsKey';
    final now = DateTime.now();

    if (!forceRefresh) {
      final cached = _cachedMatchesByDate[cacheKey];
      final cachedAt = _cachedAtByDate[cacheKey];
      if (cached != null &&
          cachedAt != null &&
          now.difference(cachedAt) < _cacheTtl) {
        return cached;
      }
    }

    // Always prioritize the Cloudflare Worker proxy which provides edge caching & filtering
    final endpointsToTry = [_proxyEndpoint, _primaryEndpoint];

    final queryParams = <String>['date=$dateKey'];
    if (targetTeams != null && targetTeams.isNotEmpty) {
      final encodedTeams = targetTeams
          .map((t) => Uri.encodeComponent(
                SportsLocalization.localizeTeam(t, isArabic: false),
              ))
          .toSet()
          .join(',');
      if (encodedTeams.isNotEmpty) {
        queryParams.add('teams=$encodedTeams');
      }
    }

    for (final base in endpointsToTry) {
      try {
        final separator = base.contains('?') ? '&' : '?';
        final url = '$base$separator${queryParams.join('&')}';
        final response = await _dio.get<dynamic>(url);
        dynamic data = response.data;
        if (data is String) {
          try {
            data = jsonDecode(data);
          } catch (_) {}
        }

        if (data is Map) {
          final leagues = data['leagues'] as List? ?? const [];
          final items = <FotmobMatchItem>[];
          for (final l in leagues) {
            if (l is Map && l['matches'] is List) {
              for (final m in l['matches'] as List) {
                if (m is Map) {
                  // If target teams are specified, only parse matching games
                  if (targetTeams != null && targetTeams.isNotEmpty) {
                    if (!_matchesAnyTarget(m, targetTeams)) continue;
                  }
                  try {
                    items.add(
                      FotmobMatchItem.fromJson(Map<String, dynamic>.from(m)),
                    );
                  } catch (e) {
                    // Ignore single malformed match item
                  }
                }
              }
            }
          }

          if (items.isNotEmpty) {
            _cachedMatchesByDate[cacheKey] = items;
            _cachedAtByDate[cacheKey] = now;
            AppLogger.info(
              'Fetched ${items.length} real-time matches from FotMob ($url)',
              feature: 'sports',
            );
            return items;
          }
        }
      } catch (e) {
        AppLogger.warning(
          'FotMob fetch candidate failed ($base): $e',
          feature: 'sports',
        );
      }
    }

    return _cachedMatchesByDate[cacheKey] ?? const [];
  }

  /// Checks whether a raw FotMob match JSON object involves any of the target teams.
  static bool _matchesAnyTarget(Map<dynamic, dynamic> m, Iterable<String> targetTeams) {
    final home = m['home'] as Map?;
    final away = m['away'] as Map?;
    final hName =
        '${home?['name'] ?? ''} ${home?['longName'] ?? ''}'.toLowerCase();
    final aName =
        '${away?['name'] ?? ''} ${away?['longName'] ?? ''}'.toLowerCase();

    for (final target in targetTeams) {
      final tNorm = BigMatchDetector.normalize(target);
      final tEnNorm = BigMatchDetector.normalize(
        SportsLocalization.localizeTeam(target, isArabic: false),
      );

      if (tNorm.isNotEmpty &&
          (hName.contains(tNorm) || aName.contains(tNorm))) {
        return true;
      }
      if (tEnNorm.isNotEmpty &&
          (hName.contains(tEnNorm) || aName.contains(tEnNorm))) {
        return true;
      }
    }
    return false;
  }

  /// Fetches all matches for [date] (defaults to today) with memory caching.
  /// If [targetTeams] is provided, only matches involving those teams are fetched
  /// and parsed, saving bandwidth and CPU cycles.
  Future<List<FotmobMatchItem>> fetchMatches({
    DateTime? date,
    bool forceRefresh = false,
    Iterable<String>? targetTeams,
  }) async {
    final targetDate = date ?? DateTime.now();
    final primary = await _fetchMatchesForSingleDate(
      targetDate,
      forceRefresh: forceRefresh,
      targetTeams: targetTeams,
    );

    // If date wasn't explicitly pinned and it's before noon,
    // also fetch yesterday's matches to capture late-night / finished evening matches.
    if (date == null && targetDate.hour < 12) {
      final yesterday = targetDate.subtract(const Duration(days: 1));
      final yesterdayMatches = await _fetchMatchesForSingleDate(
        yesterday,
        forceRefresh: forceRefresh,
        targetTeams: targetTeams,
      );

      if (yesterdayMatches.isNotEmpty) {
        final merged = <int, FotmobMatchItem>{};
        for (final m in yesterdayMatches) {
          merged[m.id] = m;
        }
        for (final m in primary) {
          merged[m.id] = m;
        }
        return merged.values.toList();
      }
    }

    return primary;
  }

  /// Finds the best matching FotMob match item for a given fixture.
  /// Uses English & Arabic name localization, BigMatchDetector normalization,
  /// and nickname matching.
  FotmobMatchItem? findMatchFor({
    required List<FotmobMatchItem> fotmobMatches,
    required String homeName,
    required String awayName,
    List<BigTeam>? teams,
  }) {
    if (fotmobMatches.isEmpty) return null;

    final homeEn = SportsLocalization.localizeTeam(homeName, isArabic: false).toLowerCase();
    final awayEn = SportsLocalization.localizeTeam(awayName, isArabic: false).toLowerCase();
    final homeNorm = BigMatchDetector.normalize(homeEn);
    final awayNorm = BigMatchDetector.normalize(awayEn);

    final bigTeamsHome = teams?.where((t) => t.matchesNormalized(BigMatchDetector.normalize(homeName))).toList() ??
        BigMatchDetector.teamsIn(homeName);
    final bigTeamsAway = teams?.where((t) => t.matchesNormalized(BigMatchDetector.normalize(awayName))).toList() ??
        BigMatchDetector.teamsIn(awayName);

    for (final fm in fotmobMatches) {
      final fmHomeRaw = '${fm.homeName} ${fm.homeLongName}'.toLowerCase();
      final fmAwayRaw = '${fm.awayName} ${fm.awayLongName}'.toLowerCase();
      final fmHomeNorm = BigMatchDetector.normalize(fmHomeRaw);
      final fmAwayNorm = BigMatchDetector.normalize(fmAwayRaw);

      bool homeMatch = homeNorm.isNotEmpty &&
          (fmHomeNorm.contains(homeNorm) || homeNorm.contains(fmHomeNorm));
      bool awayMatch = awayNorm.isNotEmpty &&
          (fmAwayNorm.contains(awayNorm) || awayNorm.contains(fmAwayNorm));

      if (!homeMatch && bigTeamsHome.isNotEmpty) {
        homeMatch = bigTeamsHome.any((t) => t.matchesNormalized(fmHomeNorm));
      }
      if (!awayMatch && bigTeamsAway.isNotEmpty) {
        awayMatch = bigTeamsAway.any((t) => t.matchesNormalized(fmAwayNorm));
      }

      // Exact match for both teams
      if (homeMatch && awayMatch) {
        return fm;
      }

      // Check inverted/swapped home and away
      bool flippedHome = homeNorm.isNotEmpty &&
          (fmAwayNorm.contains(homeNorm) || homeNorm.contains(fmAwayNorm));
      bool flippedAway = awayNorm.isNotEmpty &&
          (fmHomeNorm.contains(awayNorm) || awayNorm.contains(fmHomeNorm));
      if (!flippedHome && bigTeamsHome.isNotEmpty) {
        flippedHome = bigTeamsHome.any((t) => t.matchesNormalized(fmAwayNorm));
      }
      if (!flippedAway && bigTeamsAway.isNotEmpty) {
        flippedAway = bigTeamsAway.any((t) => t.matchesNormalized(fmHomeNorm));
      }

      if (flippedHome && flippedAway) {
        return fm;
      }
    }

    // Secondary pass: if one team is a recognized BigTeam and matched
    for (final fm in fotmobMatches) {
      final fmHomeNorm = BigMatchDetector.normalize('${fm.homeName} ${fm.homeLongName}'.toLowerCase());
      final fmAwayNorm = BigMatchDetector.normalize('${fm.awayName} ${fm.awayLongName}'.toLowerCase());

      final bigHomeHit = bigTeamsHome.isNotEmpty &&
          (bigTeamsHome.any((t) => t.matchesNormalized(fmHomeNorm)) ||
              bigTeamsHome.any((t) => t.matchesNormalized(fmAwayNorm)));
      final bigAwayHit = bigTeamsAway.isNotEmpty &&
          (bigTeamsAway.any((t) => t.matchesNormalized(fmHomeNorm)) ||
              bigTeamsAway.any((t) => t.matchesNormalized(fmAwayNorm)));

      if (bigHomeHit || bigAwayHit) {
        return fm;
      }
    }

    return null;
  }
}
