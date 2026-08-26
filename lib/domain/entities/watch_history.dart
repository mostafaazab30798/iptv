import 'package:equatable/equatable.dart';

enum WatchHistoryType { channel, movie, episode }

class WatchHistoryEntry extends Equatable {
  const WatchHistoryEntry({
    required this.id,
    required this.type,
    required this.itemId,
    required this.name,
    this.imageUrl,
    this.positionSecs = 0,
    this.durationSecs,
    required this.watchedAt,
  });

  final int id;
  final WatchHistoryType type;
  final int itemId;
  final String name;
  final String? imageUrl;
  final int positionSecs;
  final int? durationSecs;
  final DateTime watchedAt;

  double get progressFraction {
    if (durationSecs == null || durationSecs == 0) return 0;
    return (positionSecs / durationSecs!).clamp(0.0, 1.0);
  }

  bool get isFinished => progressFraction >= 0.9;

  WatchHistoryEntry copyWith({
    int? id,
    WatchHistoryType? type,
    int? itemId,
    String? name,
    String? imageUrl,
    int? positionSecs,
    int? durationSecs,
    DateTime? watchedAt,
  }) {
    return WatchHistoryEntry(
      id: id ?? this.id,
      type: type ?? this.type,
      itemId: itemId ?? this.itemId,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      positionSecs: positionSecs ?? this.positionSecs,
      durationSecs: durationSecs ?? this.durationSecs,
      watchedAt: watchedAt ?? this.watchedAt,
    );
  }

  @override
  List<Object?> get props => [id, type, itemId, positionSecs, durationSecs, watchedAt];
}

