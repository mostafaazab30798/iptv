import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/core/utils/result.dart';
import 'package:iptv/domain/entities/category.dart';
import 'package:iptv/domain/entities/channel.dart';
import 'package:iptv/domain/entities/movie.dart';
import 'package:iptv/domain/entities/season.dart';
import 'package:iptv/domain/entities/series.dart';
import 'package:iptv/domain/repositories/live_repository.dart';
import 'package:iptv/domain/repositories/series_repository.dart';
import 'package:iptv/domain/repositories/vod_repository.dart';
import 'package:iptv/features/kids_mode/kids_content_policy.dart';
import 'package:iptv/features/kids_mode/kids_filtered_repositories.dart';

const _policy = KidsContentPolicy();

void main() {
  test('VOD exposes only movies from matching categories', () async {
    final repository = KidsFilteredVodRepository(_FakeVodRepository(), _policy);

    expect((await repository.getCategories()).value.map((e) => e.name), [
      'Kids',
    ]);
    expect((await repository.getMovies()).value.map((e) => e.name), [
      'Safe Movie',
    ]);
    expect((await repository.getMovieById(20)).isErr, isTrue);
  });

  test(
    'series includes course categories and blocks other season lookups',
    () async {
      final repository = KidsFilteredSeriesRepository(
        _FakeSeriesRepository(),
        _policy,
      );

      expect((await repository.getSeries()).value.map((e) => e.name), ['Math']);
      expect((await repository.getSeasons(100)).isOk, isTrue);
      expect((await repository.getSeasons(200)).isErr, isTrue);
    },
  );

  test('live filters channels by name and removes empty categories', () async {
    final repository = KidsFilteredLiveRepository(
      _FakeLiveRepository(),
      _policy,
    );

    expect((await repository.getChannels()).value.map((e) => e.name), [
      'Cartoon Network HD',
    ]);
    expect((await repository.getCategories()).value.map((e) => e.name), [
      'Entertainment',
    ]);
    expect((await repository.getChannelById(2)).isErr, isTrue);
  });

  test('live also hides the same country packages as normal mode', () async {
    final repository = KidsFilteredLiveRepository(
      _FakeLiveRepositoryWithCountryPacks(),
      _policy,
    );

    expect((await repository.getCategories()).value.map((e) => e.name), [
      'KIDS Tv',
    ]);
    expect((await repository.getChannels()).value.map((e) => e.name), [
      'Spacetoon HD',
    ]);
    expect((await repository.getChannelById(20)).isErr, isTrue);
    expect((await repository.getChannels(categoryId: 2)).value, isEmpty);
  });
}

class _FakeVodRepository implements VodRepository {
  static const categories = [
    Category(id: 1, serverId: 1, type: CategoryType.vod, name: 'Kids'),
    Category(id: 2, serverId: 2, type: CategoryType.vod, name: 'Action'),
  ];
  static const movies = [
    Movie(id: 10, serverId: 1, streamId: 10, name: 'Safe Movie', categoryId: 1),
    Movie(
      id: 20,
      serverId: 2,
      streamId: 20,
      name: 'Other Movie',
      categoryId: 2,
    ),
  ];

  @override
  Future<Result<List<Category>>> getCategories({
    bool forceRefresh = false,
  }) async => const Ok(categories);

  @override
  Future<Result<List<Movie>>> getMovies({
    int? categoryId,
    bool forceRefresh = false,
  }) async => Ok(
    categoryId == null
        ? movies
        : movies.where((movie) => movie.categoryId == categoryId).toList(),
  );

  @override
  Future<Result<Movie>> getMovieById(int streamId) async =>
      Ok(movies.firstWhere((movie) => movie.streamId == streamId));
}

class _FakeSeriesRepository implements SeriesRepository {
  static const categories = [
    Category(id: 3, serverId: 3, type: CategoryType.series, name: 'Courses'),
    Category(id: 4, serverId: 4, type: CategoryType.series, name: 'Drama'),
  ];
  static const items = [
    Series(id: 100, serverId: 1, seriesId: 100, name: 'Math', categoryId: 3),
    Series(id: 200, serverId: 2, seriesId: 200, name: 'Drama', categoryId: 4),
  ];

  @override
  Future<Result<List<Category>>> getCategories({
    bool forceRefresh = false,
  }) async => const Ok(categories);

  @override
  Future<Result<List<Series>>> getSeries({
    int? categoryId,
    bool forceRefresh = false,
  }) async => Ok(
    categoryId == null
        ? items
        : items.where((series) => series.categoryId == categoryId).toList(),
  );

  @override
  Future<Result<List<Season>>> getSeasons(int seriesId) async => const Ok([]);
}

class _FakeLiveRepository implements LiveRepository {
  static const categories = [
    Category(
      id: 5,
      serverId: 5,
      type: CategoryType.live,
      name: 'Entertainment',
    ),
    Category(id: 6, serverId: 6, type: CategoryType.live, name: 'News'),
  ];
  static const channels = [
    Channel(
      id: 1,
      serverId: 1,
      streamId: 1,
      name: 'Cartoon Network HD',
      categoryId: 5,
    ),
    Channel(id: 2, serverId: 2, streamId: 2, name: 'BBC News', categoryId: 6),
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

class _FakeLiveRepositoryWithCountryPacks implements LiveRepository {
  static const categories = [
    Category(id: 1, serverId: 1, type: CategoryType.live, name: 'KIDS Tv'),
    Category(id: 2, serverId: 2, type: CategoryType.live, name: 'USA Tv'),
    Category(id: 3, serverId: 3, type: CategoryType.live, name: 'ENGLAND Tv'),
  ];
  static const channels = [
    Channel(
      id: 10,
      serverId: 1,
      streamId: 10,
      name: 'Spacetoon HD',
      categoryId: 1,
    ),
    Channel(
      id: 20,
      serverId: 2,
      streamId: 20,
      name: 'Cartoon Network HD',
      categoryId: 2,
    ),
    Channel(
      id: 30,
      serverId: 3,
      streamId: 30,
      name: 'Disney Junior HD',
      categoryId: 3,
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
