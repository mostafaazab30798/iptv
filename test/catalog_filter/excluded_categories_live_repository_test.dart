import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/core/utils/result.dart';
import 'package:iptv/domain/entities/category.dart';
import 'package:iptv/domain/entities/channel.dart';
import 'package:iptv/domain/repositories/live_repository.dart';
import 'package:iptv/features/catalog_filter/excluded_categories_live_repository.dart';
import 'package:iptv/features/catalog_filter/excluded_live_categories_policy.dart';

void main() {
  const policy = ExcludedLiveCategoriesPolicy();

  test('hides excluded categories and their channels', () async {
    final repository = ExcludedCategoriesLiveRepository(
      _FakeLiveRepository(),
      policy,
    );

    expect((await repository.getCategories()).value.map((e) => e.name), [
      'ARABIC',
      'BEIN SPORTS',
    ]);
    expect((await repository.getChannels()).value.map((e) => e.name), [
      'MBC 1',
      'beIN Sports 1',
    ]);
    expect((await repository.getChannels(categoryId: 2)).value, isEmpty);
    expect((await repository.getChannelById(20)).isErr, isTrue);
    expect((await repository.getChannelById(10)).isOk, isTrue);
  });
}

class _FakeLiveRepository implements LiveRepository {
  static const categories = [
    Category(id: 1, serverId: 1, type: CategoryType.live, name: 'ARABIC'),
    Category(id: 2, serverId: 2, type: CategoryType.live, name: 'USA TV'),
    Category(id: 3, serverId: 3, type: CategoryType.live, name: 'BEIN SPORTS'),
    Category(
      id: 4,
      serverId: 4,
      type: CategoryType.live,
      name: 'ENGLAND TV|BK',
    ),
  ];

  static const channels = [
    Channel(
      id: 10,
      serverId: 1,
      streamId: 10,
      name: 'MBC 1',
      categoryId: 1,
    ),
    Channel(
      id: 20,
      serverId: 2,
      streamId: 20,
      name: 'CNN',
      categoryId: 2,
    ),
    Channel(
      id: 30,
      serverId: 3,
      streamId: 30,
      name: 'beIN Sports 1',
      categoryId: 3,
    ),
    Channel(
      id: 40,
      serverId: 4,
      streamId: 40,
      name: 'BBC One',
      categoryId: 4,
    ),
  ];

  @override
  Future<Result<List<Category>>> getCategories({
    bool forceRefresh = false,
  }) async => const Ok(categories);

  @override
  Future<Result<List<Channel>>> getChannels({
    int? categoryId,
    bool forceRefresh = false,
  }) async => Ok(
    categoryId == null
        ? channels
        : channels
              .where((channel) => channel.categoryId == categoryId)
              .toList(),
  );

  @override
  Future<Result<Channel>> getChannelById(int streamId) async =>
      Ok(channels.firstWhere((channel) => channel.streamId == streamId));
}
