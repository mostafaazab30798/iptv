import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/domain/entities/category.dart';
import 'package:iptv/features/catalog_filter/excluded_live_categories_policy.dart';

void main() {
  const policy = ExcludedLiveCategoriesPolicy();

  Category live(String name) =>
      Category(id: 1, serverId: 1, type: CategoryType.live, name: name);

  group('ExcludedLiveCategoriesPolicy', () {
    test('excludes real provider country packages', () {
      const names = [
        'FRANCE Tv',
        ' FRANCE | LIGUE 1+',
        'FRANCE SPORTS Tv',
        'FRANCE A LA CARTE Tv',
        'ITALY Tv',
        'ITALY BK Tv',
        'GERMANY Tv',
        'ESPAN Tv',
        'ESPAN BK Tv',
        'POLAND Tv',
        'EXYU Tv',
        'ENGLAND Tv',
        'ENGLAND Tv|BK',
        'PORTUGUEL Tv',
        'TURKEY Tv',
        'TURKEY SPORTS Tv',
        'NEDERLAND Tv',
        'AMOS Tv',
        'CANADA Tv',
        'USA Tv',
        'USA Tv |BACK UP|',
        'BRAZIL Tv',
        'GREECE Tv',
        'ROMANIA Tv',
        'ALBANIA Tv',
        'RUSSIAN TV',
        'RU|Okko Sport',
        'INDIA Tv',
        'IRAN Tv',
        'KURDISH Tv',
        'CHRISTIAN Tv',
      ];
      for (final name in names) {
        expect(policy.isExcluded(live(name)), isTrue, reason: name);
      }
    });

    test('keeps middle-east and beIN regional categories', () {
      const names = [
        'ARABIC Tv',
        'EGYPT Tv',
        'EGYPT BK Tv',
        'KIDS Tv',
        'ISLAMIC Tv',
        'beIN SPORTS FRANCE',
        'beIN SPORTS TURKEY',
        'beIN SPORTS ESPAN',
        'beIN SPORTS HD',
        'SAUDIA Tv',
        'Turkish 24/7',
      ];
      for (final name in names) {
        expect(policy.isExcluded(live(name)), isFalse, reason: name);
      }
    });
  });
}
