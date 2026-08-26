import 'package:equatable/equatable.dart';

enum CategoryType { live, vod, series }

class Category extends Equatable {
  const Category({
    required this.id,
    required this.serverId,
    required this.type,
    required this.name,
    this.parentId,
  });

  final int id;
  final int serverId;
  final CategoryType type;
  final String name;
  final int? parentId;

  @override
  List<Object?> get props => [id, serverId, type];
}
