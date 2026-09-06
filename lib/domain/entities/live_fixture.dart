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

  /// Normalizes Arabic-Indic digits to standard Western digits.
  static String normalizeDigits(String input) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    var result = input;
    for (var i = 0; i < 10; i++) {
      result = result.replaceAll(arabicDigits[i], '$i');
    }
    return result;
  }

  /// Parses scheduled kickoff time string (e.g. "20:00" or " 20:00 ") into a [DateTime].
  /// Handles Eastern-Arabic numerals and cross-midnight scheduling.
  static DateTime? parseStartTime(String time, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final normalized = normalizeDigits(time).trim();
    final parts = normalized.split(':');
    if (parts.length < 2) return null;

    final hour = int.tryParse(parts[0].trim());
    final minute = int.tryParse(parts[1].trim());
    if (hour == null || minute == null) return null;

    var matchStartTime = DateTime(
      current.year,
      current.month,
      current.day,
      hour,
      minute,
    );

    // If it's early in the morning (00:00 - 05:59) and the match was scheduled
    // for evening (18:00 - 23:59), the match was kicked off yesterday evening.
    if (current.hour < 6 && hour >= 18) {
      matchStartTime = matchStartTime.subtract(const Duration(days: 1));
    }
    // If it's late evening (18:00 - 23:59) and the match is scheduled
    // for early morning (00:00 - 05:59), it's kicking off tomorrow morning.
    else if (current.hour >= 18 && hour < 6) {
      matchStartTime = matchStartTime.add(const Duration(days: 1));
    }

    return matchStartTime;
  }

  /// Resolves the actual scheduled kickoff [DateTime].
  DateTime? resolvedStartTime({DateTime? now}) =>
      start ??
      (scheduledTime != null ? parseStartTime(scheduledTime!, now: now) : null);

  /// Whether the match is currently live, or is scheduled to start within [window]
  /// (default 10 minutes) before kickoff.
  bool isEligibleForRealtime({
    DateTime? now,
    Duration window = const Duration(minutes: 10),
  }) {
    if (isLive) return true;
    if (isFinished) return false;

    final current = now ?? DateTime.now();
    final startTime = resolvedStartTime(now: current);
    if (startTime == null) return false;

    final windowStart = startTime.subtract(window);
    final matchEndEstimate = startTime.add(const Duration(minutes: 130));

    return (current.isAfter(windowStart) ||
            current.isAtSameMomentAs(windowStart)) &&
        current.isBefore(matchEndEstimate);
  }

  /// Calculates the duration remaining until the [window] (default 10 minutes)
  /// before kickoff begins. Returns [Duration.zero] if already within the window,
  /// or null if the match is finished or kickoff time is unparseable.
  Duration? timeUntilRealtimeWindow({
    DateTime? now,
    Duration window = const Duration(minutes: 10),
  }) {
    if (isFinished) return null;
    if (isLive) return Duration.zero;

    final current = now ?? DateTime.now();
    final startTime = resolvedStartTime(now: current);
    if (startTime == null) return null;

    final windowStart = startTime.subtract(window);
    if (current.isAfter(windowStart) || current.isAtSameMomentAs(windowStart)) {
      return Duration.zero;
    }
    return windowStart.difference(current);
  }

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
