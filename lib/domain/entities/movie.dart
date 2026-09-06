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
    this.country,
    this.releaseDate,
    this.backdropPaths,
    this.videoResolution,
    this.mpaaRating,
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
  final String? country;
  final String? releaseDate;
  final List<String>? backdropPaths;
  final String? videoResolution;
  final String? mpaaRating;

  Duration? get duration =>
      durationSecs != null ? Duration(seconds: durationSecs!) : null;

  Movie copyWith({
    int? id,
    int? serverId,
    int? streamId,
    String? name,
    int? categoryId,
    String? streamIcon,
    String? rating,
    String? genre,
    String? plot,
    String? cast,
    String? director,
    int? releaseYear,
    int? durationSecs,
    String? containerExtension,
    String? country,
    String? releaseDate,
    List<String>? backdropPaths,
    String? videoResolution,
    String? mpaaRating,
  }) {
    return Movie(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      streamId: streamId ?? this.streamId,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      streamIcon: streamIcon ?? this.streamIcon,
      rating: rating ?? this.rating,
      genre: genre ?? this.genre,
      plot: plot ?? this.plot,
      cast: cast ?? this.cast,
      director: director ?? this.director,
      releaseYear: releaseYear ?? this.releaseYear,
      durationSecs: durationSecs ?? this.durationSecs,
      containerExtension: containerExtension ?? this.containerExtension,
      country: country ?? this.country,
      releaseDate: releaseDate ?? this.releaseDate,
      backdropPaths: backdropPaths ?? this.backdropPaths,
      videoResolution: videoResolution ?? this.videoResolution,
      mpaaRating: mpaaRating ?? this.mpaaRating,
    );
  }

  @override
  List<Object?> get props => [id, serverId, streamId];
}
