import 'package:equatable/equatable.dart';

class Movie extends Equatable {
  const Movie({
    required this.id,
    required this.serverId,
    required this.streamId,
    required this.name,
    this.categoryId,
    this.streamIcon,
    this.rating,
    this.genre,
    this.plot,
    this.cast,
    this.director,
    this.releaseYear,
    this.durationSecs,
    this.containerExtension,
  });

  final int id;
  final int serverId;
  final int streamId;
  final String name;
  final int? categoryId;
  final String? streamIcon;
  final String? rating;
  final String? genre;
  final String? plot;
  final String? cast;
  final String? director;
  final int? releaseYear;
  final int? durationSecs;
  final String? containerExtension;

  Duration? get duration =>
      durationSecs != null ? Duration(seconds: durationSecs!) : null;

  @override
  List<Object?> get props => [id, serverId, streamId];
}
