import 'package:equatable/equatable.dart';

class Channel extends Equatable {
  const Channel({
    required this.id,
    required this.serverId,
    required this.streamId,
    required this.name,
    this.categoryId,
    this.streamIcon,
    this.epgChannelId,
    this.hasTvArchive = false,
    this.tvArchiveDuration,
  });

  final int id;
  final int serverId;
  final int streamId;
  final String name;
  final int? categoryId;
  final String? streamIcon;
  final String? epgChannelId;
  final bool hasTvArchive;
  final int? tvArchiveDuration;

  @override
  List<Object?> get props => [id, serverId, streamId];
}
