import 'package:equatable/equatable.dart';

/// Platform and backend specific capabilities.
class PlayerCapabilities extends Equatable {
  const PlayerCapabilities({
    this.playPause = true,
    this.seek = true,
    this.volume = true,
    this.fullscreen = true,
    this.audioTracks = false,
    this.subtitles = false,
    this.aspectRatio = true,
    this.pictureInPicture = false,
    this.liveSeek = false,
    this.retry = true,
    this.hardwareAcceleration = true,
  });

  final bool playPause;
  final bool seek;
  final bool volume;
  final bool fullscreen;
  final bool audioTracks;
  final bool subtitles;
  final bool aspectRatio;
  final bool pictureInPicture;
  final bool liveSeek;
  final bool retry;
  final bool hardwareAcceleration;

  static const defaultCapabilities = PlayerCapabilities();

  PlayerCapabilities copyWith({
    bool? playPause,
    bool? seek,
    bool? volume,
    bool? fullscreen,
    bool? audioTracks,
    bool? subtitles,
    bool? aspectRatio,
    bool? pictureInPicture,
    bool? liveSeek,
    bool? retry,
    bool? hardwareAcceleration,
  }) {
    return PlayerCapabilities(
      playPause: playPause ?? this.playPause,
      seek: seek ?? this.seek,
      volume: volume ?? this.volume,
      fullscreen: fullscreen ?? this.fullscreen,
      audioTracks: audioTracks ?? this.audioTracks,
      subtitles: subtitles ?? this.subtitles,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      pictureInPicture: pictureInPicture ?? this.pictureInPicture,
      liveSeek: liveSeek ?? this.liveSeek,
      retry: retry ?? this.retry,
      hardwareAcceleration: hardwareAcceleration ?? this.hardwareAcceleration,
    );
  }

  @override
  List<Object?> get props => [
        playPause,
        seek,
        volume,
        fullscreen,
        audioTracks,
        subtitles,
        aspectRatio,
        pictureInPicture,
        liveSeek,
        retry,
        hardwareAcceleration,
      ];
}
