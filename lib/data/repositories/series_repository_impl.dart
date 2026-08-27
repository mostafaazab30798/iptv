import 'dart:async';
import 'package:flutter/foundation.dart' show compute;
import 'package:iptv/core/cache/local_catalog_cache.dart';
import 'package:iptv/core/utils/result.dart';
import 'package:iptv/data/datasources/xtream_remote_datasource.dart';
import 'package:iptv/data/mappers/data_mapper.dart';
import 'package:iptv/domain/entities/category.dart';
import 'package:iptv/domain/entities/series.dart';
import 'package:iptv/domain/entities/season.dart';
import 'package:iptv/domain/repositories/series_repository.dart';

List<Series> _parseSeriesListIsolate(List<Map<String, dynamic>> raw) {
  return raw.map(DataMapper.seriesFromJson).toList();
}

class SeriesRepositoryImpl implements SeriesRepository {
  const SeriesRepositoryImpl({required this.remoteDataSource});

  final XtreamRemoteDataSource remoteDataSource;

  static const _ttl = Duration(minutes: 10);
  static List<Category>? _cachedCategories;
  static DateTime? _categoriesFetchedAt;

  static List<Series>? _cachedAllSeries;
  static DateTime? _seriesFetchedAt;
  static final Map<int, List<Series>> _cachedCategorySeries = {};
  static final Map<int, List<Season>> _cachedSeasons = {};

  static bool _isFresh(DateTime? fetchedAt) {
    if (fetchedAt == null) return false;
    return DateTime.now().difference(fetchedAt) < _ttl;
  }

  @override
  Future<Result<List<Category>>> getCategories({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedCategories != null && _isFresh(_categoriesFetchedAt)) {
      return Ok(_cachedCategories!);
    }

    // Cold-start disk cache check
    if (!forceRefresh && _cachedCategories == null) {
      final diskCategories = await LocalCatalogCache.instance.loadCategories('series', CategoryType.series);
      if (diskCategories != null && diskCategories.isNotEmpty) {
        _cachedCategories = diskCategories;
        _categoriesFetchedAt = DateTime.now();
        unawaited(remoteDataSource.getSeriesCategories().then((raw) {
          if (raw.isNotEmpty) {
            final categories = raw.map((j) => DataMapper.categoryFromJson(j, CategoryType.series)).toList();
            _cachedCategories = categories;
            _categoriesFetchedAt = DateTime.now();
            LocalCatalogCache.instance.saveCategories('series', raw);
          }
        }).catchError((_) {}));
        return Ok(diskCategories);
      }
    }

    try {
      final raw = await remoteDataSource.getSeriesCategories();
      final categories = raw.map((j) => DataMapper.categoryFromJson(j, CategoryType.series)).toList();
      _cachedCategories = categories;
      _categoriesFetchedAt = DateTime.now();
      if (raw.isNotEmpty) {
        unawaited(LocalCatalogCache.instance.saveCategories('series', raw));
      }
      return Ok(categories);
    } catch (e) {
      if (_cachedCategories != null) {
        return Ok(_cachedCategories!);
      }
      return Err(AppResultError('Failed to load series categories', cause: e));
    }
  }

