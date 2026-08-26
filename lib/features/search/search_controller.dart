import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iptv/app/providers.dart';
import 'package:iptv/core/utils/result.dart';
import 'package:iptv/domain/entities/channel.dart';
import 'package:iptv/domain/entities/movie.dart';
import 'package:iptv/domain/entities/series.dart';
import 'package:iptv/domain/repositories/live_repository.dart';
import 'package:iptv/domain/repositories/series_repository.dart';
import 'package:iptv/domain/repositories/vod_repository.dart';

class SearchState {
  const SearchState({
    this.query = '',
    this.channels = const [],
    this.movies = const [],
    this.series = const [],
    this.isLoading = false,
  });

  final String query;
  final List<Channel> channels;
  final List<Movie> movies;
  final List<Series> series;
  final bool isLoading;

  bool get isEmpty =>
      query.isEmpty || (channels.isEmpty && movies.isEmpty && series.isEmpty);

  int get totalResults => channels.length + movies.length + series.length;
}

/// Simple typed in-memory catalog cache with TTL.
class _CatalogCache<T> {
  static const _ttl = Duration(minutes: 5);

  List<T>? _data;
  DateTime? _fetchedAt;

  bool get isValid =>
      _data != null &&
      _fetchedAt != null &&
      DateTime.now().difference(_fetchedAt!) < _ttl;

  List<T>? get data => isValid ? _data : null;

  void set(List<T> data) {
    _data = data;
    _fetchedAt = DateTime.now();
  }

  void invalidate() {
    _data = null;
    _fetchedAt = null;
  }
}

class SearchController extends StateNotifier<SearchState> {
  SearchController(this._liveRepo, this._vodRepo, this._seriesRepo)
      : super(const SearchState());

  final LiveRepository? _liveRepo;
  final VodRepository? _vodRepo;
  final SeriesRepository? _seriesRepo;

  int _searchToken = 0;

  // In-memory TTL caches — avoids full-catalog network round-trips on every search keystroke.
  final _channelCache = _CatalogCache<Channel>();
  final _movieCache = _CatalogCache<Movie>();
  final _seriesCache = _CatalogCache<Series>();

  Future<void> search(String query) async {
    final currentToken = ++_searchToken;
    final trimmed = query.trim();

    if (trimmed.isEmpty) {
      state = const SearchState();
      return;
    }

    state = SearchState(query: trimmed, isLoading: true);

    try {
      final q = trimmed.toLowerCase();

      // Fetch catalogs — use in-memory cache when fresh, otherwise hit network and populate cache.
      final channelsFuture = _fetchChannels();
      final moviesFuture = _fetchMovies();
      final seriesFuture = _fetchSeriesList();

      final results = await Future.wait([channelsFuture, moviesFuture, seriesFuture]);

      // If a newer search or clear was issued while we awaited, discard this response.
      if (_searchToken != currentToken) return;

      final channels = (results[0] as List<Channel>)
          .where((c) => c.name.toLowerCase().contains(q))
          .take(30)
          .toList();

      final movies = (results[1] as List<Movie>)
          .where((m) => m.name.toLowerCase().contains(q))
          .take(30)
          .toList();

      final series = (results[2] as List<Series>)
          .where((s) => s.name.toLowerCase().contains(q))
          .take(30)
          .toList();

      state = SearchState(
        query: trimmed,
        channels: channels,
        movies: movies,
        series: series,
        isLoading: false,
      );
    } catch (_) {
      if (_searchToken == currentToken) {
        state = SearchState(query: trimmed, isLoading: false);
      }
    }
  }

  /// Returns cached channels or fetches from network and populates cache.
  Future<List<Channel>> _fetchChannels() async {
    if (_channelCache.isValid) return _channelCache.data!;
    final res = await (_liveRepo?.getChannels() ??
        Future.value(const Err<List<Channel>>(AppResultError('No repo'))));
    final list = res.when(ok: (l) => l, err: (_) => <Channel>[]);
    if (list.isNotEmpty) _channelCache.set(list);
    return list;
  }

  /// Returns cached movies or fetches from network and populates cache.
  Future<List<Movie>> _fetchMovies() async {
    if (_movieCache.isValid) return _movieCache.data!;
    final res = await (_vodRepo?.getMovies() ??
        Future.value(const Err<List<Movie>>(AppResultError('No repo'))));
    final list = res.when(ok: (l) => l, err: (_) => <Movie>[]);
    if (list.isNotEmpty) _movieCache.set(list);
    return list;
  }

  /// Returns cached series or fetches from network and populates cache.
  Future<List<Series>> _fetchSeriesList() async {
    if (_seriesCache.isValid) return _seriesCache.data!;
    final res = await (_seriesRepo?.getSeries() ??
        Future.value(const Err<List<Series>>(AppResultError('No repo'))));
    final list = res.when(ok: (l) => l, err: (_) => <Series>[]);
    if (list.isNotEmpty) _seriesCache.set(list);
    return list;
  }

  void clear() {
    _searchToken++;
    state = const SearchState();
  }

  /// Explicitly invalidate catalog caches (e.g. after a pull-to-refresh).
  void invalidateCaches() {
    _channelCache.invalidate();
    _movieCache.invalidate();
    _seriesCache.invalidate();
  }
}

final searchControllerProvider =
    StateNotifierProvider<SearchController, SearchState>((ref) {
  final liveRepo = ref.watch(liveRepositoryProvider);
  final vodRepo = ref.watch(vodRepositoryProvider);
  final seriesRepo = ref.watch(seriesRepositoryProvider);
  return SearchController(liveRepo, vodRepo, seriesRepo);
});
