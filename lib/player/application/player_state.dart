import 'package:equatable/equatable.dart';
import 'package:iptv/player/domain/entities/player_capabilities.dart';
import 'package:iptv/player/domain/entities/player_metrics.dart';
import 'package:iptv/player/domain/entities/player_source.dart';
import 'package:iptv/player/domain/entities/player_track.dart';
import 'package:iptv/player/domain/enums/playback_buffer_mode.dart';
import 'package:iptv/player/domain/enums/player_error_type.dart';
import 'package:iptv/player/domain/enums/player_status.dart';

/// Immutable consolidated state for the IPTV player subsystem.
class PlayerState extends Equatable {
  const PlayerState({
    this.status = PlayerStatus.idle,
    this.source,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.bufferedPosition = Duration.zero,
    this.volume = 1.0,
    this.isMuted = false,
    this.isFullscreen = false,
    this.aspectRatioIndex = 0, // 0: Fit, 1: Fill, 2: 16:9, 3: 4:3
    this.playbackRate = 1.0,
    this.isLocked = false,
    this.bufferMode = PlaybackBufferMode.balanced,
    this.error,
    this.errorMessage,
    this.currentAudioTrack,
    this.currentSubtitleTrack,
    this.availableAudioTracks = const [],
    this.availableSubtitleTracks = const [],
    this.capabilities = PlayerCapabilities.defaultCapabilities,
    this.metrics = PlayerMetrics.empty,
  });

  final PlayerStatus status;
  final PlayerSource? source;
  final Duration position;
  final Duration duration;
  final Duration bufferedPosition;
  final double volume;
  final bool isMuted;
  final bool isFullscreen;
  final int aspectRatioIndex;
  final double playbackRate;
  final bool isLocked;
  final PlaybackBufferMode bufferMode;
  final PlayerErrorType? error;
  final String? errorMessage;
  final PlayerAudioTrack? currentAudioTrack;
  final PlayerSubtitleTrack? currentSubtitleTrack;
  final List<PlayerAudioTrack> availableAudioTracks;
  final List<PlayerSubtitleTrack> availableSubtitleTracks;
  final PlayerCapabilities capabilities;
  final PlayerMetrics metrics;

  static const initial = PlayerState();

  bool get isLive => source?.profile.isLive ?? (duration == Duration.zero);
  bool get isPlaying => status == PlayerStatus.playing;
  bool get isBuffering => status == PlayerStatus.buffering;
  bool get isLoading => status == PlayerStatus.loading || status == PlayerStatus.initializing;
  bool get hasError => status == PlayerStatus.error && error != null;

  double get bufferedFraction {
    if (duration == Duration.zero) return 0.0;
    return (bufferedPosition.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
  }

  double get progressFraction {
    if (duration == Duration.zero) return 0.0;
    return (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
  }

  PlayerState copyWith({
    PlayerStatus? status,
    PlayerSource? source,
    bool clearSource = false,
    Duration? position,
    Duration? duration,
    Duration? bufferedPosition,
    double? volume,
    bool? isMuted,
    bool? isFullscreen,
    int? aspectRatioIndex,
    double? playbackRate,
    bool? isLocked,
    PlaybackBufferMode? bufferMode,
    PlayerErrorType? error,
    bool clearError = false,
    String? errorMessage,
    PlayerAudioTrack? currentAudioTrack,
    PlayerSubtitleTrack? currentSubtitleTrack,
    List<PlayerAudioTrack>? availableAudioTracks,
    List<PlayerSubtitleTrack>? availableSubtitleTracks,
    PlayerCapabilities? capabilities,
    PlayerMetrics? metrics,
  }) {
    return PlayerState(
      status: status ?? this.status,
      source: clearSource ? null : (source ?? this.source),
      position: position ?? this.position,
      duration: duration ?? this.duration,
      bufferedPosition: bufferedPosition ?? this.bufferedPosition,
      volume: volume ?? this.volume,
      isMuted: isMuted ?? this.isMuted,
      isFullscreen: isFullscreen ?? this.isFullscreen,
      aspectRatioIndex: aspectRatioIndex ?? this.aspectRatioIndex,
      playbackRate: playbackRate ?? this.playbackRate,
      isLocked: isLocked ?? this.isLocked,
      bufferMode: bufferMode ?? this.bufferMode,
      error: clearError ? null : (error ?? this.error),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      currentAudioTrack: currentAudioTrack ?? this.currentAudioTrack,
      currentSubtitleTrack: currentSubtitleTrack ?? this.currentSubtitleTrack,
      availableAudioTracks: availableAudioTracks ?? this.availableAudioTracks,
      availableSubtitleTracks:
          availableSubtitleTracks ?? this.availableSubtitleTracks,
      capabilities: capabilities ?? this.capabilities,
      metrics: metrics ?? this.metrics,
    );
  }

  @override
  List<Object?> get props => [
        status,
        source,
        position,
        duration,
        bufferedPosition,
        volume,
        isMuted,
        isFullscreen,
        aspectRatioIndex,
        playbackRate,
        isLocked,
        bufferMode,
        error,
        errorMessage,
        currentAudioTrack,
        currentSubtitleTrack,
        availableAudioTracks,
        availableSubtitleTracks,
        capabilities,
        metrics,
      ];
}
