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

      // Simulated current time: 20:30 (30 mins after kickoff)
      final testTimeLive = DateTime(2026, 9, 4, 20, 30);
      final liveFixture = model.toLiveFixture(now: testTimeLive);
      expect(liveFixture.isLive, isTrue);
      expect(liveFixture.isUpcoming, isFalse);
      expect(liveFixture.state, 'in');
      expect(liveFixture.clock, "'+30");

      // Simulated current time: 18:00 (2 hours before kickoff)
      final testTimeUpcoming = DateTime(2026, 9, 4, 18, 0);
      final upcomingFixture = model.toLiveFixture(now: testTimeUpcoming);
      expect(upcomingFixture.isLive, isFalse);
      expect(upcomingFixture.isUpcoming, isTrue);
      expect(upcomingFixture.state, 'pre');
      expect(upcomingFixture.clock, '20:00');
    });
  });
}
