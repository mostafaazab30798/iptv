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

    return Movie(
      id: streamId != 0 ? streamId : (int.tryParse(json['num']?.toString() ?? '0') ?? 0),
      serverId: serverId,
      streamId: streamId,
      name: nameStr,
      categoryId: int.tryParse(catIdStr ?? ''),
      streamIcon: (iconStr != null && iconStr.isNotEmpty) ? iconStr : null,
      rating: json['rating']?.toString() ?? json['rating_5based']?.toString(),
      containerExtension: json['container_extension']?.toString() ?? 'mp4',
    );
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
      rating: json['rating']?.toString() ?? json['rating_5based']?.toString(),
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
}
