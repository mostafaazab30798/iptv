import 'dart:convert';

import 'package:iptv/domain/entities/category.dart';
import 'package:iptv/domain/entities/channel.dart';
import 'package:iptv/domain/entities/epg_program.dart';
import 'package:iptv/domain/entities/movie.dart';
import 'package:iptv/domain/entities/series.dart';

/// Data mappers converting raw JSON / DTOs into Domain Entities.
class DataMapper {
  static Category categoryFromJson(Map<String, dynamic> json, CategoryType type, {int serverId = 1}) {
    final catIdStr = json['category_id']?.toString() ?? json['id']?.toString() ?? '0';
    final nameStr = json['category_name']?.toString() ?? json['name']?.toString() ?? 'Category $catIdStr';

    return Category(
      id: int.tryParse(catIdStr) ?? 0,
      serverId: serverId,
      type: type,
      name: nameStr,
      parentId: int.tryParse(json['parent_id']?.toString() ?? ''),
    );
  }

  static Channel channelFromJson(Map<String, dynamic> json, {int serverId = 1}) {
    final streamIdStr = json['stream_id']?.toString() ?? json['id']?.toString() ?? json['num']?.toString() ?? '0';
    final nameStr = json['name']?.toString() ?? json['title']?.toString() ?? 'Channel $streamIdStr';
    final iconStr = json['stream_icon']?.toString() ?? json['cover']?.toString() ?? json['icon']?.toString();
    final catIdStr = json['category_id']?.toString();
    final streamId = int.tryParse(streamIdStr) ?? 0;

    return Channel(
      id: streamId != 0 ? streamId : (int.tryParse(json['num']?.toString() ?? '0') ?? 0),
      serverId: serverId,
      streamId: streamId,
      name: nameStr,
      categoryId: int.tryParse(catIdStr ?? ''),
      streamIcon: (iconStr != null && iconStr.isNotEmpty) ? iconStr : null,
      epgChannelId: json['epg_channel_id']?.toString(),
      hasTvArchive: json['tv_archive'] == 1 || json['tv_archive'] == '1',
      tvArchiveDuration: int.tryParse(json['tv_archive_duration']?.toString() ?? ''),
    );
  }

  static Movie movieFromJson(Map<String, dynamic> json, {int serverId = 1}) {
    final streamIdStr = json['stream_id']?.toString() ?? json['id']?.toString() ?? json['num']?.toString() ?? '0';
    final nameStr = json['name']?.toString() ?? json['title']?.toString() ?? 'Movie $streamIdStr';
    final iconStr = json['stream_icon']?.toString() ?? json['cover']?.toString() ?? json['movie_image']?.toString();
    final catIdStr = json['category_id']?.toString();
    final streamId = int.tryParse(streamIdStr) ?? 0;

    final plotStr = json['plot']?.toString() ?? json['description']?.toString();
    final castStr = json['cast']?.toString() ?? json['actors']?.toString();
    final directorStr = json['director']?.toString();
    final genreStr = json['genre']?.toString();
    final releaseDateStr = json['releaseDate']?.toString() ?? json['releasedate']?.toString() ?? json['release_date']?.toString();
    final releaseYear = int.tryParse(json['year']?.toString() ?? (releaseDateStr != null && releaseDateStr.contains('-') ? releaseDateStr.split('-').first : ''));
    final durationSecs = _parseDurationSecs(json['duration_secs'] ?? json['duration']);

    return Movie(
      id: streamId != 0 ? streamId : (int.tryParse(json['num']?.toString() ?? '0') ?? 0),
      serverId: serverId,
      streamId: streamId,
      name: nameStr,
      categoryId: int.tryParse(catIdStr ?? ''),
      streamIcon: (iconStr != null && iconStr.isNotEmpty) ? iconStr : null,
      rating: parseRating(
        json['rating'] ?? json['rating_10'] ?? json['vote_average'],
        json['rating_5based'],
      ),
      containerExtension: json['container_extension']?.toString() ?? 'mp4',
      plot: (plotStr != null && plotStr.isNotEmpty) ? plotStr : null,
      cast: (castStr != null && castStr.isNotEmpty) ? castStr : null,
      director: (directorStr != null && directorStr.isNotEmpty) ? directorStr : null,
      genre: (genreStr != null && genreStr.isNotEmpty) ? genreStr : null,
      releaseDate: (releaseDateStr != null && releaseDateStr.isNotEmpty) ? releaseDateStr : null,
      releaseYear: releaseYear,
      durationSecs: durationSecs,
    );
  }

