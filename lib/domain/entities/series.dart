import 'package:equatable/equatable.dart';

class Series extends Equatable {
  const Series({
    required this.id,
    required this.serverId,
    required this.seriesId,
    required this.name,
    this.categoryId,
    this.cover,
    this.plot,
    this.cast,
    this.director,
    this.genre,
    this.rating,
    this.releaseYear,
  });

  final int id;
  final int serverId;
  final int seriesId;
  final String name;
  final int? categoryId;
  final String? cover;
  final String? plot;
  final String? cast;
  final String? director;
  final String? genre;
  final String? rating;
  final int? releaseYear;

  @override
  List<Object?> get props => [id, serverId, seriesId];
}
