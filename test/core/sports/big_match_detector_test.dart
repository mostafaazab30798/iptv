import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/core/sports/big_match_detector.dart';

void main() {
  group('BigMatchDetector', () {
    test('finds Barcelona and Real Madrid in titles', () {
      final teams = BigMatchDetector.teamsIn(
        '|AR| Barcelona vs Real Madrid 4K HEVC',
      );
      expect(teams.map((t) => t.id), ['barcelona', 'real_madrid']);
    });

    test('matches Arabic club names', () {
      final teams = BigMatchDetector.teamsIn('برشلونة ضد ريال مدريد');
      expect(teams.map((t) => t.id), ['barcelona', 'real_madrid']);
    });

    test('rejects official club TV stations', () {
      expect(BigMatchDetector.isOfficialClubChannel('Barcelona TV HD'), isTrue);
      expect(BigMatchDetector.isOfficialClubChannel('Liverpool TV'), isTrue);
      expect(BigMatchDetector.isOfficialClubChannel('Real Madrid TV'), isTrue);
      expect(
        BigMatchDetector.isOfficialClubChannel('beIN Sports 1 HD'),
        isFalse,
      );
    });

    test('only tracks Barcelona, Real Madrid, and the Premier League Big Six', () {
      expect(BigMatchDetector.teamsIn('Bayern Munich'), isEmpty);
      expect(BigMatchDetector.teamsIn('PSG'), isEmpty);
      expect(
        BigMatchDetector.teamsIn('Liverpool vs Chelsea').map((t) => t.id),
        ['liverpool', 'chelsea'],
      );
      expect(
        BigMatchDetector.teamsIn('Arsenal vs Manchester City').map((t) => t.id),
        ['man_city', 'arsenal'],
      );
    });

    test('allows beIN and Arabic-region sports networks, not Western ones', () {
      expect(
        BigMatchDetector.isAllowedMatchChannel('beIN Sports 1 HD'),
        isTrue,
      );
      expect(
        BigMatchDetector.isAllowedMatchChannel('AD Sports 1'),
        isTrue,
      );
      expect(
        BigMatchDetector.isAllowedMatchChannel('أبوظبي الرياضية 1'),
        isTrue,
      );
      expect(
        BigMatchDetector.isAllowedMatchChannel('Sky Sports Main Event'),
        isFalse,
      );
      expect(
        BigMatchDetector.isAllowedMatchChannel('ESPN HD'),
        isFalse,
      );
      expect(
        BigMatchDetector.isAllowedMatchChannel('Barcelona TV 4K'),
        isFalse,
      );
    });
  });
}
