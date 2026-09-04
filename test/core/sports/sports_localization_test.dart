import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/core/sports/sports_localization.dart';

void main() {
  group('SportsLocalization - Teams', () {
    test('localizes top European teams from Arabic to English', () {
      expect(
        SportsLocalization.localizeTeam('ريال مدريد', isArabic: false),
        'Real Madrid',
      );
      expect(
        SportsLocalization.localizeTeam('برشلونة', isArabic: false),
        'Barcelona',
      );
      expect(
        SportsLocalization.localizeTeam('ريال بيتيس', isArabic: false),
        'Real Betis',
      );
      expect(
        SportsLocalization.localizeTeam('ليفربول', isArabic: false),
        'Liverpool',
      );
      expect(
        SportsLocalization.localizeTeam('إيبسويتش تاون', isArabic: false),
        'Ipswich Town',
      );
      expect(
        SportsLocalization.localizeTeam('باريس سان جيرمان', isArabic: false),
        'Paris Saint-Germain',
      );
      expect(
        SportsLocalization.localizeTeam('مانشستر سيتي', isArabic: false),
        'Manchester City',
      );
      expect(
        SportsLocalization.localizeTeam('أرسنال', isArabic: false),
        'Arsenal',
      );
      expect(
        SportsLocalization.localizeTeam('بايرن ميونخ', isArabic: false),
        'Bayern Munich',
      );
      expect(
        SportsLocalization.localizeTeam('إنتر ميلان', isArabic: false),
        'Inter Milan',
      );
      expect(
        SportsLocalization.localizeTeam('يوفنتوس', isArabic: false),
        'Juventus',
      );
    });

    test('handles tatweel, diacritics, and invisible characters', () {
      expect(
        SportsLocalization.localizeTeam('الاتفـــــاق', isArabic: false),
        'Al Ettifaq',
      );
      expect(
        SportsLocalization.localizeTeam('طنطا\u200f', isArabic: false),
        'Tanta',
      );
      expect(
        SportsLocalization.localizeTeam('أهلي جدة', isArabic: false),
        'Al Ahli',
      );
      expect(
        SportsLocalization.localizeTeam('إيه أس بورت', isArabic: false),
        'AS Port',
      );
      expect(
        SportsLocalization.localizeTeam('الإسماعيلي', isArabic: false),
        'Ismaily',
      );
    });

    test('preserves original team name when interface is in Arabic', () {
      expect(
        SportsLocalization.localizeTeam('ريال مدريد', isArabic: true),
        'ريال مدريد',
      );
      expect(
        SportsLocalization.localizeTeam('برشلونة', isArabic: true),
        'برشلونة',
      );
      expect(
        SportsLocalization.localizeTeam('Real Madrid', isArabic: true),
        'ريال مدريد',
      );
      expect(
        SportsLocalization.localizeTeam('Barcelona', isArabic: true),
        'برشلونة',
      );
    });
  });

  group('SportsLocalization - Channels', () {
    test('localizes Arabic beIN and sports channel names to English', () {
      expect(
        SportsLocalization.localizeChannel('بى ان سبورت 1HD', isArabic: false),
        'beIN Sports 1 HD',
      );
      expect(
        SportsLocalization.localizeChannel('بى ان سبورت 3 HD', isArabic: false),
        'beIN Sports 3 HD',
      );
      expect(
        SportsLocalization.localizeChannel('بي ان سبورت 2', isArabic: false),
        'beIN Sports 2',
      );
      expect(
        SportsLocalization.localizeChannel('أبوظبي الرياضية - HD1', isArabic: false),
        'AD Sports 1 HD',
      );
      expect(
        SportsLocalization.localizeChannel('ثمانية 1', isArabic: false),
        'Thmanyah 1',
      );
    });

    test('cleans provider language tags on English side', () {
      expect(
        SportsLocalization.localizeChannel('AR | BEIN SPORTS 1 FHD', isArabic: false),
        'BEIN SPORTS 1 FHD',
      );
      expect(
        SportsLocalization.localizeChannel('|AR| BEIN SPORTS 2 HD', isArabic: false),
        'BEIN SPORTS 2 HD',
      );
    });

    test('preserves Arabic channel name when interface is in Arabic', () {
      expect(
        SportsLocalization.localizeChannel('بى ان سبورت 3 HD', isArabic: true),
        'بى ان سبورت 3 HD',
      );
    });
  });

  group('SportsLocalization - Leagues', () {
    test('localizes competition names from Arabic to English', () {
      expect(
        SportsLocalization.localizeLeague('الدوري الإسباني', isArabic: false),
        'La Liga',
      );
      expect(
        SportsLocalization.localizeLeague('الدوري الإنجليزي', isArabic: false),
        'Premier League',
      );
      expect(
        SportsLocalization.localizeLeague('دوري أبطال أوروبا', isArabic: false),
        'UEFA Champions League',
      );
      expect(
        SportsLocalization.localizeLeague('الدوري الإيطالي', isArabic: false),
        'Serie A',
      );
      expect(
        SportsLocalization.localizeLeague('الدوري الألماني', isArabic: false),
        'Bundesliga',
      );
      expect(
        SportsLocalization.localizeLeague('الدوري الفرنسي', isArabic: false),
        'Ligue 1',
      );
      expect(
        SportsLocalization.localizeLeague('دوري أبطال أفريقيا', isArabic: false),
        'CAF Champions League',
      );
      expect(
        SportsLocalization.localizeLeague('دوري القسم الثاني-أ', isArabic: false),
        'Egyptian Second Division',
      );
    });

    test('preserves Arabic league name when interface is in Arabic', () {
      expect(
        SportsLocalization.localizeLeague('الدوري الإسباني', isArabic: true),
        'الدوري الإسباني',
      );
    });
  });
}
