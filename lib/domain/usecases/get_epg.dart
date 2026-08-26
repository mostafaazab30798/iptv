import 'package:iptv/core/utils/result.dart';
import 'package:iptv/domain/entities/epg_program.dart';
import 'package:iptv/domain/repositories/epg_repository.dart';

class GetEpgUseCase {
  const GetEpgUseCase(this._repository);

  final EpgRepository _repository;

  Future<Result<List<EpgProgram>>> call(
    String epgChannelId, {
    DateTime? from,
    DateTime? to,
    bool forceRefresh = false,
  }) {
    return _repository.getProgramsForChannel(
      epgChannelId,
      from: from,
      to: to,
      forceRefresh: forceRefresh,
    );
  }

  Future<Result<EpgProgram?>> getCurrentProgram(String epgChannelId) {
    return _repository.getCurrentProgram(epgChannelId);
  }
}
