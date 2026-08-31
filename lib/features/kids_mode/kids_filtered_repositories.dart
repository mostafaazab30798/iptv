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

const _blockedContentError = AppResultError('Content is blocked by Kids Mode');

class KidsFilteredVodRepository implements VodRepository {
  KidsFilteredVodRepository(this._delegate, this._policy);

  final VodRepository _delegate;
  final KidsContentPolicy _policy;

  Future<Result<Set<int>>> _allowedCategoryIds({
    bool forceRefresh = false,
  }) async {
    return (await _delegate.getCategories(forceRefresh: forceRefresh)).map(
      (categories) => categories
          .where(_policy.allowsCategory)
          .map((category) => category.id)
          .toSet(),
    );
  }

  @override
  Future<Result<List<Category>>> getCategories({
    bool forceRefresh = false,
  }) async {
    return (await _delegate.getCategories(
      forceRefresh: forceRefresh,
    )).map((categories) => categories.where(_policy.allowsCategory).toList());
  }

  @override
  Future<Result<List<Movie>>> getMovies({
    int? categoryId,
    bool forceRefresh = false,
  }) async {
    final allowedResult = await _allowedCategoryIds(forceRefresh: forceRefresh);
    if (allowedResult case Err<Set<int>>(:final appError)) {
      return Err(appError);
    }
    final allowed = allowedResult.value;
    if (categoryId != null && !allowed.contains(categoryId)) {
      return const Ok(<Movie>[]);
    }
    return (await _delegate.getMovies(
      categoryId: categoryId,
      forceRefresh: forceRefresh,
    )).map(
      (movies) =>
          movies.where((movie) => allowed.contains(movie.categoryId)).toList(),
    );
  }

  @override
  Future<Result<Movie>> getMovieById(int streamId) async {
    final movieResult = await _delegate.getMovieById(streamId);
    if (movieResult case Err<Movie>(:final appError)) return Err(appError);
    final allowedResult = await _allowedCategoryIds();
    if (allowedResult case Err<Set<int>>(:final appError)) {
      return Err(appError);
    }
    return allowedResult.value.contains(movieResult.value.categoryId)
        ? movieResult
        : const Err(_blockedContentError);
  }
}

class KidsFilteredSeriesRepository implements SeriesRepository {
  KidsFilteredSeriesRepository(this._delegate, this._policy);

  final SeriesRepository _delegate;
  final KidsContentPolicy _policy;

  Future<Result<Set<int>>> _allowedCategoryIds({
    bool forceRefresh = false,
  }) async {
    return (await _delegate.getCategories(forceRefresh: forceRefresh)).map(
      (categories) => categories
          .where(_policy.allowsCategory)
          .map((category) => category.id)
          .toSet(),
    );
  }

  @override
  Future<Result<List<Category>>> getCategories({
    bool forceRefresh = false,
  }) async {
    return (await _delegate.getCategories(
      forceRefresh: forceRefresh,
    )).map((categories) => categories.where(_policy.allowsCategory).toList());
  }

  @override
  Future<Result<List<Series>>> getSeries({
    int? categoryId,
    bool forceRefresh = false,
  }) async {
    final allowedResult = await _allowedCategoryIds(forceRefresh: forceRefresh);
    if (allowedResult case Err<Set<int>>(:final appError)) {
      return Err(appError);
    }
    final allowed = allowedResult.value;
    if (categoryId != null && !allowed.contains(categoryId)) {
      return const Ok(<Series>[]);
    }
    return (await _delegate.getSeries(
      categoryId: categoryId,
      forceRefresh: forceRefresh,
    )).map(
      (series) =>
          series.where((item) => allowed.contains(item.categoryId)).toList(),
    );
  }

  @override
  Future<Result<List<Season>>> getSeasons(int seriesId) async {
    final allowedSeries = await getSeries();
    if (allowedSeries case Err<List<Series>>(:final appError)) {
      return Err(appError);
    }
    if (!allowedSeries.value.any((series) => series.seriesId == seriesId)) {
      return const Err(_blockedContentError);
    }
    return _delegate.getSeasons(seriesId);
  }
}

class KidsFilteredLiveRepository implements LiveRepository {
  KidsFilteredLiveRepository(this._delegate, this._policy);

  final LiveRepository _delegate;
  final KidsContentPolicy _policy;

  bool _allowsChannel(Channel channel) =>
      _policy.allowsLiveChannelName(channel.name);

  @override
  Future<Result<List<Category>>> getCategories({
    bool forceRefresh = false,
  }) async {
    final results = await Future.wait([
      _delegate.getCategories(forceRefresh: forceRefresh),
      _delegate.getChannels(forceRefresh: forceRefresh),
    ]);
    final categoriesResult = results[0] as Result<List<Category>>;
    final channelsResult = results[1] as Result<List<Channel>>;
    if (categoriesResult case Err<List<Category>>(:final appError)) {
      return Err(appError);
    }
    if (channelsResult case Err<List<Channel>>(:final appError)) {
      return Err(appError);
    }
    final visibleCategoryIds = channelsResult.value
        .where(_allowsChannel)
        .map((channel) => channel.categoryId)
        .whereType<int>()
        .toSet();
    return Ok(
      categoriesResult.value
          .where((category) => visibleCategoryIds.contains(category.id))
          .toList(),
    );
  }

  @override
  Future<Result<List<Channel>>> getChannels({
    int? categoryId,
    bool forceRefresh = false,
  }) async {
    return (await _delegate.getChannels(
      categoryId: categoryId,
      forceRefresh: forceRefresh,
    )).map((channels) => channels.where(_allowsChannel).toList());
  }

  @override
  Future<Result<Channel>> getChannelById(int streamId) async {
    final result = await _delegate.getChannelById(streamId);
    if (result case Err<Channel>()) return result;
    return _allowsChannel(result.value)
        ? result
        : const Err(_blockedContentError);
  }
}
