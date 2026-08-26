import 'package:iptv/core/utils/result.dart';
import 'package:iptv/data/datasources/xtream_remote_datasource.dart';
import 'package:iptv/domain/entities/epg_program.dart';
import 'package:iptv/domain/repositories/epg_repository.dart';

class EpgRepositoryImpl implements EpgRepository {
  const EpgRepositoryImpl({required this.remoteDataSource});

  final XtreamRemoteDataSource remoteDataSource;

  @override
  Future<Result<List<EpgProgram>>> getProgramsForChannel(
    String epgChannelId, {
    DateTime? from,
    DateTime? to,
    bool forceRefresh = false,
  }) async {
    try {
      final streamId = int.tryParse(epgChannelId) ?? 0;
      final raw = await remoteDataSource.getShortEpg(streamId);
      final programs = raw.map((j) {
        return EpgProgram(
          id: int.tryParse(j['id']?.toString() ?? '0') ?? 0,
          epgId: epgChannelId,
          title: j['title']?.toString() ?? '',
          description: j['description']?.toString(),
          start: DateTime.tryParse(j['start']?.toString() ?? '') ?? DateTime.now(),
          end: DateTime.tryParse(j['end']?.toString() ?? '') ?? DateTime.now().add(const Duration(hours: 1)),
        );
      }).toList();
      return Ok(programs);
    } catch (e) {
      return Err(AppResultError('Failed to load EPG programs', cause: e));
    }
  }

  @override
  Future<Result<EpgProgram?>> getCurrentProgram(String epgChannelId) async {
    final res = await getProgramsForChannel(epgChannelId);
    return res.map((list) {
      final now = DateTime.now();
      try {
        return list.firstWhere((p) => p.start.isBefore(now) && p.end.isAfter(now));
      } catch (_) {
        return list.isNotEmpty ? list.first : null;
      }
    });
  }
}
