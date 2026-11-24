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
    this.timeUtc,
    this.kickoffUtc,
    this.sourceTimeZoneOffsetHours = defaultSourceTimeZoneOffsetHours,
    this.status = '',
    required this.channel,
    this.homePenScore,
    this.awayPenScore,
    this.homeGoals = const [],
    this.awayGoals = const [],
  });

  /// Yallakora's server outputs times in Cairo Standard Time (UTC+2) when
  /// scraped from UTC servers.
  static const int defaultSourceTimeZoneOffsetHours = 2;

  final String league;
  final String teamHome;
  final String teamAway;
  final String? logoHome;
  final String? logoAway;
  final String? scoreHome;
  final String? scoreAway;
  final String time;

  /// Match kickoff time in Universal Time (UTC) as "HH:MM" (if provided by JSON).
  final String? timeUtc;

  /// Full ISO-8601 UTC timestamp for kickoff (if provided by JSON).
  final String? kickoffUtc;

  /// Timezone offset (in hours from UTC) of the raw [time] field when [timeUtc]
  /// is not explicitly provided. Defaults to [defaultSourceTimeZoneOffsetHours] (UTC+2).
  final int sourceTimeZoneOffsetHours;

  final String status;
  final String channel;
  final int? homePenScore;
  final int? awayPenScore;
  final List<MatchGoal> homeGoals;
  final List<MatchGoal> awayGoals;

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    final rawOffset = json['timezone_offset'];
    final parsedOffset = rawOffset is num
        ? rawOffset.toInt()
        : int.tryParse(rawOffset?.toString().trim() ?? '');

    return MatchModel(
      league: json['league']?.toString().trim() ?? 'Unknown League',
      teamHome: json['team_home']?.toString().trim() ?? 'Unknown',
      teamAway: json['team_away']?.toString().trim() ?? 'Unknown',
      logoHome: _nullIfEmpty(json['logo_home']?.toString().trim()),
      logoAway: _nullIfEmpty(json['logo_away']?.toString().trim()),
      scoreHome: _nullIfEmpty(json['score_home']?.toString().trim()),
      scoreAway: _nullIfEmpty(json['score_away']?.toString().trim()),
      time: json['time']?.toString().trim() ?? '00:00',
      timeUtc: _nullIfEmpty(json['time_utc']?.toString().trim()),
      kickoffUtc: _nullIfEmpty(json['kickoff_utc']?.toString().trim()),
      sourceTimeZoneOffsetHours:
          parsedOffset ?? defaultSourceTimeZoneOffsetHours,
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
      if (timeUtc != null) 'time_utc': timeUtc,
      if (kickoffUtc != null) 'kickoff_utc': kickoffUtc,
      'timezone_offset': sourceTimeZoneOffsetHours,
      'status': status,
      'channel': channel,
    };
  }

  /// Normalizes Arabic-Indic digits to standard Western digits.
  static String normalizeDigits(String input) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    var result = input;
    for (var i = 0; i < 10; i++) {
      result = result.replaceAll(arabicDigits[i], '$i');
    }
    return result;
  }

  /// Formats a [DateTime] into "HH:MM" (24-hour local format).
  static String formatTimeHHmm(DateTime dateTime) {
    final h = dateTime.hour.toString().padLeft(2, '0');
    final m = dateTime.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// Converts a match time from Universal Time (UTC) or the source timezone
  /// (defaulting to Yallakora's UTC+2) into the device's local timezone
  /// (or [targetTimeZoneOffset] if provided for deterministic testing).
  ///
  /// Example:
  /// - Source time "22:00" (UTC+2) -> 20:00 UTC -> "23:00" in a UTC+3 country.
  /// - Explicit [timeUtc] "20:00" (UTC) -> "23:00" in a UTC+3 country.
  static DateTime? parseStartTime(
    String time, {
    DateTime? now,
    String? timeUtc,
    String? kickoffUtc,
    int? sourceTimeZoneOffsetHours,
    Duration? targetTimeZoneOffset,
  }) {
    final current = now ?? DateTime.now();
    final localOffset = targetTimeZoneOffset ?? current.timeZoneOffset;

    // 1. If a full ISO-8601 UTC timestamp is provided and no explicit test `now`
    // overrides the date context, parse it directly and shift to the local timezone.
    if (kickoffUtc != null && kickoffUtc.trim().isNotEmpty && now == null) {
      final parsedIso = DateTime.tryParse(kickoffUtc.trim());
      if (parsedIso != null) {
        final utcMoment = parsedIso.toUtc();
        if (targetTimeZoneOffset != null) {
          final shifted = utcMoment.add(targetTimeZoneOffset);
          return DateTime(
            shifted.year,
            shifted.month,
            shifted.day,
            shifted.hour,
            shifted.minute,
          );
        }
        final localMoment = utcMoment.toLocal();
        return DateTime(
          localMoment.year,
          localMoment.month,
          localMoment.day,
          localMoment.hour,
          localMoment.minute,
        );
      }
    }

    // 2. Determine the raw time string and its origin UTC offset.
    final bool hasExplicitUtc = timeUtc != null && timeUtc.trim().isNotEmpty;
    final rawTimeStr = hasExplicitUtc ? timeUtc : time;
    final normalized = normalizeDigits(rawTimeStr).trim();
    final parts = normalized.split(':');
    if (parts.length < 2) return null;

    final rawHour = int.tryParse(parts[0].trim());
    final rawMinute = int.tryParse(parts[1].trim());
    if (rawHour == null || rawMinute == null) return null;

    // Convert source time -> Universal Time (UTC) -> Device Local Time.
    final Duration sourceOffset = hasExplicitUtc
        ? Duration.zero
        : (sourceTimeZoneOffsetHours != null
              ? Duration(hours: sourceTimeZoneOffsetHours)
              : localOffset);

    final totalSourceMinutes = rawHour * 60 + rawMinute;
    final utcMinutes = totalSourceMinutes - sourceOffset.inMinutes;
    final localTotalMinutes = utcMinutes + localOffset.inMinutes;

    var dayDelta = 0;
    var wrappedMinutes = localTotalMinutes;
    while (wrappedMinutes < 0) {
      wrappedMinutes += 1440;
      dayDelta -= 1;
    }
    while (wrappedMinutes >= 1440) {
      wrappedMinutes -= 1440;
      dayDelta += 1;
    }

    final localHour = wrappedMinutes ~/ 60;
    final localMinute = wrappedMinutes % 60;

    var matchStartTime = DateTime(
      current.year,
      current.month,
      current.day,
      localHour,
      localMinute,
    ).add(Duration(days: dayDelta));

    // When no timezone shift caused a calendar day wrap, apply cross-midnight
    // heuristic for raw local time strings without full date info.
    if (dayDelta == 0) {
      // If it's early in the morning (00:00 - 05:59) and the match was scheduled
      // for evening (18:00 - 23:59), the match was kicked off yesterday evening.
      if (current.hour < 6 && localHour >= 18) {
        matchStartTime = matchStartTime.subtract(const Duration(days: 1));
      }
      // If it's late evening (18:00 - 23:59) and the match is scheduled
      // for early morning (00:00 - 05:59), it's kicking off tomorrow morning.
      else if (current.hour >= 18 && localHour < 6) {
        matchStartTime = matchStartTime.add(const Duration(days: 1));
      }
    }

    return matchStartTime;
  }

  /// Converts a match time string to the device's local "HH:MM" representation
  /// via Universal Time (UTC).
  static String formatLocalTime(
    String time, {
    DateTime? now,
    String? timeUtc,
    String? kickoffUtc,
    int? sourceTimeZoneOffsetHours = defaultSourceTimeZoneOffsetHours,
    Duration? targetTimeZoneOffset,
  }) {
    final parsed = parseStartTime(
      time,
      now: now,
      timeUtc: timeUtc,
      kickoffUtc: kickoffUtc,
      sourceTimeZoneOffsetHours: sourceTimeZoneOffsetHours,
      targetTimeZoneOffset: targetTimeZoneOffset,
    );
    if (parsed == null) return time;
    return formatTimeHHmm(parsed);
  }

  /// The match's scheduled time converted from UTC to the phone's local timezone.
  String localTimeLabel({DateTime? now, Duration? targetTimeZoneOffset}) {
    return formatLocalTime(
      time,
      now: now,
      timeUtc: timeUtc,
      kickoffUtc: kickoffUtc,
      sourceTimeZoneOffsetHours: sourceTimeZoneOffsetHours,
      targetTimeZoneOffset: targetTimeZoneOffset,
    );
  }

  /// Resolves the match start [DateTime] in the phone's local timezone.
  DateTime? resolvedLocalStartTime({
    DateTime? now,
    Duration? targetTimeZoneOffset,
  }) {
    return parseStartTime(
      time,
      now: now,
      timeUtc: timeUtc,
      kickoffUtc: kickoffUtc,
      sourceTimeZoneOffsetHours: sourceTimeZoneOffsetHours,
      targetTimeZoneOffset: targetTimeZoneOffset,
    );
  }

  /// Whether the match needs score or goal enrichment from FotMob.
  /// Matches that are in progress, finished today, past scheduled kickoff,
  /// or within the [window] (default 10 minutes) before kickoff are eligible.
  bool needsScoreOrGoalsEnrichment({
    DateTime? now,
    Duration window = const Duration(minutes: 10),
    Duration? targetTimeZoneOffset,
  }) {
    final current = now ?? DateTime.now();
    final localTime = localTimeLabel(
      now: current,
      targetTimeZoneOffset: targetTimeZoneOffset,
    );
    final startTime = resolvedLocalStartTime(
      now: current,
      targetTimeZoneOffset: targetTimeZoneOffset,
    );
    final timing = resolveMatchTiming(
      status: status,
      time: localTime,
      now: current,
      startTime: startTime,
    );

    // Matches in progress or finished today need score and goal data
    if (timing.state == 'in' || timing.state == 'post') return true;

    if (startTime == null) return false;

    // Past kickoff time
    if (current.isAfter(startTime) || current.isAtSameMomentAs(startTime)) {
      return true;
    }

    // Within pre-kickoff window
    final windowStart = startTime.subtract(window);
    return current.isAfter(windowStart) || current.isAtSameMomentAs(windowStart);
  }

  /// Whether the match is currently live, or is scheduled to start within [window]
  /// (default 10 minutes) before kickoff.
  bool isEligibleForRealtime({
    DateTime? now,
    Duration window = const Duration(minutes: 10),
    Duration? targetTimeZoneOffset,
  }) {
    final current = now ?? DateTime.now();
    final localTime = localTimeLabel(
      now: current,
      targetTimeZoneOffset: targetTimeZoneOffset,
    );
    final startTime = resolvedLocalStartTime(
      now: current,
      targetTimeZoneOffset: targetTimeZoneOffset,
    );
    final timing = resolveMatchTiming(
      status: status,
      time: localTime,
      now: current,
      startTime: startTime,
    );

    // If already in progress, always track real-time
    if (timing.state == 'in') return true;

    // If already finished, no real-time polling needed
    if (timing.state == 'post') return false;

    // For upcoming matches, only track if within the pre-kickoff window
    if (startTime == null) return false;

    final windowStart = startTime.subtract(window);
    final matchEndEstimate = startTime.add(const Duration(minutes: 130));

    return (current.isAfter(windowStart) || current.isAtSameMomentAs(windowStart)) &&
        current.isBefore(matchEndEstimate);
  }

  /// Calculates the time remaining until the [window] (default 10 minutes)
  /// before kickoff begins. Returns [Duration.zero] if already within the window,
  /// or null if the match is finished or time is unparseable.
  Duration? timeUntilRealtimeWindow({
    DateTime? now,
    Duration window = const Duration(minutes: 10),
    Duration? targetTimeZoneOffset,
  }) {
    final current = now ?? DateTime.now();
    final localTime = localTimeLabel(
      now: current,
      targetTimeZoneOffset: targetTimeZoneOffset,
    );
    final startTime = resolvedLocalStartTime(
      now: current,
      targetTimeZoneOffset: targetTimeZoneOffset,
    );
    final timing = resolveMatchTiming(
      status: status,
      time: localTime,
      now: current,
      startTime: startTime,
    );
    if (timing.state == 'post') return null;
    if (timing.state == 'in') return Duration.zero;

    if (startTime == null) return null;

    final windowStart = startTime.subtract(window);
    if (current.isAfter(windowStart) || current.isAtSameMomentAs(windowStart)) {
      return Duration.zero;
    }
    return windowStart.difference(current);
  }

  /// Resolves the match state ('in', 'pre', 'post') and clock label based on
  /// both the scraped status string and whether the real current time has
  /// reached or exceeded the scheduled kickoff time.
  static ({String state, String? clock}) resolveMatchTiming({
    required String status,
    required String time,
    DateTime? now,
    DateTime? startTime,
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
    final matchStartTime = startTime ?? parseStartTime(time, now: current);
    if (matchStartTime != null) {
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
    String? timeUtc,
    String? kickoffUtc,
    int? sourceTimeZoneOffsetHours,
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
      timeUtc: timeUtc ?? this.timeUtc,
      kickoffUtc: kickoffUtc ?? this.kickoffUtc,
      sourceTimeZoneOffsetHours:
          sourceTimeZoneOffsetHours ?? this.sourceTimeZoneOffsetHours,
      status: status ?? this.status,
      channel: channel ?? this.channel,
      homePenScore: homePenScore ?? this.homePenScore,
      awayPenScore: awayPenScore ?? this.awayPenScore,
      homeGoals: homeGoals ?? this.homeGoals,
      awayGoals: awayGoals ?? this.awayGoals,
    );
  }

  LiveFixture toLiveFixture({
    DateTime? now,
    Duration? targetTimeZoneOffset,
  }) {
    final teams = BigMatchDetector.teamsIn('$teamHome $teamAway');
    final localStart = resolvedLocalStartTime(
      now: now,
      targetTimeZoneOffset: targetTimeZoneOffset,
    );
    final localTime = localStart != null ? formatTimeHHmm(localStart) : time;
    final timing = resolveMatchTiming(
      status: status,
      time: localTime,
      now: now,
      startTime: localStart,
    );

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
      scheduledTime: localTime,
      rawStatus: status,
      start: localStart,
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
