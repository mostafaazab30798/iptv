import 'package:iptv/data/datasources/xtream_remote_datasource.dart';
import 'package:iptv/data/mappers/data_mapper.dart';
import 'package:iptv/domain/entities/channel.dart';
import 'package:iptv/domain/entities/epg_program.dart';

/// Provides finished programmes inside a channel's advertised archive window.
class CatchUpRepository {
  const CatchUpRepository(this._remoteDataSource);

  final XtreamRemoteDataSource _remoteDataSource;

  Future<List<EpgProgram>> getArchivedPrograms(Channel channel) async {
    if (!channel.hasTvArchive) return const [];
    final rows = await _remoteDataSource.getEpg(channel.streamId);
    final programs = <EpgProgram>[];
    for (final row in rows) {
      final program = DataMapper.epgFromListing(
        row,
        channelId: channel.streamId,
      );
      if (program != null) programs.add(program);
    }
    return filterArchivedPrograms(
      programs,
      now: DateTime.now(),
      archiveDays: channel.tvArchiveDuration ?? 1,
    );
  }
}

/// Keeps completed programmes within a bounded provider archive window.
///
/// Kept pure so provider clock/window edge cases can be covered without an
/// HTTP fixture.
List<EpgProgram> filterArchivedPrograms(
  Iterable<EpgProgram> programs, {
  required DateTime now,
  required int archiveDays,
}) {
  final utcNow = now.toUtc();
  final boundedDays = archiveDays.clamp(1, 30);
  final oldest = utcNow.subtract(Duration(days: boundedDays));
  final result =
      programs
          .where(
            (program) =>
                !program.end.toUtc().isAfter(utcNow) &&
                !program.start.toUtc().isBefore(oldest),
          )
          .toList()
        ..sort((a, b) => b.start.compareTo(a.start));
  return List<EpgProgram>.unmodifiable(result);
}
