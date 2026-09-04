import 'package:iptv/core/sports/big_match_detector.dart';
import 'package:iptv/domain/entities/live_fixture.dart';

/// Representation of a football match scraped from Yallakora.
class MatchModel {
  const MatchModel({
    required this.league,
    required this.teamHome,
    required this.teamAway,
    this.logoHome,
    this.logoAway,
    this.scoreHome,
    this.scoreAway,
    required this.time,
    this.status = '',
    required this.channel,
    this.homePenScore,
    this.awayPenScore,
    this.homeGoals = const [],
    this.awayGoals = const [],
  });

  final String league;
  final String teamHome;
  final String teamAway;
  final String? logoHome;
  final String? logoAway;
  final String? scoreHome;
  final String? scoreAway;
  final String time;
  final String status;
  final String channel;
  final int? homePenScore;
  final int? awayPenScore;
  final List<MatchGoal> homeGoals;
  final List<MatchGoal> awayGoals;

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    return MatchModel(
      league: json['league']?.toString().trim() ?? 'Unknown League',
      teamHome: json['team_home']?.toString().trim() ?? 'Unknown',
      teamAway: json['team_away']?.toString().trim() ?? 'Unknown',
      logoHome: _nullIfEmpty(json['logo_home']?.toString().trim()),
      logoAway: _nullIfEmpty(json['logo_away']?.toString().trim()),
      scoreHome: _nullIfEmpty(json['score_home']?.toString().trim()),
      scoreAway: _nullIfEmpty(json['score_away']?.toString().trim()),
      time: json['time']?.toString().trim() ?? '00:00',
      status: json['status']?.toString().trim() ?? '',
      channel: json['channel']?.toString().trim() ?? 'Not Available',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'league': league,
      'team_home': teamHome,
      'team_away': teamAway,
      'logo_home': logoHome,
      'logo_away': logoAway,
      'score_home': scoreHome,
      'score_away': scoreAway,
      'time': time,
      'status': status,
      'channel': channel,
    };
  }

  /// Resolves the match state ('in', 'pre', 'post') and clock label based on
  /// both the scraped status string and whether the real current time has
  /// reached or exceeded the scheduled kickoff time.
  static ({String state, String? clock}) resolveMatchTiming({
    required String status,
    required String time,
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final lowerStatus = status.toLowerCase().trim();

    // 1. Explicit finished status
    if (lowerStatus.contains('انتهت') ||
        lowerStatus.contains('final') ||
        lowerStatus.contains('ft') ||
        lowerStatus.contains('pen') ||
        lowerStatus.contains('aet')) {
      return (state: 'post', clock: status.isNotEmpty ? status : 'انتهت');
    }

    // 2. Explicit live status from provider
    if (lowerStatus.contains('جار') ||
        lowerStatus.contains('شوط') ||
        lowerStatus.contains('استراح') ||
        lowerStatus.contains('live') ||
        lowerStatus.contains('ht') ||
        lowerStatus.contains('et')) {
      return (state: 'in', clock: status.isNotEmpty ? status : time);
    }

    // 3. Real-time vs scheduled start time check
    final parts = time.trim().split(':');
    if (parts.length >= 2) {
      final hour = int.tryParse(parts[0].trim());
      final minute = int.tryParse(parts[1].trim());
      if (hour != null && minute != null) {
        var matchStartTime = DateTime(
          current.year,
          current.month,
          current.day,
          hour,
          minute,
        );

        // If it's early in the morning (00:00 - 06:00) and the match
        // was scheduled for evening (18:00 - 23:59), the match was kicked
        // off yesterday evening.
        if (current.hour < 6 && hour >= 18) {
          matchStartTime = matchStartTime.subtract(const Duration(days: 1));
        }

        if (current.isAfter(matchStartTime) ||
            current.isAtSameMomentAs(matchStartTime)) {
          final elapsed = current.difference(matchStartTime);
          // Football matches last ~115-130 minutes total (90min + HT + stoppage)
          if (elapsed <= const Duration(minutes: 130)) {
            final elapsedMinutes = elapsed.inMinutes;
            final minuteLabel =
                elapsedMinutes > 0 ? "'+$elapsedMinutes" : 'جارية الآن';
            return (
              state: 'in',
              clock: (status.isNotEmpty && status != 'لم تبدأ')
                  ? status
                  : minuteLabel,
            );
          } else {
            return (state: 'post', clock: 'انتهت');
          }
        } else {
          return (state: 'pre', clock: time);
        }
      }
    }

    final isPre = lowerStatus.contains('لم تبدأ') || lowerStatus.isEmpty;
    return (
      state: isPre ? 'pre' : 'in',
      clock: status.isNotEmpty ? status : time,
    );
  }

  MatchModel copyWith({
    String? league,
    String? teamHome,
    String? teamAway,
    String? logoHome,
    String? logoAway,
    String? scoreHome,
    String? scoreAway,
    String? time,
    String? status,
    String? channel,
    int? homePenScore,
    int? awayPenScore,
    List<MatchGoal>? homeGoals,
    List<MatchGoal>? awayGoals,
  }) {
    return MatchModel(
      league: league ?? this.league,
      teamHome: teamHome ?? this.teamHome,
      teamAway: teamAway ?? this.teamAway,
      logoHome: logoHome ?? this.logoHome,
      logoAway: logoAway ?? this.logoAway,
      scoreHome: scoreHome ?? this.scoreHome,
      scoreAway: scoreAway ?? this.scoreAway,
      time: time ?? this.time,
      status: status ?? this.status,
      channel: channel ?? this.channel,
      homePenScore: homePenScore ?? this.homePenScore,
      awayPenScore: awayPenScore ?? this.awayPenScore,
      homeGoals: homeGoals ?? this.homeGoals,
      awayGoals: awayGoals ?? this.awayGoals,
    );
  }

  LiveFixture toLiveFixture({DateTime? now}) {
    final teams = BigMatchDetector.teamsIn('$teamHome $teamAway');
    final timing = resolveMatchTiming(status: status, time: time, now: now);

    final cleanScoreHome =
        (scoreHome != null && scoreHome != '-') ? scoreHome : null;
    final cleanScoreAway =
        (scoreAway != null && scoreAway != '-') ? scoreAway : null;
    final cleanChannel =
        (channel.isNotEmpty && channel != 'Not Available') ? channel : null;

    return LiveFixture(
      homeName: teamHome,
      awayName: teamAway,
      teams: teams,
      state: timing.state,
      clock: timing.clock,
      league: league,
      homeScore: cleanScoreHome,
      awayScore: cleanScoreAway,
      homeLogoUrl: logoHome,
      awayLogoUrl: logoAway,
      broadcastChannel: cleanChannel,
      scheduledTime: time,
      rawStatus: status,
      homePenScore: homePenScore,
      awayPenScore: awayPenScore,
      homeGoals: homeGoals,
      awayGoals: awayGoals,
    );
  }

  static String? _nullIfEmpty(String? val) {
    if (val == null || val.isEmpty) return null;
    return val;
  }
}
