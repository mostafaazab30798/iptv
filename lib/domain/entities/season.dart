import 'package:equatable/equatable.dart';

class Season extends Equatable {
  const Season({
    required this.id,
    required this.seriesLocalId,
    required this.seasonNumber,
    this.name,
    this.cover,
    this.episodes = const [],
  });

  final int id;
  final int seriesLocalId;
  final int seasonNumber;
  final String? name;
  final String? cover;
  final List<Episode> episodes;

  @override
  List<Object?> get props => [id, seriesLocalId, seasonNumber];
}

class Episode extends Equatable {
  const Episode({
    required this.id,
    required this.seasonLocalId,
    required this.episodeNum,
    required this.title,
    required this.streamId,
    this.containerExtension,
    this.durationSecs,
    this.plot,
    this.cover,
  });

  final int id;
  final int seasonLocalId;
  final int episodeNum;
  final String title;
  final int streamId;
  final String? containerExtension;
  final int? durationSecs;
  final String? plot;
  final String? cover;

  Duration? get duration =>
      durationSecs != null ? Duration(seconds: durationSecs!) : null;

  @override
  List<Object?> get props => [id, seasonLocalId, episodeNum];
}
