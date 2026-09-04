import 'package:equatable/equatable.dart';
import 'package:iptv/core/sports/big_match_detector.dart';

/// Represents a goal event (scorer, minute, own goal, penalty).
class MatchGoal extends Equatable {
  const MatchGoal({
    required this.player,
    required this.minute,
    this.isOwnGoal = false,
    this.isPenalty = false,
  });

  final String player;
  final String minute;
  final bool isOwnGoal;
  final bool isPenalty;

  String get displayLabel {
    final prefix = isOwnGoal ? '(OG) ' : (isPenalty ? '(P) ' : '');
    return '$prefix$player $minute';
  }

  @override
  List<Object?> get props => [player, minute, isOwnGoal, isPenalty];
}

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
    this.scheduledTime,
    this.rawStatus,
    this.homePenScore,
    this.awayPenScore,
    this.homeGoals = const [],
    this.awayGoals = const [],
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

  /// Original scheduled starting time string (e.g. "22:00").
  final String? scheduledTime;

  /// Raw scraped status string (e.g. "لم تبدأ", "جارية").
  final String? rawStatus;

  /// Penalty shootout scores (if match decided on penalties).
  final int? homePenScore;
  final int? awayPenScore;

  /// Goal events for each side.
  final List<MatchGoal> homeGoals;
  final List<MatchGoal> awayGoals;

  String get headline => '$homeName vs $awayName';

  bool get isLive => state == 'in';
  bool get isUpcoming => state == 'pre';
  bool get isFinished => state == 'post';

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
      scheduledTime: scheduledTime,
      rawStatus: rawStatus,
      homePenScore: homePenScore,
      awayPenScore: awayPenScore,
      homeGoals: homeGoals,
      awayGoals: awayGoals,
    );
  }

  LiveFixture copyWith({
    String? homeName,
    String? awayName,
    List<BigTeam>? teams,
    String? state,
    String? clock,
    String? league,
    String? homeScore,
    String? awayScore,
    String? bannerUrl,
    String? posterUrl,
    String? homeLogoUrl,
    String? awayLogoUrl,
    DateTime? start,
    String? broadcastChannel,
    String? scheduledTime,
    String? rawStatus,
    int? homePenScore,
    int? awayPenScore,
    List<MatchGoal>? homeGoals,
    List<MatchGoal>? awayGoals,
  }) {
    return LiveFixture(
      homeName: homeName ?? this.homeName,
      awayName: awayName ?? this.awayName,
      teams: teams ?? this.teams,
      state: state ?? this.state,
      clock: clock ?? this.clock,
      league: league ?? this.league,
      homeScore: homeScore ?? this.homeScore,
      awayScore: awayScore ?? this.awayScore,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      posterUrl: posterUrl ?? this.posterUrl,
      homeLogoUrl: homeLogoUrl ?? this.homeLogoUrl,
      awayLogoUrl: awayLogoUrl ?? this.awayLogoUrl,
      start: start ?? this.start,
      broadcastChannel: broadcastChannel ?? this.broadcastChannel,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      rawStatus: rawStatus ?? this.rawStatus,
      homePenScore: homePenScore ?? this.homePenScore,
      awayPenScore: awayPenScore ?? this.awayPenScore,
      homeGoals: homeGoals ?? this.homeGoals,
      awayGoals: awayGoals ?? this.awayGoals,
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
  List<Object?> get props => [
        homeName,
        awayName,
        state,
        clock,
        broadcastChannel,
        scheduledTime,
        rawStatus,
        homeScore,
        awayScore,
        homePenScore,
        awayPenScore,
        homeGoals,
        awayGoals,
      ];
}

abstract interface class LiveScoreSource {
  Future<List<LiveFixture>> fetchLiveBigMatches({bool forceRefresh = false});
}

class EmptyLiveScoreSource implements LiveScoreSource {
  const EmptyLiveScoreSource();

  @override
  Future<List<LiveFixture>> fetchLiveBigMatches({bool forceRefresh = false}) async => const [];
}
