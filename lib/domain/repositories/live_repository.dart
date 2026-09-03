import 'package:iptv/core/utils/result.dart';
import 'package:iptv/domain/entities/category.dart';
import 'package:iptv/domain/entities/channel.dart';
import 'package:iptv/domain/entities/epg_program.dart';

abstract interface class LiveRepository {
  Future<Result<List<Category>>> getCategories({bool forceRefresh = false});
  Future<Result<List<Channel>>> getChannels({
    int? categoryId,
    bool forceRefresh = false,
  });
  Future<Result<Channel>> getChannelById(int streamId);
  Future<Result<List<EpgProgram>>> getShortEpg(
    int streamId, {
    int limit = 4,
  });
}