  @override
  Future<Result<List<Series>>> getSeries({
    int? categoryId,
    bool forceRefresh = false,
  }) async {
    // Fast path 1: Unfiltered request and cached all series is fresh in memory
    if (categoryId == null && !forceRefresh && _cachedAllSeries != null && _isFresh(_seriesFetchedAt)) {
      return Ok(_cachedAllSeries!);
    }

    // Fast path 2: Filtered request and full catalog is already cached in memory
    if (categoryId != null && !forceRefresh && _cachedAllSeries != null && _isFresh(_seriesFetchedAt)) {
      final filtered = _cachedAllSeries!.where((s) => s.categoryId == categoryId).toList();
      return Ok(filtered);
    }

    // Fast path 3: Cold-start disk cache loading (< 15ms)
    if (!forceRefresh && _cachedAllSeries == null) {
      final diskSeries = await LocalCatalogCache.instance.loadSeries();
      if (diskSeries != null && diskSeries.isNotEmpty) {
        _cachedAllSeries = diskSeries;
        _seriesFetchedAt = DateTime.now();
        _cachedCategorySeries.clear();

        // Trigger silent background update
        unawaited(remoteDataSource.getSeries().then((raw) async {
          if (raw.isNotEmpty) {
            final list = raw.length > 250
                ? await compute(_parseSeriesListIsolate, raw)
                : raw.map(DataMapper.seriesFromJson).toList();
            _cachedAllSeries = list;
            _seriesFetchedAt = DateTime.now();
            unawaited(LocalCatalogCache.instance.saveSeries(raw));
          }
        }).catchError((_) {}));

        if (categoryId != null) {
          return Ok(diskSeries.where((s) => s.categoryId == categoryId).toList());
        }
        return Ok(diskSeries);
      }
    }

    // Fast path 4: Filtered request and specific category is cached
    if (categoryId != null && !forceRefresh && _cachedCategorySeries.containsKey(categoryId)) {
      return Ok(_cachedCategorySeries[categoryId]!);
    }

    try {
      final raw = await remoteDataSource.getSeries(categoryId: categoryId);
      final seriesList = raw.length > 250
          ? await compute(_parseSeriesListIsolate, raw)
          : raw.map(DataMapper.seriesFromJson).toList();

      if (categoryId == null) {
        _cachedAllSeries = seriesList;
        _seriesFetchedAt = DateTime.now();
        _cachedCategorySeries.clear();
        if (raw.isNotEmpty) {
          unawaited(LocalCatalogCache.instance.saveSeries(raw));
        }
      } else {
        _cachedCategorySeries[categoryId] = seriesList;
      }

      return Ok(seriesList);
    } catch (e) {
      if (categoryId == null && _cachedAllSeries != null) {
        return Ok(_cachedAllSeries!);
      }
      if (categoryId != null && _cachedAllSeries != null) {
        return Ok(_cachedAllSeries!.where((s) => s.categoryId == categoryId).toList());
      }
      return Err(AppResultError('Failed to load series', cause: e));
    }
  }

  @override
  Future<Result<List<Season>>> getSeasons(int seriesId) async {
    if (_cachedSeasons.containsKey(seriesId)) {
      return Ok(_cachedSeasons[seriesId]!);
    }
    try {
      final info = await remoteDataSource.getSeriesInfo(seriesId);
      if (info.isEmpty) {
        return const Ok([]);
      }

      // 1. Gather season metadata
      final seasonsMeta = <int, Map<String, dynamic>>{};
      final rawSeasons = info['seasons'];

      if (rawSeasons is List) {
        for (var i = 0; i < rawSeasons.length; i++) {
          final item = rawSeasons[i];
          if (item is Map) {
            final itemMap = Map<String, dynamic>.from(item);
            final sNum = int.tryParse(itemMap['season_number']?.toString() ??
                itemMap['season']?.toString() ??
                itemMap['num']?.toString() ??
                '${i + 1}') ?? (i + 1);
            seasonsMeta[sNum] = itemMap;
          }
        }
      } else if (rawSeasons is Map) {
        rawSeasons.forEach((key, value) {
          final keyNum = int.tryParse(key.toString());
          if (value is Map) {
            final valMap = Map<String, dynamic>.from(value);
            final sNum = int.tryParse(valMap['season_number']?.toString() ??
                valMap['season']?.toString() ??
                key.toString()) ?? keyNum ?? 1;
            seasonsMeta[sNum] = valMap;
          } else if (keyNum != null) {
            seasonsMeta[keyNum] = {
              'season_number': keyNum,
              'name': 'Season $keyNum',
            };
          }
        });
      }

      // 2. Gather episodes grouped by season
      final episodesBySeason = <int, List<Episode>>{};
      final rawEpisodes = info['episodes'];

      if (rawEpisodes is Map) {
        rawEpisodes.forEach((seasonKey, epList) {
          final cleanKey = seasonKey.toString().replaceAll(RegExp(r'[^0-9]'), '');
          final sNum = int.tryParse(cleanKey) ?? int.tryParse(seasonKey.toString()) ?? 1;

          if (epList is List) {
            for (var i = 0; i < epList.length; i++) {
              final ep = epList[i];
              if (ep is Map) {
                final epMap = Map<String, dynamic>.from(ep);
                final episode = _parseEpisode(epMap, sNum, i + 1);
                episodesBySeason.putIfAbsent(sNum, () => []).add(episode);
              }
            }
          }
        });
      } else if (rawEpisodes is List) {
        for (var i = 0; i < rawEpisodes.length; i++) {
          final ep = rawEpisodes[i];
          if (ep is Map) {
            final epMap = Map<String, dynamic>.from(ep);
            final sNum = int.tryParse(epMap['season']?.toString() ??
                epMap['season_num']?.toString() ??
                epMap['season_number']?.toString() ??
                '1') ?? 1;
            final episode = _parseEpisode(epMap, sNum, i + 1);
            episodesBySeason.putIfAbsent(sNum, () => []).add(episode);
          }
        }
      }

      // 3. Unify seasons
      final allSeasonNumbers = {...seasonsMeta.keys, ...episodesBySeason.keys}.toList()..sort();

      final seasons = <Season>[];
      for (final sNum in allSeasonNumbers) {
        final meta = seasonsMeta[sNum] ?? {};
        final rawSeasonEpisodes = episodesBySeason[sNum] ?? [];

        // Sort episodes by episodeNum
        rawSeasonEpisodes.sort((a, b) => a.episodeNum.compareTo(b.episodeNum));

        final seasonName = meta['name']?.toString() ?? 'Season $sNum';
        final seasonCover = meta['cover']?.toString() ?? meta['cover_big']?.toString();

        seasons.add(Season(
          id: sNum,
          seriesLocalId: seriesId,
          seasonNumber: sNum,
          name: seasonName,
          cover: (seasonCover != null && seasonCover.isNotEmpty) ? seasonCover : null,
          episodes: rawSeasonEpisodes,
        ));
      }

      _cachedSeasons[seriesId] = seasons;
      return Ok(seasons);
    } catch (e) {
      return Err(AppResultError('Failed to load seasons', cause: e));
    }
  }