  static Movie movieFromVodInfo(
    Map<String, dynamic> json,
    Movie fallbackMovie, {
    int serverId = 1,
  }) {
    final rawInfo = json['info'];
    final info = rawInfo is Map ? Map<String, dynamic>.from(rawInfo) : <String, dynamic>{};
    final rawMovieData = json['movie_data'];
    final movieData = rawMovieData is Map ? Map<String, dynamic>.from(rawMovieData) : <String, dynamic>{};
    final effectiveInfo = info.isNotEmpty ? info : json;

    final nameStr = movieData['name']?.toString() ??
        movieData['title']?.toString() ??
        effectiveInfo['name']?.toString() ??
        effectiveInfo['o_name']?.toString() ??
        fallbackMovie.name;

    final iconStr = effectiveInfo['movie_image']?.toString() ??
        effectiveInfo['cover_big']?.toString() ??
        effectiveInfo['cover']?.toString() ??
        movieData['stream_icon']?.toString() ??
        fallbackMovie.streamIcon;

    final plotStr = effectiveInfo['plot']?.toString() ??
        effectiveInfo['description']?.toString() ??
        fallbackMovie.plot;

    final castStr = effectiveInfo['cast']?.toString() ??
        effectiveInfo['actors']?.toString() ??
        fallbackMovie.cast;

    final directorStr = effectiveInfo['director']?.toString() ?? fallbackMovie.director;
    final genreStr = effectiveInfo['genre']?.toString() ?? fallbackMovie.genre;
    final countryStr = effectiveInfo['country']?.toString() ?? fallbackMovie.country;
    final mpaaRatingStr = effectiveInfo['age']?.toString() ??
        effectiveInfo['mpaa_rating']?.toString() ??
        fallbackMovie.mpaaRating;

    final ratingStr = parseRating(
          effectiveInfo['rating'] ??
              movieData['rating'] ??
              effectiveInfo['rating_10'] ??
              effectiveInfo['vote_average'] ??
              movieData['vote_average'],
          effectiveInfo['rating_5based'] ?? movieData['rating_5based'],
        ) ??
        fallbackMovie.rating;

    final releaseDateStr = effectiveInfo['releasedate']?.toString() ??
        effectiveInfo['release_date']?.toString() ??
        fallbackMovie.releaseDate;

    final releaseYear = int.tryParse(
          effectiveInfo['year']?.toString() ??
              movieData['year']?.toString() ??
              (releaseDateStr != null && releaseDateStr.contains('-')
                  ? releaseDateStr.split('-').first
                  : ''),
        ) ??
        fallbackMovie.releaseYear;

    final durationSecs = _parseDurationSecs(
          effectiveInfo['duration_secs'] ??
              effectiveInfo['duration'] ??
              effectiveInfo['episode_run_time'],
        ) ??
        fallbackMovie.durationSecs;

    final containerExtension = movieData['container_extension']?.toString() ??
        effectiveInfo['container_extension']?.toString() ??
        fallbackMovie.containerExtension ??
        'mp4';

    final categoryId = int.tryParse(
          movieData['category_id']?.toString() ??
              effectiveInfo['category_id']?.toString() ??
              '',
        ) ??
        fallbackMovie.categoryId;

    List<String>? backdropPaths;
    final rawBackdrops = effectiveInfo['backdrop_path'];
    if (rawBackdrops is List) {
      final list = rawBackdrops
          .map((e) => e?.toString() ?? '')
          .where((s) => s.isNotEmpty && s.startsWith('http'))
          .toList();
      if (list.isNotEmpty) backdropPaths = list;
    }

    String? videoResolution;
    final video = effectiveInfo['video'];
    if (video is Map) {
      final height = int.tryParse(video['height']?.toString() ?? '');
      final width = int.tryParse(video['width']?.toString() ?? '');
      if (height != null) {
        if (height >= 2160 || (width != null && width >= 3840)) {
          videoResolution = '4K';
        } else if (height >= 1080) {
          videoResolution = '1080p';
        } else if (height >= 720) {
          videoResolution = '720p';
        } else {
          videoResolution = 'SD';
        }
      }
    }

    return fallbackMovie.copyWith(
      name: nameStr.isNotEmpty ? nameStr : fallbackMovie.name,
      streamIcon: (iconStr != null && iconStr.isNotEmpty) ? iconStr : fallbackMovie.streamIcon,
      plot: (plotStr != null && plotStr.isNotEmpty) ? plotStr : fallbackMovie.plot,
      cast: (castStr != null && castStr.isNotEmpty) ? castStr : fallbackMovie.cast,
      director: (directorStr != null && directorStr.isNotEmpty) ? directorStr : fallbackMovie.director,
      genre: (genreStr != null && genreStr.isNotEmpty) ? genreStr : fallbackMovie.genre,
      country: (countryStr != null && countryStr.isNotEmpty) ? countryStr : fallbackMovie.country,
      mpaaRating: (mpaaRatingStr != null && mpaaRatingStr.isNotEmpty) ? mpaaRatingStr : fallbackMovie.mpaaRating,
      rating: (ratingStr != null && ratingStr.isNotEmpty) ? ratingStr : fallbackMovie.rating,
      releaseDate: (releaseDateStr != null && releaseDateStr.isNotEmpty) ? releaseDateStr : fallbackMovie.releaseDate,
      releaseYear: releaseYear,
      durationSecs: durationSecs,
      containerExtension: containerExtension,
      categoryId: categoryId,
      backdropPaths: backdropPaths ?? fallbackMovie.backdropPaths,
      videoResolution: videoResolution ?? fallbackMovie.videoResolution,
    );
  }

