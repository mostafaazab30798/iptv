import 'package:equatable/equatable.dart';

/// Audio track representation.
class PlayerAudioTrack extends Equatable {
  const PlayerAudioTrack({
    required this.id,
    required this.title,
    this.language,
    this.channels,
    this.bitrate,
  });

  final String id;
  final String title;
  final String? language;
  final int? channels;
  final int? bitrate;

  static const auto = PlayerAudioTrack(id: 'auto', title: 'Auto');

  @override
  List<Object?> get props => [id, title, language, channels, bitrate];
}

/// Subtitle track representation.
class PlayerSubtitleTrack extends Equatable {
  const PlayerSubtitleTrack({
    required this.id,
    required this.title,
    this.language,
  });

  final String id;
  final String title;
  final String? language;

  static const noTrack = PlayerSubtitleTrack(id: 'no', title: 'Off');
  static const auto = PlayerSubtitleTrack(id: 'auto', title: 'Auto');

  @override
  List<Object?> get props => [id, title, language];
}
