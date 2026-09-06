import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/core/utils/result.dart';
import 'package:iptv/features/movies/movies_controller.dart';

import 'fake_catalog_repos.dart';

void main() {
  group('MoviesController', () {
    test('loadData populates hub counts and leading logos', () async {
      final repo = FakeVodRepository(
        categories: [vodCategory(5, 'Action')],
        movies: [
          movie(streamId: 1, name: 'A', categoryId: 5, icon: 'a.png'),
          movie(streamId: 2, name: 'B', categoryId: 5),
          movie(streamId: 3, name: 'C', categoryId: 9),
        ],
      );
      final controller = MoviesController(repo);
      addTearDown(controller.dispose);

      await controller.loadData();

      expect(controller.state.isLoading, isFalse);
      expect(controller.state.categories, hasLength(1));
      expect(controller.state.filteredMovies, isEmpty);
      expect(controller.state.totalMovieCount, 3);
      expect(controller.state.categoryCounts[5], 2);
      expect(controller.state.categoryLeadingLogos[5], 'a.png');
      expect(controller.state.movies, isEmpty);
    });

    test('selectCategory / showAll / hub navigation', () async {
      final repo = FakeVodRepository(
        categories: [vodCategory(5, 'Action')],
        movies: [
          movie(streamId: 1, name: 'A', categoryId: 5),
          movie(streamId: 2, name: 'B', categoryId: 9),
        ],
      );
      final controller = MoviesController(repo);
      addTearDown(controller.dispose);
      await controller.loadData();

      await controller.selectCategory(5);
      expect(controller.state.selectedCategoryId, 5);
      expect(controller.state.filteredMovies.map((m) => m.streamId), [1]);

      controller.showAllMovies();
      expect(controller.state.selectedCategoryId, isNull);
      expect(controller.state.filteredMovies, hasLength(2));

      await controller.selectCategory(null);
      expect(controller.state.filteredMovies, isEmpty);
    });

    test('lazy-loads category when catalog empty for that id', () async {
      final repo = FakeVodRepository(
        categories: [vodCategory(5, 'Action')],
        movies: [],
      );
      final controller = MoviesController(repo);
      addTearDown(controller.dispose);
      await controller.loadData();
      expect(controller.state.totalMovieCount, 0);

      repo.movies = [movie(streamId: 9, name: 'Late', categoryId: 5)];
      await controller.selectCategory(5);

      expect(controller.state.filteredMovies.map((m) => m.streamId), [9]);
      expect(repo.lastMoviesCategoryId, 5);
      expect(controller.state.isLoading, isFalse);
    });

    test('search filters movies by name', () async {
      final repo = FakeVodRepository(
        categories: [vodCategory(5, 'Action')],
        movies: [
          movie(streamId: 1, name: 'Matrix', categoryId: 5),
          movie(streamId: 2, name: 'Inception', categoryId: 5),
        ],
      );
      final controller = MoviesController(repo);
      addTearDown(controller.dispose);
      await controller.loadData();
      controller.showAllMovies();

      controller.search('matrix');
      await Future<void>.delayed(const Duration(milliseconds: 350));

      expect(controller.state.filteredMovies.map((m) => m.streamId), [1]);
    });

    test('thrown errors set state.error', () async {
      final repo = FakeVodRepository(throwOnMovies: true);
      final controller = MoviesController(repo);
      addTearDown(controller.dispose);

      await controller.loadData();

      expect(controller.state.error, contains('movies failed'));
      expect(controller.state.isLoading, isFalse);
    });

    test('Result.Err surfaces on state.error', () async {
      final repo = FakeVodRepository(
        categoriesError: const AppResultError('down'),
        moviesError: const AppResultError('down'),
      );
      final controller = MoviesController(repo);
      addTearDown(controller.dispose);

      await controller.loadData();

      expect(controller.state.categories, isEmpty);
      expect(controller.state.error, 'down');
    });
  });
}