  static int? _parseDurationSecs(dynamic raw) {
    if (raw == null) return null;
    final str = raw.toString().trim();
    if (str.isEmpty) return null;
    final direct = int.tryParse(str);
    if (direct != null && direct > 0) return direct;
    final parts = str.split(':');
    if (parts.length == 3) {
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      final s = int.tryParse(parts[2]) ?? 0;
      return h * 3600 + m * 60 + s;
    } else if (parts.length == 2) {
      final m = int.tryParse(parts[0]) ?? 0;
      final s = int.tryParse(parts[1]) ?? 0;
      return m * 60 + s;
    }
    return null;
  }

  static Series seriesFromJson(Map<String, dynamic> json, {int serverId = 1}) {
    final seriesIdStr = json['series_id']?.toString() ?? json['id']?.toString() ?? '0';
    final nameStr = json['name']?.toString() ?? json['title']?.toString() ?? 'Series $seriesIdStr';
    final coverStr = json['cover']?.toString() ?? json['stream_icon']?.toString() ?? json['poster']?.toString();
    final catIdStr = json['category_id']?.toString();
    final seriesId = int.tryParse(seriesIdStr) ?? 0;

    return Series(
      id: seriesId != 0 ? seriesId : (int.tryParse(json['num']?.toString() ?? '0') ?? 0),
      serverId: serverId,
      seriesId: seriesId,
      name: nameStr,
      categoryId: int.tryParse(catIdStr ?? ''),
      cover: (coverStr != null && coverStr.isNotEmpty) ? coverStr : null,
      plot: json['plot']?.toString(),
      cast: json['cast']?.toString(),
      director: json['director']?.toString(),
      genre: json['genre']?.toString(),
      rating: parseRating(
        json['rating'] ?? json['rating_10'] ?? json['vote_average'],
        json['rating_5based'],
      ),
      releaseYear: int.tryParse(json['releaseDate']?.toString() ?? json['year']?.toString() ?? ''),
    );
  }

  static String decodeEpgText(dynamic raw) {
    if (raw == null) return '';
    final source = raw.toString().trim();
    if (source.isEmpty) return '';
    try {
      final decoded = utf8.decode(base64.decode(source)).trim();
      if (decoded.isNotEmpty) return decoded;
    } catch (_) {}
    return source;
  }

