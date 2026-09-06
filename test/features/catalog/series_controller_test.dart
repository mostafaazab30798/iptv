import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/core/utils/result.dart';
import 'package:iptv/features/series/series_controller.dart';

import 'fake_catalog_repos.dart';

void main() {
  group('SeriesController', () {
    test('loadData populates hub counts and leading covers', () async {
      final repo = FakeSeriesRepository(
        categories: [seriesCategory(7, 'Drama')],
        series: [
          seriesItem(seriesId: 1, name: 'S1', categoryId: 7, cover: 'c.png'),
          seriesItem(seriesId: 2, name: 'S2', categoryId: 7),
          seriesItem(seriesId: 3, name: 'S3', categoryId: 8),
        ],
      );
      final controller = SeriesController(repo);
      addTearDown(controller.dispose);

      await controller.loadData();

      expect(controller.state.isLoading, isFalse);
      expect(controller.state.categories, hasLength(1));
      expect(controller.state.filteredSeries, isEmpty);
      expect(controller.state.totalSeriesCount, 3);
      expect(controller.state.categoryCounts[7], 2);
      expect(controller.state.categoryLeadingCovers[7], 'c.png');
      expect(controller.state.seriesList, isEmpty);
    });

    test('selectCategory / showAll / hub navigation', () async {
      final repo = FakeSeriesRepository(
        categories: [seriesCategory(7, 'Drama')],
        series: [
          seriesItem(seriesId: 1, name: 'S1', categoryId: 7),
          seriesItem(seriesId: 2, name: 'S2', categoryId: 8),
        ],
      );
      final controller = SeriesController(repo);
      addTearDown(controller.dispose);
      await controller.loadData();

      await controller.selectCategory(7);
      expect(controller.state.selectedCategoryId, 7);
      expect(controller.state.filteredSeries.map((s) => s.seriesId), [1]);

      controller.showAllSeries();
      expect(controller.state.selectedCategoryId, isNull);
      expect(controller.state.filteredSeries, hasLength(2));

      controller.showCategoriesHub();
      expect(controller.state.filteredSeries, isEmpty);
    });

    test('search filters series by name', () async {
      final repo = FakeSeriesRepository(
        categories: [seriesCategory(7, 'Drama')],
        series: [
          seriesItem(seriesId: 1, name: 'Breaking Bad', categoryId: 7),
          seriesItem(seriesId: 2, name: 'Better Call Saul', categoryId: 7),
        ],
      );
      final controller = SeriesController(repo);
      addTearDown(controller.dispose);
      await controller.loadData();
      controller.showAllSeries();

      controller.search('breaking');
      await Future<void>.delayed(const Duration(milliseconds: 350));

      expect(controller.state.filteredSeries.map((s) => s.seriesId), [1]);
    });

    test('thrown errors set state.error', () async {
      final repo = FakeSeriesRepository(throwOnSeries: true);
      final controller = SeriesController(repo);
      addTearDown(controller.dispose);

      await controller.loadData();

      expect(controller.state.error, contains('series failed'));
      expect(controller.state.isLoading, isFalse);
    });

    test('Result.Err surfaces on state.error', () async {
      final repo = FakeSeriesRepository(
        categoriesError: const AppResultError('down'),
        seriesError: const AppResultError('down'),
      );
      final controller = SeriesController(repo);
      addTearDown(controller.dispose);

      await controller.loadData();

      expect(controller.state.categories, isEmpty);
      expect(controller.state.error, 'down');
    });
  });
}
