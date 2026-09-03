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

  LiveFixture toLiveFixture() {
    final teams = BigMatchDetector.teamsIn('$teamHome $teamAway');
    final isLiveNow = status.contains('جار') ||
        status.contains('شوط') ||
        status.toLowerCase().contains('live');

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
      state: isLiveNow ? 'in' : 'pre',
      clock: (status.isNotEmpty && status != 'لم تبدأ') ? status : time,
      league: league,
      homeScore: cleanScoreHome,
      awayScore: cleanScoreAway,
      homeLogoUrl: logoHome,
      awayLogoUrl: logoAway,
      broadcastChannel: cleanChannel,
    );
  }

  static String? _nullIfEmpty(String? val) {
    if (val == null || val.isEmpty) return null;
    return val;
  }
}
