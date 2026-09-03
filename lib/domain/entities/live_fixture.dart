import 'package:equatable/equatable.dart';
import 'package:iptv/core/sports/big_match_detector.dart';

/// A currently live (or imminent) football match from an external scoreboard.
class LiveFixture extends Equatable {
  const LiveFixture({
    required this.homeName,
    required this.awayName,
    required this.teams,
    this.state = 'in',
    this.clock,
    this.league,
    this.homeScore,
    this.awayScore,
    this.bannerUrl,
    this.posterUrl,
    this.homeLogoUrl,
    this.awayLogoUrl,
    this.start,
    this.broadcastChannel,
  });

  final String homeName;
  final String awayName;
  final List<BigTeam> teams;
  final String state;
  final String? clock;
  final String? league;
  final String? homeScore;
  final String? awayScore;

  /// Landscape match artwork for the Home hero backdrop.
  final String? bannerUrl;

  /// Portrait match poster for the Home hero card.
  final String? posterUrl;
  final String? homeLogoUrl;
  final String? awayLogoUrl;
  final DateTime? start;

  /// Name of the broadcasting channel (e.g. from Yallakora).
  final String? broadcastChannel;

  String get headline => '$homeName vs $awayName';

  bool get isLive => state == 'in';

  String? get heroBackdropUrl =>
      _firstUrl([bannerUrl, posterUrl, homeLogoUrl, awayLogoUrl]);

  String? get heroPosterUrl =>
      _firstUrl([posterUrl, bannerUrl, homeLogoUrl, awayLogoUrl]);

  LiveFixture withArtwork({String? bannerUrl, String? posterUrl}) {
    return LiveFixture(
      homeName: homeName,
      awayName: awayName,
      teams: teams,
      state: state,
      clock: clock,
      league: league,
      homeScore: homeScore,
      awayScore: awayScore,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      posterUrl: posterUrl ?? this.posterUrl,
      homeLogoUrl: homeLogoUrl,
      awayLogoUrl: awayLogoUrl,
      start: start,
      broadcastChannel: broadcastChannel,
    );
  }

  static String? _firstUrl(List<String?> urls) {
    for (final url in urls) {
      if (url != null && url.trim().isNotEmpty) return url;
    }
    return null;
  }

  /// True when this fixture's clubs appear in a channel name or EPG title.
  bool matchesBroadcastText(String text) {
    if (teams.isEmpty) return false;
    final normalized = BigMatchDetector.normalize(text);
    return teams.every((team) => team.matchesNormalized(normalized));
  }

  @override
  List<Object?> get props => [homeName, awayName, state, clock, broadcastChannel];
}

abstract interface class LiveScoreSource {
  Future<List<LiveFixture>> fetchLiveBigMatches();
}

class EmptyLiveScoreSource implements LiveScoreSource {
  const EmptyLiveScoreSource();

  @override
  Future<List<LiveFixture>> fetchLiveBigMatches() async => const [];
}
