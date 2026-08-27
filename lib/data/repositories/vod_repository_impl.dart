import 'dart:async';
import 'package:flutter/foundation.dart' show compute;
import 'package:iptv/core/cache/local_catalog_cache.dart';
import 'package:iptv/core/utils/result.dart';
import 'package:iptv/data/datasources/xtream_remote_datasource.dart';
import 'package:iptv/data/mappers/data_mapper.dart';
import 'package:iptv/domain/entities/category.dart';
import 'package:iptv/domain/entities/movie.dart';
import 'package:iptv/domain/repositories/vod_repository.dart';

List<Movie> _parseMoviesIsolate(List<Map<String, dynamic>> raw) {
  return raw.map(DataMapper.movieFromJson).toList();
}

class VodRepositoryImpl implements VodRepository {
  const VodRepositoryImpl({required this.remoteDataSource});

  final XtreamRemoteDataSource remoteDataSource;

  static const _ttl = Duration(minutes: 10);
  static List<Category>? _cachedCategories;
  static DateTime? _categoriesFetchedAt;

  static List<Movie>? _cachedAllMovies;
  static DateTime? _moviesFetchedAt;
  static final Map<int, List<Movie>> _cachedCategoryMovies = {};
  static final Map<int, Movie> _movieMap = {};

  static bool _isFresh(DateTime? fetchedAt) {
    if (fetchedAt == null) return false;
    return DateTime.now().difference(fetchedAt) < _ttl;
  }

  @override
  Future<Result<List<Category>>> getCategories({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedCategories != null && _isFresh(_categoriesFetchedAt)) {
      return Ok(_cachedCategories!);
    }

    // Cold start disk cache check
    if (!forceRefresh && _cachedCategories == null) {
      final diskCategories = await LocalCatalogCache.instance.loadCategories('vod', CategoryType.vod);
      if (diskCategories != null && diskCategories.isNotEmpty) {
        _cachedCategories = diskCategories;
        _categoriesFetchedAt = DateTime.now();
        unawaited(remoteDataSource.getVodCategories().then((raw) {
          if (raw.isNotEmpty) {
            final categories = raw.map((j) => DataMapper.categoryFromJson(j, CategoryType.vod)).toList();
            _cachedCategories = categories;
            _categoriesFetchedAt = DateTime.now();
            LocalCatalogCache.instance.saveCategories('vod', raw);
          }
        }).catchError((_) {}));
        return Ok(diskCategories);
      }
    }

    try {
      final raw = await remoteDataSource.getVodCategories();
      final categories = raw.map((j) => DataMapper.categoryFromJson(j, CategoryType.vod)).toList();
      _cachedCategories = categories;
      _categoriesFetchedAt = DateTime.now();
      if (raw.isNotEmpty) {
        unawaited(LocalCatalogCache.instance.saveCategories('vod', raw));
      }
      return Ok(categories);
    } catch (e) {
      if (_cachedCategories != null) {
        return Ok(_cachedCategories!);
      }
      return Err(AppResultError('Failed to load VOD categories', cause: e));
    }
  }

  @override
  Future<Result<List<Movie>>> getMovies({
    int? categoryId,
    bool forceRefresh = false,
  }) async {
    // Fast path 1: Unfiltered request and cached all movies is fresh in memory
    if (categoryId == null && !forceRefresh && _cachedAllMovies != null && _isFresh(_moviesFetchedAt)) {
      return Ok(_cachedAllMovies!);
    }

    // Fast path 2: Filtered request and full catalog is already cached in memory
    if (categoryId != null && !forceRefresh && _cachedAllMovies != null && _isFresh(_moviesFetchedAt)) {
      final filtered = _cachedAllMovies!.where((m) => m.categoryId == categoryId).toList();
      return Ok(filtered);
    }

    // Fast path 3: Cold-start disk cache loading (< 15ms)
    if (!forceRefresh && _cachedAllMovies == null) {
      final diskMovies = await LocalCatalogCache.instance.loadMovies();
      if (diskMovies != null && diskMovies.isNotEmpty) {
        _cachedAllMovies = diskMovies;
        _moviesFetchedAt = DateTime.now();
        _cachedCategoryMovies.clear();
        _movieMap
          ..clear()
          ..addEntries(diskMovies.map((m) => MapEntry(m.streamId, m)));

        // Trigger silent background update
        unawaited(remoteDataSource.getVodStreams().then((raw) async {
          if (raw.isNotEmpty) {
            final movies = raw.length > 250
                ? await compute(_parseMoviesIsolate, raw)
                : raw.map(DataMapper.movieFromJson).toList();
            _cachedAllMovies = movies;
            _moviesFetchedAt = DateTime.now();
            _movieMap
              ..clear()
              ..addEntries(movies.map((m) => MapEntry(m.streamId, m)));
            unawaited(LocalCatalogCache.instance.saveMovies(raw));
          }
        }).catchError((_) {}));

        if (categoryId != null) {
          return Ok(diskMovies.where((m) => m.categoryId == categoryId).toList());
        }
        return Ok(diskMovies);
      }
    }

    // Fast path 4: Filtered request and specific category is cached
    if (categoryId != null && !forceRefresh && _cachedCategoryMovies.containsKey(categoryId)) {
      return Ok(_cachedCategoryMovies[categoryId]!);
    }

    try {
      final raw = await remoteDataSource.getVodStreams(categoryId: categoryId);
      final movies = raw.length > 250
          ? await compute(_parseMoviesIsolate, raw)
          : raw.map(DataMapper.movieFromJson).toList();

      if (categoryId == null) {
        _cachedAllMovies = movies;
        _moviesFetchedAt = DateTime.now();
        _cachedCategoryMovies.clear();
        _movieMap
          ..clear()
          ..addEntries(movies.map((m) => MapEntry(m.streamId, m)));
        if (raw.isNotEmpty) {
          unawaited(LocalCatalogCache.instance.saveMovies(raw));
        }
      } else {
        _cachedCategoryMovies[categoryId] = movies;
        for (final m in movies) {
          _movieMap[m.streamId] = m;
        }
      }

      return Ok(movies);
    } catch (e) {
      if (categoryId == null && _cachedAllMovies != null) {
        return Ok(_cachedAllMovies!);
      }
      if (categoryId != null && _cachedAllMovies != null) {
        return Ok(_cachedAllMovies!.where((m) => m.categoryId == categoryId).toList());
      }
      return Err(AppResultError('Failed to load movies', cause: e));
    }
  }

  @override
  Future<Result<Movie>> getMovieById(int streamId) async {
    if (_movieMap.containsKey(streamId)) {
      return Ok(_movieMap[streamId]!);
    }

    if (_cachedAllMovies != null) {
      try {
        final movie = _cachedAllMovies!.firstWhere((m) => m.streamId == streamId);
        _movieMap[streamId] = movie;
        return Ok(movie);
      } catch (_) {}
    }

    try {
      await getMovies();
      final movie = _movieMap[streamId];
      if (movie != null) {
        return Ok(movie);
      }
      return const Err(AppResultError('Movie not found'));
    } catch (e) {
      return Err(AppResultError('Movie not found', cause: e));
    }
  }
}
