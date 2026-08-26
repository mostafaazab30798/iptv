import 'package:iptv/domain/entities/category.dart';
import 'package:iptv/domain/entities/channel.dart';
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
}
