import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/domain/entities/category.dart';
import 'package:iptv/features/kids_mode/kids_content_policy.dart';

void main() {
  const policy = KidsContentPolicy();

  Category category(String name, CategoryType type) =>
      Category(id: 1, serverId: 1, type: type, name: name);

  group('KidsContentPolicy categories', () {
    test('allows kid-oriented movie categories in English and Arabic', () {
      expect(
        policy.allowsCategory(category('ANIME | HD', CategoryType.vod)),
        isTrue,
      );
      expect(
        policy.allowsCategory(category('أفلام أطفال', CategoryType.vod)),
        isTrue,
      );
      expect(
        policy.allowsCategory(category('Cartoons', CategoryType.vod)),
        isTrue,
      );
    });

    test('allows courses only for series', () {
      expect(
        policy.allowsCategory(category('English Courses', CategoryType.series)),
        isTrue,
      );
      expect(
        policy.allowsCategory(category('دورات تعليمية', CategoryType.series)),
        isTrue,
      );
      expect(
        policy.allowsCategory(category('English Courses', CategoryType.vod)),
        isFalse,
      );
    });

    test('deny terms override kid terms', () {
      expect(
        policy.allowsCategory(
          category('Adult Animation 18+', CategoryType.vod),
        ),
        isFalse,
      );
      expect(
        policy.allowsCategory(category('كرتون للكبار', CategoryType.series)),
        isFalse,
      );
    });

    test('does not use unsafe partial-word matches', () {
      expect(
        policy.allowsCategory(category('Nicole Kidman', CategoryType.vod)),
        isFalse,
      );
    });
  });

  group('KidsContentPolicy live channels', () {
    test('allows curated names with common suffixes', () {
      expect(policy.allowsLiveChannelName('US | Cartoon Network FHD'), isTrue);
      expect(policy.allowsLiveChannelName('AR: سبيستون HD'), isTrue);
      expect(policy.allowsLiveChannelName('Disney Junior 4K'), isTrue);
      expect(policy.allowsLiveChannelName('beIN Junior HD'), isTrue);
    });

    test('blocks unrelated and adult channels', () {
      expect(policy.allowsLiveChannelName('BBC World News'), isFalse);
      expect(policy.allowsLiveChannelName('Adult Cartoon Network'), isFalse);
    });
  });
}