  Episode _parseEpisode(Map<String, dynamic> epMap, int seasonNum, int indexFallback) {
    final epId = int.tryParse(epMap['id']?.toString() ??
        epMap['stream_id']?.toString() ??
        epMap['episode_id']?.toString() ??
        '0') ?? 0;

    final epInfo = (epMap['info'] is Map) ? Map<String, dynamic>.from(epMap['info'] as Map) : null;

    final epNum = int.tryParse(epMap['episode_num']?.toString() ??
        epMap['episode']?.toString() ??
        epMap['num']?.toString() ??
        epInfo?['episode_num']?.toString() ??
        '') ?? indexFallback;

    final title = epInfo?['name']?.toString() ??
        epMap['title']?.toString() ??
        epMap['name']?.toString() ??
        epInfo?['title']?.toString();
    final cleanTitle = (title != null && title.trim().isNotEmpty)
        ? title.trim()
        : 'Episode $epNum';

    final containerExt = epMap['container_extension']?.toString() ??
        epInfo?['container_extension']?.toString() ??
        epMap['target_container']?.toString() ??
        'mp4';

    final durationSecs = _parseDuration(
      epInfo?['duration_secs'] ?? epMap['duration_secs'],
      epInfo?['duration'] ?? epMap['duration'],
    );

    final plot = epInfo?['plot']?.toString() ??
        epMap['plot']?.toString() ??
        epInfo?['overview']?.toString();

    final cover = epInfo?['movie_image']?.toString() ??
        epInfo?['cover']?.toString() ??
        epInfo?['cover_big']?.toString() ??
        epMap['movie_image']?.toString() ??
        epMap['cover']?.toString();

    return Episode(
      id: epId,
      seasonLocalId: seasonNum,
      episodeNum: epNum,
      title: cleanTitle,
      streamId: epId,
      containerExtension: containerExt,
      durationSecs: durationSecs,
      plot: (plot != null && plot.trim().isNotEmpty) ? plot.trim() : null,
      cover: (cover != null && cover.trim().isNotEmpty) ? cover.trim() : null,
    );
  }

  int? _parseDuration(dynamic rawSecs, dynamic rawDurationStr) {
    if (rawSecs != null) {
      final s = int.tryParse(rawSecs.toString());
      if (s != null && s > 0) return s;
    }
    if (rawDurationStr != null) {
      final str = rawDurationStr.toString().trim();
      final parts = str.split(':');
      if (parts.length == 3) {
        final h = int.tryParse(parts[0]) ?? 0;
        final m = int.tryParse(parts[1]) ?? 0;
        final s = int.tryParse(parts[2]) ?? 0;
        final total = h * 3600 + m * 60 + s;
        if (total > 0) return total;
      } else if (parts.length == 2) {
        final m = int.tryParse(parts[0]) ?? 0;
        final s = int.tryParse(parts[1]) ?? 0;
        final total = m * 60 + s;
        if (total > 0) return total;
      } else {
        final s = int.tryParse(str);
        if (s != null && s > 0) return s;
      }
    }
    return null;
  }
}
