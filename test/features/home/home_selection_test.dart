import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/domain/entities/favorite.dart';
import 'package:iptv/domain/entities/movie.dart';
import 'package:iptv/domain/entities/series.dart';
import 'package:iptv/domain/entities/watch_history.dart';
import 'package:iptv/domain/repositories/favorites_repository.dart';
import 'package:iptv/domain/repositories/history_repository.dart';
import 'package:iptv/features/home/home_controller.dart';
import 'package:iptv/core/utils/result.dart';
import 'package:iptv/shared/widgets/favorite_toggle_button.dart';

import '../catalog/fake_catalog_repos.dart';

class _FakeFavoritesRepository implements FavoritesRepository {
  @override
  Future<Result<List<Favorite>>> getFavorites({FavoriteType? type}) async =>
      const Ok([]);

  @override
  Future<bool> isFavorite({
    required FavoriteType type,
    required int itemId,
  }) async =>
      false;

  @override
  Future<Result<void>> addFavorite(Favorite favorite) async => const Ok(null);

  @override
  Future<Result<void>> removeFavorite(int favoriteId) async => const Ok(null);

  @override
  Future<Result<void>> removeFavoriteByItemId({
    required FavoriteType type,
    required int itemId,
  }) async =>
      const Ok(null);
}

class _FakeHistoryRepository implements HistoryRepository {
  @override
  Future<Result<List<WatchHistoryEntry>>> getHistory({
    int limit = HistoryRepository.maxHistoryLimit,
  }) async =>
      const Ok([]);

  @override
  Future<Result<WatchHistoryEntry?>> getEntry({
    required WatchHistoryType type,
    required int itemId,
  }) async =>
      const Ok(null);

  @override
  Future<Result<void>> recordWatch(WatchHistoryEntry entry) async =>
      const Ok(null);

  @override
  Future<Result<void>> updatePosition({
    required WatchHistoryType type,
    required int itemId,
    required int positionSecs,
    int? durationSecs,
  }) async =>
      const Ok(null);

  @override
  Future<Result<void>> clearHistory() async => const Ok(null);

  @override
  Future<Result<void>> deleteEntry(int id) async => const Ok(null);
}

void main() {
  group('PosterTopActions rating badge', () {
    Widget buildWidget(String? rating) {
      return MaterialApp(
        home: Scaffold(
          body: PosterTopActions(rating: rating),
        ),
      );
    }

    testWidgets('renders star icon and rating text when rating is valid',
        (tester) async {
      await tester.pumpWidget(buildWidget('8.7'));
      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
      expect(find.text('8.7'), findsOneWidget);
    });

    testWidgets('hides badge when rating is 0, 0.0, empty or null',
        (tester) async {
      await tester.pumpWidget(buildWidget('0'));
      expect(find.byIcon(Icons.star_rounded), findsNothing);

      await tester.pumpWidget(buildWidget('0.0'));
      expect(find.byIcon(Icons.star_rounded), findsNothing);

      await tester.pumpWidget(buildWidget(''));
      expect(find.byIcon(Icons.star_rounded), findsNothing);

      await tester.pumpWidget(buildWidget(null));
      expect(find.byIcon(Icons.star_rounded), findsNothing);
    });
  });

  group('HomeController featured and popular content selection', () {
    test('featuredMovies excludes 0-star / unrated movies and orders by rating',
        () async {
      final movies = [
        const Movie(
          id: 1,
          serverId: 1,
          streamId: 1,
          name: 'Zero Star Movie A',
          rating: null,
          releaseYear: 2024,
        ),
        const Movie(
          id: 2,
          serverId: 1,
          streamId: 2,
          name: 'Zero Star Movie B',
          rating: '0',
          releaseYear: 2023,
        ),
        const Movie(
          id: 3,
          serverId: 1,
          streamId: 3,
          name: 'High Rated Movie',
          rating: '9.2',
          releaseYear: 2022,
        ),
        const Movie(
          id: 4,
          serverId: 1,
          streamId: 4,
          name: 'Medium Rated Movie',
          rating: '8.4',
          releaseYear: 2023,
        ),
        const Movie(
          id: 5,
          serverId: 1,
          streamId: 5,
          name: 'Recent Top Movie',
          rating: '9.1',
          releaseYear: 2024,
        ),
      ];

      final liveRepo = FakeLiveRepository();
      final vodRepo = FakeVodRepository(movies: movies);
      final seriesRepo = FakeSeriesRepository();
      final favRepo = _FakeFavoritesRepository();
      final histRepo = _FakeHistoryRepository();

      final controller = HomeController(
        liveRepo: liveRepo,
        vodRepo: vodRepo,
        seriesRepo: seriesRepo,
        favoritesRepo: favRepo,
        historyRepo: histRepo,
      );

      // Wait for loadData()
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final featured = controller.state.featuredMovies;
      expect(featured.isNotEmpty, isTrue);

      // The top 3 should be the rated movies
      final top3Names = featured.take(3).map((m) => m.name).toList();
      expect(top3Names, contains('High Rated Movie'));
      expect(top3Names, contains('Recent Top Movie'));
      expect(top3Names, contains('Medium Rated Movie'));

      // 0-star movies should not precede rated movies
      expect(featured.first.rating, isNotNull);
      expect(double.parse(featured.first.rating!), greaterThan(8.0));

      controller.dispose();
    });

    test('popularSeries excludes 0-star / unrated series and orders by rating',
        () async {
      final series = [
        const Series(
          id: 1,
          serverId: 1,
          seriesId: 1,
          name: 'Unrated Series',
          rating: null,
          releaseYear: 2024,
        ),
        const Series(
          id: 2,
          serverId: 1,
          seriesId: 2,
          name: 'Zero Star Series',
          rating: '0',
          releaseYear: 2023,
        ),
        const Series(
          id: 3,
          serverId: 1,
          seriesId: 3,
          name: 'Top Rated Series',
          rating: '9.5',
          releaseYear: 2021,
        ),
        const Series(
          id: 4,
          serverId: 1,
          seriesId: 4,
          name: 'Hit Series',
          rating: '8.8',
          releaseYear: 2024,
        ),
      ];

      final liveRepo = FakeLiveRepository();
      final vodRepo = FakeVodRepository();
      final seriesRepo = FakeSeriesRepository(series: series);
      final favRepo = _FakeFavoritesRepository();
      final histRepo = _FakeHistoryRepository();

      final controller = HomeController(
        liveRepo: liveRepo,
        vodRepo: vodRepo,
        seriesRepo: seriesRepo,
        favoritesRepo: favRepo,
        historyRepo: histRepo,
      );

      // Wait for loadData()
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final popular = controller.state.popularSeries;
      expect(popular.isNotEmpty, isTrue);

      // Top items should be the rated series
      final top2Names = popular.take(2).map((s) => s.name).toList();
      expect(top2Names, contains('Top Rated Series'));
      expect(top2Names, contains('Hit Series'));

      expect(popular.first.rating, isNotNull);
      expect(double.parse(popular.first.rating!), greaterThan(8.0));

      controller.dispose();
    });
  });
}
