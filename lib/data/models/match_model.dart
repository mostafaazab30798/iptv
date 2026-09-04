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
        lowerStatus.contains('ft')) {
      return (state: 'post', clock: status.isNotEmpty ? status : 'انتهت');
    }

    // 2. Explicit live status from provider
    if (lowerStatus.contains('جار') ||
        lowerStatus.contains('شوط') ||
        lowerStatus.contains('استراح') ||
        lowerStatus.contains('live')) {
      return (state: 'in', clock: status.isNotEmpty ? status : time);
    }

    // 3. Real-time vs scheduled start time check
    final parts = time.trim().split(':');
    if (parts.length >= 2) {
      final hour = int.tryParse(parts[0].trim());
      final minute = int.tryParse(parts[1].trim());
      if (hour != null && minute != null) {
        final matchStartTime = DateTime(
          current.year,
          current.month,
          current.day,
          hour,
          minute,
        );

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
    );
  }

  static String? _nullIfEmpty(String? val) {
    if (val == null || val.isEmpty) return null;
    return val;
  }
}
