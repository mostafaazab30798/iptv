import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/core/logos/bein/bein_logo_normalizer.dart';

void main() {
  group('BeinLogoNormalizer', () {
    test('Exact match and normalization', () {
      expect(BeinLogoNormalizer.normalize('beIN Sports 1'), 'bein_sports_1');
      expect(BeinLogoNormalizer.normalize('beIN Sports 2'), 'bein_sports_2');
      expect(BeinLogoNormalizer.normalize('beIN Sports 7'), 'bein_sports_7');
      expect(BeinLogoNormalizer.normalize('beIN Sports'), 'bein_sports');
    });

    test('Case insensitivity', () {
      expect(BeinLogoNormalizer.normalize('BEIN SPORTS 1'), 'bein_sports_1');
      expect(BeinLogoNormalizer.normalize('bein sport 1'), 'bein_sports_1');
      expect(BeinLogoNormalizer.normalize('BeIN Sport 3'), 'bein_sports_3');
    });

    test('Safely strips presentation and quality tags (HD, FHD, 1080p, etc.)', () {
      expect(BeinLogoNormalizer.normalize('beIN Sports 1 HD'), 'bein_sports_1');
      expect(BeinLogoNormalizer.normalize('beIN Sports 1 FHD'), 'bein_sports_1');
      expect(BeinLogoNormalizer.normalize('beIN Sports 1 UHD'), 'bein_sports_1');
      expect(BeinLogoNormalizer.normalize('beIN Sports 1 1080p 50fps'), 'bein_sports_1');
      expect(BeinLogoNormalizer.normalize('|AR| beIN SPORTS 2 HD [HEVC]'), 'bein_sports_2');
      expect(BeinLogoNormalizer.normalize('beIN Sports 4K'), 'bein_sports_4k');
    });

    test('Arabic aliases and numerals', () {
      expect(BeinLogoNormalizer.normalize('بي إن سبورت 1'), 'bein_sports_1');
      expect(BeinLogoNormalizer.normalize('بي ان سبورت 1'), 'bein_sports_1');
      expect(BeinLogoNormalizer.normalize('بين سبورت 1'), 'bein_sports_1');
      expect(BeinLogoNormalizer.normalize('بي ان سبورتس ١'), 'bein_sports_1');
      expect(BeinLogoNormalizer.normalize('بي ان سبورت ٢'), 'bein_sports_2');
      expect(BeinLogoNormalizer.normalize('بي ان سبورت الإخبارية'), 'bein_sports_news');
      expect(BeinLogoNormalizer.normalize('بي ان سبورت الاخبارية'), 'bein_sports_news');
      expect(BeinLogoNormalizer.normalize('بي ان سبورت 1 بريميوم'), 'bein_sports_1_premium');
      expect(BeinLogoNormalizer.normalize('بي ان سبورت 2 ماكس'), 'bein_sports_2_max');
      expect(BeinLogoNormalizer.normalize('بي ان سبورت 1 اكسترا'), 'bein_sports_1_xtra');
      expect(BeinLogoNormalizer.normalize('بي ان سبورت 1 انجليزي'), 'bein_sports_1_english');
      expect(BeinLogoNormalizer.normalize('بي ان سبورت 1 فرنسي'), 'bein_sports_1_french');
      expect(BeinLogoNormalizer.normalize('بي ان سبورت فور كي'), 'bein_sports_4k');
    });

    test('Token safety and number isolation', () {
      // 1 should never match 10, 1 Max, or 1 Premium
      final r1 = BeinLogoNormalizer.normalize('beIN Sports 1');
      final r10 = BeinLogoNormalizer.normalize('beIN Sports 10');
      final r1Max = BeinLogoNormalizer.normalize('beIN Sports 1 Max');
      final r1Prem = BeinLogoNormalizer.normalize('beIN Sports 1 Premium');

      expect(r1, 'bein_sports_1');
      expect(r10, isNot(equals(r1)));
      expect(r1Max, 'bein_sports_1_max');
      expect(r1Prem, 'bein_sports_1_premium');
      expect(r1Max, isNot(equals(r1)));
      expect(r1Prem, isNot(equals(r1)));
    });

    test('Special channel sub-brands', () {
      expect(BeinLogoNormalizer.normalize('beIN Sports News'), 'bein_sports_news');
      expect(BeinLogoNormalizer.normalize('beIN Sports NBA'), 'bein_sports_nba');
      expect(BeinLogoNormalizer.normalize('beIN Sports 1 Max'), 'bein_sports_1_max');
      expect(BeinLogoNormalizer.normalize('beIN Sports 2 Max'), 'bein_sports_2_max');
      expect(BeinLogoNormalizer.normalize('beIN Sports 1 Premium'), 'bein_sports_1_premium');
      expect(BeinLogoNormalizer.normalize('beIN Sports 1 Xtra'), 'bein_sports_1_xtra');
      expect(BeinLogoNormalizer.normalize('beIN Sports 1 English'), 'bein_sports_1_english');
      expect(BeinLogoNormalizer.normalize('beIN Sports 1 French'), 'bein_sports_1_french');
    });

    test('Non-beIN and unknown channels return null', () {
      expect(BeinLogoNormalizer.normalize('Sky Sports Premier League'), isNull);
      expect(BeinLogoNormalizer.normalize('BBC One HD'), isNull);
      expect(BeinLogoNormalizer.normalize('Canal+ Sport'), isNull);
      expect(BeinLogoNormalizer.normalize(''), isNull);
      expect(BeinLogoNormalizer.normalize(null), isNull);
    });
  });
}
