import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/core/sports/big_match_detector.dart';
import 'package:iptv/core/sports/match_wallpaper_resolver.dart';
import 'package:iptv/data/models/match_model.dart';
import 'package:iptv/domain/entities/channel.dart';
import 'package:iptv/domain/entities/live_fixture.dart';
import 'package:iptv/domain/entities/live_match.dart';

Channel _mockChannel(int id, String name) {
  return Channel(
    id: id,
    serverId: 1,
    streamId: id,
    name: name,
    categoryId: 1,
  );
}

void main() {
  final barca = BigMatchDetector.teamsIn('Barcelona').first;
  final rm = BigMatchDetector.teamsIn('Real Madrid').first;
  final liverpool = BigMatchDetector.teamsIn('Liverpool').first;
  final manCity = BigMatchDetector.teamsIn('Manchester City').first;
  final arsenal = BigMatchDetector.teamsIn('Arsenal').first;

  group('MatchWallpaperResolver', () {
    test('resolves fcb.jpg for Barcelona match', () {
      final fixture = LiveFixture(
        homeName: 'Barcelona',
        awayName: 'Girona',
        teams: [barca],
        league: 'الدوري الإسباني',
      );
      final match = LiveMatch(
        channel: _mockChannel(101, 'beIN Sports 1 HD'),
        programTitle: 'Barcelona vs Girona',
        teams: [barca],
        fixture: fixture,
      );

      final wallpaper = MatchWallpaperResolver.resolveWallpaper(match);
      expect(wallpaper, MatchWallpaperResolver.barcelonaWallpaper);
      expect(wallpaper, 'assets/images/fcb.jpg');
    });

    test('resolves fcb.jpg when Arabic team name is used for Barcelona', () {
      final fixture = LiveFixture(
        homeName: 'برشلونة',
        awayName: 'خيتافي',
        teams: [barca],
        league: 'الدوري الإسباني',
      );
      final match = LiveMatch(
        channel: _mockChannel(102, 'beIN Sports 3 HD'),
        programTitle: 'مباراة برشلونة وخيتافي',
        teams: [barca],
        fixture: fixture,
      );

      final wallpaper = MatchWallpaperResolver.resolveWallpaper(match);
      expect(wallpaper, 'assets/images/fcb.jpg');
    });

    test('resolves rm.jpg for Real Madrid match', () {
      final fixture = LiveFixture(
        homeName: 'Real Betis',
        awayName: 'Real Madrid',
        teams: [rm],
        league: 'الدوري الإسباني',
      );
      final match = LiveMatch(
        channel: _mockChannel(103, 'beIN Sports 1 HD'),
        programTitle: 'Real Betis vs Real Madrid',
        teams: [rm],
        fixture: fixture,
      );

      final wallpaper = MatchWallpaperResolver.resolveWallpaper(match);
      expect(wallpaper, MatchWallpaperResolver.realMadridWallpaper);
      expect(wallpaper, 'assets/images/rm.jpg');
    });

    test('resolves rm.jpg when Arabic name is used for Real Madrid', () {
      final fixture = LiveFixture(
        homeName: 'ريال مدريد',
        awayName: 'سيلتا فيجو',
        teams: [rm],
        league: 'الدوري الإسباني',
      );
      final match = LiveMatch(
        channel: _mockChannel(104, 'beIN Sports 1 HD'),
        programTitle: 'ريال مدريد ضد سيلتا فيجو',
        teams: [rm],
        fixture: fixture,
      );

      final wallpaper = MatchWallpaperResolver.resolveWallpaper(match);
      expect(wallpaper, 'assets/images/rm.jpg');
    });

    test('resolves rm.jpg for exact Yallakora matches.json Real Madrid fixture', () {
      final model = MatchModel.fromJson(const {
        'league': 'الدوري الإسباني',
        'team_home': 'ريال بيتيس',
        'team_away': 'ريال مدريد',
        'logo_home': 'https://mediayk.gemini.media/img/yallakora/iosteams/120/2018/7/29/RealBetis2018_7_29_14_50.jpg',
        'logo_away': 'https://mediayk.gemini.media/img/yallakora/iosteams/120/2018/7/29/RealMadrid2018_7_29_14_47.jpg',
        'score_home': '-',
        'score_away': '-',
        'time': '22:00',
        'status': 'لم تبدأ',
        'channel': 'بى ان سبورت 3 HD',
      });
      final fixture = model.toLiveFixture();
      final match = LiveMatch(
        channel: _mockChannel(103, 'بى ان سبورت 3 HD'),
        programTitle: fixture.headline,
        teams: fixture.teams,
        fixture: fixture,
      );

      final wallpaper = MatchWallpaperResolver.resolveWallpaper(match);
      expect(wallpaper, 'assets/images/rm.jpg');
    });

    test('resolves Barcelona image for Barcelona vs Real Madrid', () {
      final fixtureBarcaHome = LiveFixture(
        homeName: 'FC Barcelona',
        awayName: 'Real Madrid',
        teams: [barca, rm],
        league: 'La Liga',
      );
      final matchBarcaHome = LiveMatch(
        channel: _mockChannel(105, 'beIN Sports 1 HD'),
        programTitle: 'El Clasico',
        teams: [barca, rm],
        fixture: fixtureBarcaHome,
      );
      expect(
        MatchWallpaperResolver.resolveWallpaper(matchBarcaHome),
        'assets/images/fcb.jpg',
      );

      final fixtureRmHome = LiveFixture(
        homeName: 'Real Madrid CF',
        awayName: 'FC Barcelona',
        teams: [rm, barca],
        league: 'La Liga',
      );
      final matchRmHome = LiveMatch(
        channel: _mockChannel(106, 'beIN Sports 1 HD'),
        programTitle: 'El Clasico',
        teams: [rm, barca],
        fixture: fixtureRmHome,
      );
      expect(
        MatchWallpaperResolver.resolveWallpaper(matchRmHome),
        'assets/images/fcb.jpg',
      );
    });

    test('resolves pl.jpg for any Premier League match (Arabic & English)', () {
      // English league name
      final matchEnglishPl = LiveMatch(
        channel: _mockChannel(201, 'beIN Sports 1 Premium'),
        programTitle: 'Ipswich vs Liverpool',
        teams: [liverpool],
        fixture: LiveFixture(
          homeName: 'Ipswich Town',
          awayName: 'Liverpool',
          teams: [liverpool],
          league: 'Premier League',
        ),
      );
      expect(
        MatchWallpaperResolver.resolveWallpaper(matchEnglishPl),
        'assets/images/pl.jpg',
      );

      // Arabic league name from Yallakora scraper
      final matchArabicPl = LiveMatch(
        channel: _mockChannel(202, 'beIN Sports 2 HD'),
        programTitle: 'مباراة مانشستر سيتي وأرسنال',
        teams: [manCity, arsenal],
        fixture: LiveFixture(
          homeName: 'مانشستر سيتي',
          awayName: 'أرسنال',
          teams: [manCity, arsenal],
          league: 'الدوري الإنجليزي',
        ),
      );
      expect(
        MatchWallpaperResolver.resolveWallpaper(matchArabicPl),
        'assets/images/pl.jpg',
      );
    });

    test('resolves UCL wallpaper (ucl1, ucl2, ucl3) for filtered teams in Champions League', () {
      final uclMatch1 = LiveMatch(
        channel: _mockChannel(301, 'beIN Sports 1 HD'),
        programTitle: 'Man City vs Bayern Munich',
        teams: [manCity],
        fixture: LiveFixture(
          homeName: 'Manchester City',
          awayName: 'Bayern Munich',
          teams: [manCity],
          league: 'UEFA Champions League',
        ),
      );

      final wallpaper1 = MatchWallpaperResolver.resolveWallpaper(uclMatch1);
      expect(wallpaper1, isNotNull);
      expect(MatchWallpaperResolver.uclWallpapers, contains(wallpaper1));

      // Arabic Champions League name
      final uclMatch2 = LiveMatch(
        channel: _mockChannel(302, 'beIN Sports 2 HD'),
        programTitle: 'أرسنال ضد باريس سان جيرمان',
        teams: [arsenal],
        fixture: LiveFixture(
          homeName: 'أرسنال',
          awayName: 'باريس سان جيرمان',
          teams: [arsenal],
          league: 'دوري أبطال أوروبا',
        ),
      );

      final wallpaper2 = MatchWallpaperResolver.resolveWallpaper(uclMatch2);
      expect(wallpaper2, isNotNull);
      expect(MatchWallpaperResolver.uclWallpapers, contains(wallpaper2));
    });

    test('deterministic UCL wallpaper selection stays consistent across rebuilds', () {
      final match = LiveMatch(
        channel: _mockChannel(305, 'beIN Sports 1 HD'),
        programTitle: 'Arsenal vs Inter',
        teams: [arsenal],
        fixture: LiveFixture(
          homeName: 'Arsenal',
          awayName: 'Inter',
          teams: [arsenal],
          league: 'Champions League',
        ),
      );

      final first = MatchWallpaperResolver.resolveWallpaper(match);
      final second = MatchWallpaperResolver.resolveWallpaper(match);
      final third = MatchWallpaperResolver.resolveWallpaper(match);
      expect(first, equals(second));
      expect(second, equals(third));
    });

    test('does not treat African or Asian Champions League as UCL', () {
      final cafMatch = LiveMatch(
        channel: _mockChannel(401, 'ON Sport'),
        programTitle: 'AS Port vs Simba',
        teams: const [],
        fixture: const LiveFixture(
          homeName: 'AS Port',
          awayName: 'Simba',
          teams: [],
          league: 'دوري أبطال أفريقيا',
        ),
      );

      expect(MatchWallpaperResolver.resolveWallpaper(cafMatch), isNull);
    });

    test('returns null for unhandled leagues / non-filtered matches', () {
      final saudiMatch = LiveMatch(
        channel: _mockChannel(501, 'SSC 1'),
        programTitle: 'Al Hilal vs Al Nassr',
        teams: const [],
        fixture: const LiveFixture(
          homeName: 'Al Hilal',
          awayName: 'Al Nassr',
          teams: [],
          league: 'الدوري السعودي',
        ),
      );

      expect(MatchWallpaperResolver.resolveWallpaper(saudiMatch), isNull);
    });

    test('resolves ahly.jpg for Al Ahly match (Arabic & English)', () {
      final ahly = BigMatchDetector.teamsIn('Al Ahly').first;
      final match1 = LiveMatch(
        channel: _mockChannel(110, 'ON Sport 1'),
        programTitle: 'Al Ahly vs Pyramids',
        teams: [ahly],
        fixture: LiveFixture(
          homeName: 'Al Ahly',
          awayName: 'Pyramids',
          teams: [ahly],
          league: 'الدوري المصري',
        ),
      );
      expect(
        MatchWallpaperResolver.resolveWallpaper(match1),
        MatchWallpaperResolver.ahlyWallpaper,
      );
      expect(
        MatchWallpaperResolver.resolveWallpaper(match1),
        'assets/images/ahly.jpg',
      );

      final match2 = LiveMatch(
        channel: _mockChannel(111, 'ON Sport 1'),
        programTitle: 'مباراة الأهلي والترجي',
        teams: const [],
        fixture: const LiveFixture(
          homeName: 'الأهلي',
          awayName: 'الترجي',
          teams: [],
          league: 'دوري أبطال أفريقيا',
        ),
      );
      expect(
        MatchWallpaperResolver.resolveWallpaper(match2),
        'assets/images/ahly.jpg',
      );
    });

    test('resolves zamalek.jpg for Zamalek match (Arabic & English)', () {
      final zamalek = BigMatchDetector.teamsIn('Zamalek').first;
      final match1 = LiveMatch(
        channel: _mockChannel(112, 'ON Sport 2'),
        programTitle: 'Zamalek vs Smouha',
        teams: [zamalek],
        fixture: LiveFixture(
          homeName: 'Zamalek',
          awayName: 'Smouha',
          teams: [zamalek],
          league: 'الدوري المصري',
        ),
      );
      expect(
        MatchWallpaperResolver.resolveWallpaper(match1),
        MatchWallpaperResolver.zamalekWallpaper,
      );
      expect(
        MatchWallpaperResolver.resolveWallpaper(match1),
        'assets/images/zamalek.jpg',
      );

      // Exact Yallakora matches.json fixture
      final model = MatchModel.fromJson(const {
        'league': 'دوري أبطال أفريقيا',
        'team_home': 'إيه أس بورت',
        'team_away': 'الزمالك',
        'time': '20:00',
        'status': 'لم تبدأ',
        'channel': 'ON Sport',
      });
      final fixture = model.toLiveFixture();
      final match2 = LiveMatch(
        channel: _mockChannel(113, 'ON Sport'),
        programTitle: fixture.headline,
        teams: fixture.teams,
        fixture: fixture,
      );
      expect(
        MatchWallpaperResolver.resolveWallpaper(match2),
        'assets/images/zamalek.jpg',
      );
    });

    test('resolves home team wallpaper for Al Ahly vs Zamalek Derby', () {
      final ahlyHome = LiveMatch(
        channel: _mockChannel(114, 'ON Sport'),
        programTitle: 'El Qimma',
        teams: const [],
        fixture: const LiveFixture(
          homeName: 'الأهلي',
          awayName: 'الزمالك',
          teams: [],
          league: 'الدوري المصري',
        ),
      );
      expect(
        MatchWallpaperResolver.resolveWallpaper(ahlyHome),
        'assets/images/ahly.jpg',
      );

      final zamalekHome = LiveMatch(
        channel: _mockChannel(115, 'ON Sport'),
        programTitle: 'El Qimma',
        teams: const [],
        fixture: const LiveFixture(
          homeName: 'الزمالك',
          awayName: 'الأهلي',
          teams: [],
          league: 'الدوري المصري',
        ),
      );
      expect(
        MatchWallpaperResolver.resolveWallpaper(zamalekHome),
        'assets/images/zamalek.jpg',
      );
    });

    testWidgets('all wallpaper image files exist and can be loaded via rootBundle', (tester) async {
      final assetsToTest = [
        'assets/images/fcb.jpg',
        'assets/images/rm.jpg',
        'assets/images/ahly.jpg',
        'assets/images/zamalek.jpg',
        'assets/images/pl.jpg',
        'assets/images/ucl1.jpg',
        'assets/images/ucl2.jpg',
        'assets/images/ucl3.jpg',
      ];

      for (final asset in assetsToTest) {
        final data = await rootBundle.load(asset);
        expect(data.lengthInBytes, greaterThan(0), reason: '$asset should have non-zero size');
      }
    });
  });
}
