import 'package:iptv/core/utils/result.dart';
import 'package:iptv/domain/entities/category.dart';
import 'package:iptv/domain/entities/channel.dart';
import 'package:iptv/domain/entities/epg_program.dart';
import 'package:iptv/domain/entities/movie.dart';
import 'package:iptv/domain/entities/season.dart';
import 'package:iptv/domain/entities/series.dart';
import 'package:iptv/domain/repositories/live_repository.dart';
import 'package:iptv/domain/repositories/series_repository.dart';
import 'package:iptv/domain/repositories/vod_repository.dart';

class FakeLiveRepository implements LiveRepository {
  FakeLiveRepository({
    this.categories = const [],
    this.channels = const [],
    this.categoriesError,
    this.channelsError,
    this.throwOnCategories = false,
    this.throwOnChannels = false,
  });

  List<Category> categories;
  List<Channel> channels;
  AppResultError? categoriesError;
  AppResultError? channelsError;
  bool throwOnCategories;
  bool throwOnChannels;
  int getCategoriesCalls = 0;
  int getChannelsCalls = 0;
  int? lastChannelsCategoryId;

  @override
  Future<Result<List<Category>>> getCategories({
    bool forceRefresh = false,
  }) async {
    getCategoriesCalls++;
    if (throwOnCategories) throw Exception('categories failed');
    if (categoriesError != null) return Err(categoriesError!);
    return Ok(categories);
  }

  @override
  Future<Result<List<Channel>>> getChannels({
    int? categoryId,
    bool forceRefresh = false,
  }) async {
    getChannelsCalls++;
    lastChannelsCategoryId = categoryId;
    if (throwOnChannels) throw Exception('channels failed');
    if (channelsError != null) return Err(channelsError!);
    if (categoryId == null) return Ok(channels);
    return Ok(channels.where((c) => c.categoryId == categoryId).toList());
  }

  @override
  Future<Result<Channel>> getChannelById(int streamId) async {
    final match = channels.where((c) => c.streamId == streamId);
    if (match.isEmpty) {
      return const Err(AppResultError('not found'));
    }
    return Ok(match.first);
  }

  @override
  Future<Result<List<EpgProgram>>> getShortEpg(
    int streamId, {
    int limit = 4,
  }) async {
    return const Ok([]);
  }
}

class FakeVodRepository implements VodRepository {
  FakeVodRepository({
    this.categories = const [],
    this.movies = const [],
    this.categoriesError,
    this.moviesError,
    this.throwOnCategories = false,
    this.throwOnMovies = false,
  });

  List<Category> categories;
  List<Movie> movies;
  AppResultError? categoriesError;
  AppResultError? moviesError;
  bool throwOnCategories;
  bool throwOnMovies;
  int getCategoriesCalls = 0;
  int getMoviesCalls = 0;
  int? lastMoviesCategoryId;

  @override
  Future<Result<List<Category>>> getCategories({
    bool forceRefresh = false,
  }) async {
    getCategoriesCalls++;
    if (throwOnCategories) throw Exception('categories failed');
    if (categoriesError != null) return Err(categoriesError!);
    return Ok(categories);
  }

  @override
  Future<Result<List<Movie>>> getMovies({
    int? categoryId,
    bool forceRefresh = false,
  }) async {
    getMoviesCalls++;
    lastMoviesCategoryId = categoryId;
    if (throwOnMovies) throw Exception('movies failed');
    if (moviesError != null) return Err(moviesError!);
    if (categoryId == null) return Ok(movies);
    return Ok(movies.where((m) => m.categoryId == categoryId).toList());
  }

  @override
  Future<Result<Movie>> getMovieById(int streamId) async {
    final match = movies.where((m) => m.streamId == streamId);
    if (match.isEmpty) {
      return const Err(AppResultError('not found'));
    }
    return Ok(match.first);
  }
}

class FakeSeriesRepository implements SeriesRepository {
  FakeSeriesRepository({
    this.categories = const [],
    this.series = const [],
    this.categoriesError,
    this.seriesError,
    this.throwOnCategories = false,
    this.throwOnSeries = false,
  });

  List<Category> categories;
  List<Series> series;
  AppResultError? categoriesError;
  AppResultError? seriesError;
  bool throwOnCategories;
  bool throwOnSeries;
  int getCategoriesCalls = 0;
  int getSeriesCalls = 0;
  int? lastSeriesCategoryId;

  @override
  Future<Result<List<Category>>> getCategories({
    bool forceRefresh = false,
  }) async {
    getCategoriesCalls++;
    if (throwOnCategories) throw Exception('categories failed');
    if (categoriesError != null) return Err(categoriesError!);
    return Ok(categories);
  }

  @override
  Future<Result<List<Series>>> getSeries({
    int? categoryId,
    bool forceRefresh = false,
  }) async {
    getSeriesCalls++;
    lastSeriesCategoryId = categoryId;
    if (throwOnSeries) throw Exception('series failed');
    if (seriesError != null) return Err(seriesError!);
    if (categoryId == null) return Ok(series);
    return Ok(series.where((s) => s.categoryId == categoryId).toList());
  }

  @override
  Future<Result<List<Season>>> getSeasons(int seriesId) async {
    return const Ok([]);
  }
}

Category liveCategory(int id, String name) => Category(
      id: id,
      serverId: 1,
      type: CategoryType.live,
      name: name,
    );

Category vodCategory(int id, String name) => Category(
      id: id,
      serverId: 1,
      type: CategoryType.vod,
      name: name,
    );

Category seriesCategory(int id, String name) => Category(
      id: id,
      serverId: 1,
      type: CategoryType.series,
      name: name,
    );

Channel channel({
  required int streamId,
  required String name,
  int? categoryId,
  String? icon,
}) =>
    Channel(
      id: streamId,
      serverId: 1,
      streamId: streamId,
      name: name,
      categoryId: categoryId,
      streamIcon: icon,
    );

Movie movie({
  required int streamId,
  required String name,
  int? categoryId,
  String? icon,
}) =>
    Movie(
      id: streamId,
      serverId: 1,
      streamId: streamId,
      name: name,
      categoryId: categoryId,
      streamIcon: icon,
    );

Series seriesItem({
  required int seriesId,
  required String name,
  int? categoryId,
  String? cover,
}) =>
    Series(
      id: seriesId,
      serverId: 1,
      seriesId: seriesId,
      name: name,
      categoryId: categoryId,
      cover: cover,
    );
