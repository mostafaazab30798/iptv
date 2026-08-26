import 'package:equatable/equatable.dart';

class EpgProgram extends Equatable {
  const EpgProgram({
    required this.id,
    required this.epgId,
    this.channelId,
    required this.title,
    this.description,
    required this.start,
    required this.end,
    this.lang = 'en',
  });

  final int id;
  final String epgId;
  final int? channelId;
  final String title;
  final String? description;
  final DateTime start;
  final DateTime end;
  final String lang;

  Duration get duration => end.difference(start);
  bool get isLive => DateTime.now().isAfter(start) && DateTime.now().isBefore(end);
  double get progress {
    if (!isLive) return 0;
    final elapsed = DateTime.now().difference(start).inSeconds;
    return (elapsed / duration.inSeconds).clamp(0.0, 1.0);
  }

  @override
  List<Object?> get props => [id, epgId, start, end];
}
