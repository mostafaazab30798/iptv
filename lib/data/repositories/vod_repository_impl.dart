import 'dart:async';
import 'package:flutter/foundation.dart' show compute;
import 'package:iptv/core/cache/local_catalog_cache.dart';
import 'package:iptv/core/utils/result.dart';
import 'package:iptv/data/cache/catalog_memory_cache.dart';
import 'package:iptv/data/datasources/xtream_remote_datasource.dart';
import 'package:iptv/data/mappers/data_mapper.dart';
import 'package:iptv/domain/entities/category.dart';
import 'package:iptv/domain/entities/movie.dart';
import 'package:iptv/domain/repositories/vod_repository.dart';

List<Movie> _parseMoviesIsolate(List<Map<String, dynamic>> raw) {
  return raw.map(DataMapper.movieFromJson).toList();
}

class VodRepositoryImpl implements VodRepository {
  VodRepositoryImpl({
    required this.remoteDataSource,
    required this.cache,
  });

  final XtreamRemoteDataSource remoteDataSource;
  final CatalogMemoryCache cache;

  static const _ttl = Duration(minutes: 10);

  bool _isFresh(DateTime? fetchedAt) {
    if (fetchedAt == null) return false;
    return DateTime.now().difference(fetchedAt) < _ttl;
  }

  @override
  Future<Result<List<Category>>> getCategories({bool forceRefresh = false}) async {
    if (!forceRefresh && cache.vodCategories != null && _isFresh(cache.vodCategoriesFetchedAt)) {
      return Ok(cache.vodCategories!);
    }

    // Cold start disk cache check
    if (!forceRefresh && cache.vodCategories == null) {
      final diskCategories = await LocalCatalogCache.instance.loadCategories('vod', CategoryType.vod);
      if (diskCategories != null && diskCategories.isNotEmpty) {
        cache.vodCategories = diskCategories;
        cache.vodCategoriesFetchedAt = DateTime.now();
        unawaited(remoteDataSource.getVodCategories().then((raw) {
          if (raw.isNotEmpty) {
            final categories = raw.map((j) => DataMapper.categoryFromJson(j, CategoryType.vod)).toList();
            cache.vodCategories = categories;
            cache.vodCategoriesFetchedAt = DateTime.now();
            LocalCatalogCache.instance.saveCategories('vod', raw);
          }
        }).catchError((_) {}));
        return Ok(diskCategories);
      }
    }

    try {
      final raw = await remoteDataSource.getVodCategories();
      final categories = raw.map((j) => DataMapper.categoryFromJson(j, CategoryType.vod)).toList();
      cache.vodCategories = categories;
      cache.vodCategoriesFetchedAt = DateTime.now();
      if (raw.isNotEmpty) {
        unawaited(LocalCatalogCache.instance.saveCategories('vod', raw));
      }
      return Ok(categories);
    } catch (e) {
      if (cache.vodCategories != null) {
        return Ok(cache.vodCategories!);
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
    if (categoryId == null && !forceRefresh && cache.vodMovies != null && _isFresh(cache.vodMoviesFetchedAt)) {
      return Ok(cache.vodMovies!);
    }

    // Fast path 2: Filtered request and full catalog is already cached in memory
    if (categoryId != null && !forceRefresh && cache.vodMovies != null && _isFresh(cache.vodMoviesFetchedAt)) {
      final filtered = cache.vodMovies!.where((m) => m.categoryId == categoryId).toList();
      return Ok(filtered);
    }

    // Fast path 3: Cold-start disk cache loading (< 15ms)
    if (!forceRefresh && cache.vodMovies == null) {
      final diskMovies = await LocalCatalogCache.instance.loadMovies();
      if (diskMovies != null && diskMovies.isNotEmpty) {
        cache.vodMovies = diskMovies;
        cache.vodMoviesFetchedAt = DateTime.now();
        cache.vodCategoryMovies.clear();
        cache.vodMovieMap
          ..clear()
          ..addEntries(diskMovies.map((m) => MapEntry(m.streamId, m)));

        // Trigger silent background update
        unawaited(remoteDataSource.getVodStreams().then((raw) async {
          if (raw.isNotEmpty) {
            final movies = raw.length > 250
                ? await compute(_parseMoviesIsolate, raw)
                : raw.map(DataMapper.movieFromJson).toList();
            cache.vodMovies = movies;
            cache.vodMoviesFetchedAt = DateTime.now();
            cache.vodMovieMap
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
    if (categoryId != null && !forceRefresh && cache.vodCategoryMovies.containsKey(categoryId)) {
      return Ok(cache.vodCategoryMovies[categoryId]!);
    }

    try {
      final raw = await remoteDataSource.getVodStreams(categoryId: categoryId);
      final movies = raw.length > 250
          ? await compute(_parseMoviesIsolate, raw)
          : raw.map(DataMapper.movieFromJson).toList();

      if (categoryId == null) {
        cache.vodMovies = movies;
        cache.vodMoviesFetchedAt = DateTime.now();
        cache.vodCategoryMovies.clear();
        cache.vodMovieMap
          ..clear()
          ..addEntries(movies.map((m) => MapEntry(m.streamId, m)));
        if (raw.isNotEmpty) {
          unawaited(LocalCatalogCache.instance.saveMovies(raw));
        }
      } else {
        cache.vodCategoryMovies[categoryId] = movies;
        for (final m in movies) {
          cache.vodMovieMap[m.streamId] = m;
        }
      }

      return Ok(movies);
    } catch (e) {
      if (categoryId == null && cache.vodMovies != null) {
        return Ok(cache.vodMovies!);
      }
      if (categoryId != null && cache.vodMovies != null) {
        return Ok(cache.vodMovies!.where((m) => m.categoryId == categoryId).toList());
      }
      return Err(AppResultError('Failed to load movies', cause: e));
    }
  }

  @override
  Future<Result<Movie>> getMovieById(int streamId) async {
    if (cache.vodMovieMap.containsKey(streamId)) {
      return Ok(cache.vodMovieMap[streamId]!);
    }

    if (cache.vodMovies != null) {
      try {
        final movie = cache.vodMovies!.firstWhere((m) => m.streamId == streamId);
        cache.vodMovieMap[streamId] = movie;
        return Ok(movie);
      } catch (_) {}
    }

    try {
      await getMovies();
      final movie = cache.vodMovieMap[streamId];
      if (movie != null) {
        return Ok(movie);
      }
      return const Err(AppResultError('Movie not found'));
    } catch (e) {
      return Err(AppResultError('Movie not found', cause: e));
    }
  }

  @override
  Future<Result<Movie>> getMovieDetails(int streamId, {Movie? fallback}) async {
    final cached = cache.vodMovieMap[streamId];
    if (cached != null && (cached.plot != null || cached.backdropPaths != null || cached.director != null)) {
      return Ok(cached);
    }

    try {
      final raw = await remoteDataSource.getVodInfo(streamId);
      if (raw.isNotEmpty) {
        final baseMovie = fallback ?? cached ?? await () async {
          final res = await getMovieById(streamId);
          return res.isOk ? res.value : Movie(id: streamId, serverId: 1, streamId: streamId, name: '');
        }();
        final detailed = DataMapper.movieFromVodInfo(raw, baseMovie);
        cache.vodMovieMap[streamId] = detailed;
        return Ok(detailed);
      }
    } catch (_) {}

    if (cached != null) return Ok(cached);
    if (fallback != null) return Ok(fallback);
    return getMovieById(streamId);
  }
}
