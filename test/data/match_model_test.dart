import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/data/models/match_model.dart';

void main() {
  group('MatchModel', () {
    test('parses complete match JSON correctly', () {
      final json = {
        'league': 'الدوري المصري',
        'team_home': 'الأهلي',
        'team_away': 'سموحة',
        'logo_home': 'https://example.com/ahly.png',
        'logo_away': 'https://example.com/smouha.png',
        'score_home': '2',
        'score_away': '1',
        'time': '20:00',
        'status': 'جارية',
        'channel': 'ON Sport',
      };

      final model = MatchModel.fromJson(json);
      expect(model.league, 'الدوري المصري');
      expect(model.teamHome, 'الأهلي');
      expect(model.teamAway, 'سموحة');
      expect(model.scoreHome, '2');
      expect(model.scoreAway, '1');
      expect(model.channel, 'ON Sport');
      expect(model.status, 'جارية');

      final fixture = model.toLiveFixture();
      expect(fixture.homeName, 'الأهلي');
      expect(fixture.awayName, 'سموحة');
      expect(fixture.homeScore, '2');
      expect(fixture.awayScore, '1');
      expect(fixture.isLive, isTrue);
      expect(fixture.broadcastChannel, 'ON Sport');
    });

    test('handles missing and null fields gracefully without throwing', () {
      final json = <String, dynamic>{};
      final model = MatchModel.fromJson(json);

      expect(model.league, 'Unknown League');
      expect(model.teamHome, 'Unknown');
      expect(model.teamAway, 'Unknown');
      expect(model.channel, 'Not Available');
      expect(model.time, '00:00');

      final fixture = model.toLiveFixture();
      expect(fixture.homeName, 'Unknown');
      expect(fixture.broadcastChannel, isNull);
      expect(fixture.isLive, isFalse);
    });

    test('sanitizes placeholder scores "-" to null in LiveFixture', () {
      final json = {
        'team_home': 'Arsenal',
        'team_away': 'Chelsea',
        'score_home': '-',
        'score_away': '-',
        'time': '18:30',
        'channel': 'beIN Sports 1',
      };

      final model = MatchModel.fromJson(json);
      final fixture = model.toLiveFixture();
      expect(fixture.homeScore, isNull);
      expect(fixture.awayScore, isNull);
      expect(fixture.broadcastChannel, 'beIN Sports 1');
    });

    test('differentiates live games when real time exceeds start time', () {
      final model = MatchModel.fromJson({
        'team_home': 'ليفربول',
        'team_away': 'إيبسويتش تاون',
        'time': '20:00',
        'status': 'لم تبدأ',
        'channel': 'beIN Sports 1',
      });

      final localStart = model.resolvedLocalStartTime(
        now: DateTime(2026, 9, 4, 12, 0),
      )!;
      final expectedLocalTimeStr = MatchModel.formatTimeHHmm(localStart);

      // Simulated current time: 30 mins after local kickoff
      final testTimeLive = localStart.add(const Duration(minutes: 30));
      final liveFixture = model.toLiveFixture(now: testTimeLive);
      expect(liveFixture.isLive, isTrue);
      expect(liveFixture.isUpcoming, isFalse);
      expect(liveFixture.state, 'in');
      expect(liveFixture.clock, "'+30");

      // Simulated current time: 2 hours before local kickoff
      final testTimeUpcoming = localStart.subtract(const Duration(hours: 2));
      final upcomingFixture = model.toLiveFixture(now: testTimeUpcoming);
      expect(upcomingFixture.isLive, isFalse);
      expect(upcomingFixture.isUpcoming, isTrue);
      expect(upcomingFixture.state, 'pre');
      expect(upcomingFixture.clock, expectedLocalTimeStr);
    });

    test('converts match time from UTC / Cairo UTC+2 across every country timezone', () {
      // Yallakora raw time 22:00 (UTC+2) => 20:00 UTC
      final model = MatchModel.fromJson({
        'team_home': 'ريال مدريد',
        'team_away': 'برشلونة',
        'time': '22:00',
        'time_utc': '20:00',
        'timezone_offset': 2,
        'status': 'لم تبدأ',
        'channel': 'beIN Sports 1',
      });

      final refNow = DateTime(2026, 11, 24, 15, 0);

      // In UTC+3 (Saudi Arabia / Qatar / Iraq / Kuwait / Jordan / etc.): 22:00 UTC+2 -> 23:00
      final fixtureUtcPlus3 = model.toLiveFixture(
        now: refNow,
        targetTimeZoneOffset: const Duration(hours: 3),
      );
      expect(fixtureUtcPlus3.scheduledTime, '23:00');
      expect(fixtureUtcPlus3.clock, '23:00');

      // In UTC+2 (Egypt): 22:00
      final fixtureUtcPlus2 = model.toLiveFixture(
        now: refNow,
        targetTimeZoneOffset: const Duration(hours: 2),
      );
      expect(fixtureUtcPlus2.scheduledTime, '22:00');

      // In UTC+4 (UAE / Oman): 00:00
      final fixtureUtcPlus4 = model.toLiveFixture(
        now: refNow,
        targetTimeZoneOffset: const Duration(hours: 4),
      );
      expect(fixtureUtcPlus4.scheduledTime, '00:00');

      // In UTC+1 (Morocco / Tunisia / Algeria / CET): 21:00
      final fixtureUtcPlus1 = model.toLiveFixture(
        now: refNow,
        targetTimeZoneOffset: const Duration(hours: 1),
      );
      expect(fixtureUtcPlus1.scheduledTime, '21:00');

      // In UTC+0 (UK / GMT): 20:00
      final fixtureUtc0 = model.toLiveFixture(
        now: refNow,
        targetTimeZoneOffset: Duration.zero,
      );
      expect(fixtureUtc0.scheduledTime, '20:00');

      // Legacy matches.json without time_utc (falls back to UTC+2 source -> UTC -> device local)
      final legacyModel = MatchModel.fromJson({
        'team_home': 'الأهلي',
        'team_away': 'الزمالك',
        'time': '22:00',
        'status': 'لم تبدأ',
        'channel': 'ON Sport',
      });
      final legacyUtcPlus3 = legacyModel.toLiveFixture(
        now: refNow,
        targetTimeZoneOffset: const Duration(hours: 3),
      );
      expect(legacyUtcPlus3.scheduledTime, '23:00');
    });
  });
}
