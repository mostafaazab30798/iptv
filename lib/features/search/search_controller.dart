import 'dart:async';

import 'package:flutter/foundation.dart' show compute;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iptv/app/providers.dart';
import 'package:iptv/core/cache/local_catalog_cache.dart';
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
  static const _ttl = Duration(minutes: 20);

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

  Timer? _debounceTimer;
  int _searchToken = 0;

  // In-memory TTL caches — avoids full-catalog network round-trips on every search.
  final _channelCache = _CatalogCache<Channel>();
  final _movieCache = _CatalogCache<Movie>();
  final _seriesCache = _CatalogCache<Series>();

  static const _minQueryLength = 2;
  static const _resultLimit = 24;
  static const _debounce = Duration(milliseconds: 400);
  static const _isolateThreshold = 1500;

  Future<void> search(String query) async {
    _debounceTimer?.cancel();
    final trimmed = query.trim();

    if (trimmed.isEmpty) {
      _searchToken++;
      state = const SearchState();
      return;
    }

    // Avoid scanning huge catalogs for 1-character queries.
    if (trimmed.length < _minQueryLength) {
      _searchToken++;
      state = SearchState(query: trimmed);
      return;
    }

    _debounceTimer = Timer(_debounce, () async {
      final currentToken = ++_searchToken;
      state = SearchState(query: trimmed, isLoading: true);

      try {
        final q = trimmed.toLowerCase();

        // Load catalogs from memory/disk first — no server traffic when warm.
        final results = await Future.wait([
          _fetchChannels(),
          _fetchMovies(),
          _fetchSeriesList(),
        ]);

        if (_searchToken != currentToken) return;

        final channels = await _filterByName(
          results[0] as List<Channel>,
          q,
          (c) => c.name,
        );
        final movies = await _filterByName(
          results[1] as List<Movie>,
          q,
          (m) => m.name,
        );
        final series = await _filterByName(
          results[2] as List<Series>,
          q,
          (s) => s.name,
        );

        if (_searchToken != currentToken) return;

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
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Prefer memory → local disk cache → repository (network only as last resort).
  Future<List<Channel>> _fetchChannels() async {
    if (_channelCache.isValid) return _channelCache.data!;

    final disk = await LocalCatalogCache.instance.loadChannels();
    if (disk != null && disk.isNotEmpty) {
      _channelCache.set(disk);
      return disk;
    }

    final res = await (_liveRepo?.getChannels() ??
        Future.value(const Err<List<Channel>>(AppResultError('No repo'))));
    final list = res.when(ok: (l) => l, err: (_) => <Channel>[]);
    if (list.isNotEmpty) _channelCache.set(list);
    return list;
  }

  Future<List<Movie>> _fetchMovies() async {
    if (_movieCache.isValid) return _movieCache.data!;

    final disk = await LocalCatalogCache.instance.loadMovies();
    if (disk != null && disk.isNotEmpty) {
      _movieCache.set(disk);
      return disk;
    }

    final res = await (_vodRepo?.getMovies() ??
        Future.value(const Err<List<Movie>>(AppResultError('No repo'))));
    final list = res.when(ok: (l) => l, err: (_) => <Movie>[]);
    if (list.isNotEmpty) _movieCache.set(list);
    return list;
  }

  Future<List<Series>> _fetchSeriesList() async {
    if (_seriesCache.isValid) return _seriesCache.data!;

    final disk = await LocalCatalogCache.instance.loadSeries();
    if (disk != null && disk.isNotEmpty) {
      _seriesCache.set(disk);
      return disk;
    }

    final res = await (_seriesRepo?.getSeries() ??
        Future.value(const Err<List<Series>>(AppResultError('No repo'))));
    final list = res.when(ok: (l) => l, err: (_) => <Series>[]);
    if (list.isNotEmpty) _seriesCache.set(list);
    return list;
  }

  /// Early-exit name filter; offloads large catalogs to a background isolate.
  Future<List<T>> _filterByName<T>(
    List<T> items,
    String query,
    String Function(T) nameOf,
  ) async {
    if (items.isEmpty) return const [];

    if (items.length < _isolateThreshold) {
      return _filterSync(items, query, nameOf);
    }

    final names = items.map((e) => nameOf(e).toLowerCase()).toList(growable: false);
    final indices = await compute(_matchNameIndices, <Object>[names, query, _resultLimit]);
    return [for (final i in indices) items[i]];
  }

  List<T> _filterSync<T>(
    List<T> items,
    String query,
    String Function(T) nameOf,
  ) {
    final out = <T>[];
    for (final item in items) {
      if (nameOf(item).toLowerCase().contains(query)) {
        out.add(item);
        if (out.length >= _resultLimit) break;
      }
    }
    return out;
  }

  void clear() {
    _searchToken++;
    _debounceTimer?.cancel();
    state = const SearchState();
  }

  /// Explicitly invalidate catalog caches (e.g. after a pull-to-refresh).
  void invalidateCaches() {
    _channelCache.invalidate();
    _movieCache.invalidate();
    _seriesCache.invalidate();
  }
}

List<int> _matchNameIndices(List<Object> args) {
  final names = args[0] as List<String>;
  final query = args[1] as String;
  final limit = args[2] as int;
  final out = <int>[];
  for (var i = 0; i < names.length; i++) {
    if (names[i].contains(query)) {
      out.add(i);
      if (out.length >= limit) break;
    }
  }
  return out;
}

final searchControllerProvider =
    StateNotifierProvider<SearchController, SearchState>((ref) {
  final liveRepo = ref.watch(liveRepositoryProvider);
  final vodRepo = ref.watch(vodRepositoryProvider);
  final seriesRepo = ref.watch(seriesRepositoryProvider);
  return SearchController(liveRepo, vodRepo, seriesRepo);
});
