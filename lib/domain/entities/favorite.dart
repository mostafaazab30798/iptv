import 'package:equatable/equatable.dart';

enum FavoriteType { channel, movie, series }

class Favorite extends Equatable {
  const Favorite({
    required this.id,
    required this.type,
    required this.itemId,
    required this.name,
    this.imageUrl,
    required this.addedAt,
  });

  final int id;
  final FavoriteType type;
  final int itemId;
  final String name;
  final String? imageUrl;
  final DateTime addedAt;

  @override
  List<Object?> get props => [id, type, itemId];
}
