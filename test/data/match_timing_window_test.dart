import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/data/models/match_model.dart';
import 'package:iptv/domain/entities/live_fixture.dart';

void main() {
  group('Match timing and real-time window eligibility', () {
    test('parseStartTime parses standard and Arabic-Indic numerals correctly', () {
      final now = DateTime(2026, 9, 6, 12, 0);

      final t1 = MatchModel.parseStartTime('20:45', now: now);
      expect(t1, DateTime(2026, 9, 6, 20, 45));

      final t2 = MatchModel.parseStartTime(' ٢٠:٤٥ ', now: now);
      expect(t2, DateTime(2026, 9, 6, 20, 45));

      final t3 = LiveFixture.parseStartTime('18:00', now: now);
      expect(t3, DateTime(2026, 9, 6, 18, 0));
    });

    test('parseStartTime handles cross-midnight cases correctly', () {
      // 1. Current time is 23:55, match is scheduled for 00:30 (tomorrow morning)
      final lateNight = DateTime(2026, 9, 6, 23, 55);
      final nextDayMatch = MatchModel.parseStartTime('00:30', now: lateNight);
      expect(nextDayMatch, DateTime(2026, 9, 7, 0, 30));

      // 2. Current time is 01:30 AM, match was scheduled yesterday at 21:00
      final earlyMorning = DateTime(2026, 9, 7, 1, 30);
      final yesterdayMatch = MatchModel.parseStartTime('21:00', now: earlyMorning);
      expect(yesterdayMatch, DateTime(2026, 9, 6, 21, 0));
    });

    test('isEligibleForRealtime returns true only 10 minutes before kickoff and during match', () {
      const match = MatchModel(
        league: 'Premier League',
        teamHome: 'Arsenal',
        teamAway: 'Chelsea',
        time: '20:00',
        channel: 'beIN Sports 1',
      );

      // 1. More than 10 minutes before (e.g. 18:00 -> 2 hours away)
      expect(
        match.isEligibleForRealtime(now: DateTime(2026, 9, 6, 18, 0)),
        isFalse,
      );

      // 2. 11 minutes before (19:49) -> not yet in window
      expect(
        match.isEligibleForRealtime(now: DateTime(2026, 9, 6, 19, 49)),
        isFalse,
      );

      // 3. Exactly 10 minutes before (19:50) -> in window!
      expect(
        match.isEligibleForRealtime(now: DateTime(2026, 9, 6, 19, 50)),
        isTrue,
      );

      // 4. 5 minutes before (19:55) -> in window!
      expect(
        match.isEligibleForRealtime(now: DateTime(2026, 9, 6, 19, 55)),
        isTrue,
      );

      // 5. During match (20:45 -> second half) -> live!
      expect(
        match.isEligibleForRealtime(now: DateTime(2026, 9, 6, 20, 45)),
        isTrue,
      );

      // 6. Explicit live status
      const liveMatch = MatchModel(
        league: 'Premier League',
        teamHome: 'Arsenal',
        teamAway: 'Chelsea',
        time: '20:00',
        status: 'جارية',
        channel: 'beIN Sports 1',
      );
      expect(
        liveMatch.isEligibleForRealtime(now: DateTime(2026, 9, 6, 18, 0)),
        isTrue,
      );

      // 7. Finished match
      const finishedMatch = MatchModel(
        league: 'Premier League',
        teamHome: 'Arsenal',
        teamAway: 'Chelsea',
        time: '20:00',
        status: 'انتهت',
        channel: 'beIN Sports 1',
      );
      expect(
        finishedMatch.isEligibleForRealtime(now: DateTime(2026, 9, 6, 22, 30)),
        isFalse,
      );
    });

    test('timeUntilRealtimeWindow accurately computes wait duration', () {
      const match = MatchModel(
        league: 'La Liga',
        teamHome: 'Real Madrid',
        teamAway: 'Barcelona',
        time: '21:00',
        channel: 'beIN Sports 1',
      );

      // Current time is 19:00 -> window starts at 20:50 (1 hour 50 minutes = 110 minutes)
      final wait = match.timeUntilRealtimeWindow(now: DateTime(2026, 9, 6, 19, 0));
      expect(wait, const Duration(hours: 1, minutes: 50));

      // Current time is 20:55 (already inside window) -> Duration.zero
      final insideWait = match.timeUntilRealtimeWindow(now: DateTime(2026, 9, 6, 20, 55));
      expect(insideWait, Duration.zero);

      // Finished match -> null
      const finished = MatchModel(
        league: 'La Liga',
        teamHome: 'Real Madrid',
        teamAway: 'Barcelona',
        time: '21:00',
        status: 'انتهت',
        channel: 'beIN Sports 1',
      );
      expect(finished.timeUntilRealtimeWindow(now: DateTime(2026, 9, 6, 23, 30)), isNull);
    });

    test('LiveFixture correctly inherits timing from toLiveFixture and computes eligibility', () {
      final now = DateTime(2026, 9, 6, 15, 0);
      const model = MatchModel(
        league: 'Champions League',
        teamHome: 'PSG',
        teamAway: 'Bayern',
        time: '22:00',
        channel: 'beIN Sports 1',
      );

      final fixture = model.toLiveFixture(now: now);
      expect(fixture.start, DateTime(2026, 9, 6, 22, 0));
      expect(fixture.isEligibleForRealtime(now: now), isFalse);

      // When time advances to 21:51 (9 minutes before 22:00)
      expect(fixture.isEligibleForRealtime(now: DateTime(2026, 9, 6, 21, 51)), isTrue);
    });
  });
}
