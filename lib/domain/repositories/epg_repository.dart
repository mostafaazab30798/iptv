import 'package:iptv/core/utils/result.dart';
import 'package:iptv/domain/entities/epg_program.dart';

abstract interface class EpgRepository {
  Future<Result<List<EpgProgram>>> getProgramsForChannel(
    String epgChannelId, {
    DateTime? from,
    DateTime? to,
    bool forceRefresh = false,
  });

  Future<Result<EpgProgram?>> getCurrentProgram(String epgChannelId);
}