  static EpgProgram? epgFromListing(
    Map<String, dynamic> json, {
    int? channelId,
  }) {
    final title = decodeEpgText(json['title'] ?? json['name']);
    if (title.isEmpty) return null;

    final start = _epgDateTime(
      json['start_timestamp'] ?? json['start'],
      json['start'],
    );
    final end = _epgDateTime(
      json['stop_timestamp'] ?? json['end'] ?? json['stop'],
      json['end'] ?? json['stop'],
    );
    if (start == null || end == null) return null;

    final epgId = json['id']?.toString() ??
        json['epg_id']?.toString() ??
        '${channelId ?? 0}-$start';
    final id = int.tryParse(json['id']?.toString() ?? '') ??
        start.millisecondsSinceEpoch;

    return EpgProgram(
      id: id,
      epgId: epgId,
      channelId: channelId,
      title: title,
      description: decodeEpgText(json['description'] ?? json['desc']),
      start: start,
      end: end,
      lang: json['lang']?.toString() ?? 'en',
    );
  }

  static bool listingIsNowPlaying(Map<String, dynamic> json) {
    final flag = json['now_playing'];
    if (flag == 1 || flag == '1' || flag == true) return true;

    final start = _epgDateTime(
      json['start_timestamp'] ?? json['start'],
      json['start'],
    );
    final end = _epgDateTime(
      json['stop_timestamp'] ?? json['end'] ?? json['stop'],
      json['end'] ?? json['stop'],
    );
    if (start == null || end == null) return false;
    final now = DateTime.now().toUtc();
    return !now.isBefore(start.toUtc()) && now.isBefore(end.toUtc());
  }

  static DateTime? _epgDateTime(dynamic timestamp, dynamic fallback) {
    final rawTs = timestamp?.toString().trim();
    if (rawTs != null && rawTs.isNotEmpty) {
      final seconds = int.tryParse(rawTs);
      if (seconds != null && seconds > 1e8) {
        return DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);
      }
      final parsed = DateTime.tryParse(rawTs);
      if (parsed != null) return parsed.toUtc();
    }
    final rawFallback = fallback?.toString().trim();
    if (rawFallback == null || rawFallback.isEmpty) return null;
    return DateTime.tryParse(rawFallback)?.toUtc();
  }

  /// Parses rating values from various IPTV Xtream / TMDB formats.
  ///
  /// - Extracts 10-based rating from [rawRating] (handles numeric, string decimals,
  ///   fractions like "8.5/10", commas like "8,7", and ignores "null" / "N/A").
  /// - If [rawRating] is missing or <= 0, falls back to [raw5Based]. If 5-based,
  ///   it is converted to a 10-based scale (e.g. 4.3 -> 8.6).
  /// - If the final rating is <= 0 or unparseable, returns `null` so unrated items
  ///   do not carry a misleading "0" or "0.0" rating.
  static String? parseRating(dynamic rawRating, [dynamic raw5Based]) {
    final direct = _tryParseRatingValue(rawRating);
    if (direct != null && direct > 0.0) {
      return _formatRating(direct);
    }

    final fiveBased = _tryParseRatingValue(raw5Based);
    if (fiveBased != null && fiveBased > 0.0) {
      final converted = fiveBased <= 5.0 ? (fiveBased * 2.0) : fiveBased;
      return _formatRating(converted.clamp(0.0, 10.0));
    }

    return null;
  }

  static double? _tryParseRatingValue(dynamic raw) {
    if (raw == null) return null;
    if (raw is num) {
      final d = raw.toDouble();
      return (d.isNaN || d.isInfinite) ? null : d;
    }
    final str = raw.toString().trim();
    if (str.isEmpty ||
        str.toLowerCase() == 'null' ||
        str.toLowerCase() == 'n/a' ||
        str.toLowerCase() == 'nan') {
      return null;
    }
    final normalized = str.replaceAll(',', '.');
    if (normalized.contains('/')) {
      final parts = normalized.split('/');
      final numVal = double.tryParse(parts[0].trim());
      final denVal = double.tryParse(parts[1].trim());
      if (numVal != null && denVal != null && denVal > 0) {
        return (numVal / denVal) * 10.0;
      }
    }
    return double.tryParse(normalized);
  }

  static String _formatRating(double value) {
    return value.toStringAsFixed(1);
  }
}
