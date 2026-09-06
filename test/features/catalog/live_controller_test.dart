import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/core/utils/result.dart';
import 'package:iptv/features/live/live_controller.dart';

import 'fake_catalog_repos.dart';

Future<void> _waitUntil(bool Function() predicate) async {
  for (var i = 0; i < 50; i++) {
    if (predicate()) return;
    await Future<void>.delayed(Duration.zero);
  }
  fail('condition not met in time');
}

void main() {
  group('LiveController', () {
    test('loadData populates categories hub without visible channels', () async {
      final repo = FakeLiveRepository(
        categories: [liveCategory(10, 'Sports')],
        channels: [
          channel(streamId: 1, name: 'BeIN 1', categoryId: 10, icon: 'a.png'),
          channel(streamId: 2, name: 'BeIN 2', categoryId: 10),
          channel(streamId: 3, name: 'News', categoryId: 20),
        ],
      );
      final controller = LiveController(repo);
      addTearDown(controller.dispose);

      await controller.loadData();

      expect(controller.state.isLoading, isFalse);
      expect(controller.state.error, isNull);
      expect(controller.state.categories, hasLength(1));
      expect(controller.state.filteredChannels, isEmpty);
      expect(controller.state.totalChannelCount, 3);
      expect(controller.state.categoryCounts[10], 2);
      expect(controller.state.categoryLeadingChannels[10]?.streamId, 1);
      expect(controller.state.categoryNames[10], 'Sports');
      expect(controller.catalog, hasLength(3));
    });

    test('selectCategory filters catalog; showAll and hub reset visibility',
        () async {
      final repo = FakeLiveRepository(
        categories: [liveCategory(10, 'Sports'), liveCategory(20, 'News')],
        channels: [
          channel(streamId: 1, name: 'BeIN 1', categoryId: 10),
          channel(streamId: 2, name: 'CNN', categoryId: 20),
        ],
      );
      final controller = LiveController(repo);
      addTearDown(controller.dispose);
      await controller.loadData();

      controller.selectCategory(10);
      expect(controller.state.selectedCategoryId, 10);
      expect(controller.state.filteredChannels.map((c) => c.streamId), [1]);

      controller.showAllChannels();
      expect(controller.state.selectedCategoryId, isNull);
      expect(controller.state.filteredChannels, hasLength(2));

      controller.showCategoriesHub();
      expect(controller.state.filteredChannels, isEmpty);
      expect(controller.state.selectedCategoryId, isNull);
    });

    test('search debounces and filters by name within selection', () async {
      final repo = FakeLiveRepository(
        categories: [liveCategory(10, 'Sports')],
        channels: [
          channel(streamId: 1, name: 'BeIN Sports 1', categoryId: 10),
          channel(streamId: 2, name: 'Premier League', categoryId: 10),
          channel(streamId: 3, name: 'News 24', categoryId: 20),
        ],
      );
      final controller = LiveController(repo);
      addTearDown(controller.dispose);
      await controller.loadData();
      controller.showAllChannels();

      controller.search('bein');
      await Future<void>.delayed(const Duration(milliseconds: 350));

      expect(controller.state.searchQuery, 'bein');
      expect(controller.state.filteredChannels.map((c) => c.streamId), [1]);
    });

    test('thrown repo errors surface on state.error', () async {
      final repo = FakeLiveRepository(throwOnCategories: true);
      final controller = LiveController(repo);
      addTearDown(controller.dispose);

      await controller.loadData();

      expect(controller.state.isLoading, isFalse);
      expect(controller.state.error, contains('categories failed'));
    });

    test('Result.Err surfaces on state.error with empty catalog', () async {
      final repo = FakeLiveRepository(
        categoriesError: const AppResultError('net down'),
        channelsError: const AppResultError('net down'),
      );
      final controller = LiveController(repo);
      addTearDown(controller.dispose);

      await controller.loadData();

      expect(controller.state.categories, isEmpty);
      expect(controller.state.error, 'net down');
    });

    test('skips reload when catalog already warm unless forceRefresh', () async {
      final repo = FakeLiveRepository(
        categories: [liveCategory(10, 'Sports')],
        channels: [channel(streamId: 1, name: 'A', categoryId: 10)],
      );
      final controller = LiveController(repo);
      addTearDown(controller.dispose);
      // Constructor kicks off loadData — wait for it before asserting.
      await _waitUntil(() => !controller.state.isLoading && controller.catalog.isNotEmpty);
      expect(repo.getCategoriesCalls, 1);

      await controller.loadData();
      expect(repo.getCategoriesCalls, 1);

      await controller.loadData(forceRefresh: true);
      expect(repo.getCategoriesCalls, 2);
    });

    test('null repo is a no-op', () async {
      final controller = LiveController(null);
      addTearDown(controller.dispose);
      await controller.loadData();
      expect(controller.state.categories, isEmpty);
      expect(controller.state.isLoading, isFalse);
    });
  });
}
