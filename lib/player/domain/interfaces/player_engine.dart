import 'package:iptv/player/domain/entities/player_metrics.dart';
import 'package:iptv/player/domain/entities/player_source.dart';
import 'package:iptv/player/domain/entities/player_track.dart';
import 'package:iptv/player/domain/enums/playback_buffer_mode.dart';
import 'package:iptv/player/domain/enums/player_error_type.dart';
import 'package:iptv/player/domain/enums/player_status.dart';
import 'package:iptv/player/domain/enums/software_decode_fallback_tier.dart';

/// Abstract contract for low-level media playback engines (MediaKit, ExoPlayer, Fake, etc.)
abstract interface class PlayerEngine {
  /// Initializes backend-specific drivers/libraries.
  Future<void> initialize();

  /// Opens and starts buffering/playing the given [source].
  Future<void> open(PlayerSource source);

  /// Resumes playback.
  Future<void> play();

  /// Pauses playback.
  Future<void> pause();

  /// Stops playback and releases active decoders.
  Future<void> stop();

  /// Seeks to [position].
  Future<void> seek(Duration position);

  /// Seeks relatively by [offset] (e.g. +10s or -10s).
  Future<void> seekRelative(Duration offset);

  /// Sets playback speed multiplier (0.25x to 2.0x).
  Future<void> setPlaybackRate(double rate);

  /// Sets volume (0.0 to 1.0).
  Future<void> setVolume(double volume);

  /// Mutes or unmutes audio.
  Future<void> setMuted(bool muted);

  /// Selects an audio track.
  Future<void> setAudioTrack(PlayerAudioTrack track);

  /// Selects a subtitle track.
  Future<void> setSubtitleTrack(PlayerSubtitleTrack track);

  /// Updates buffer sizing preset (low-latency, balanced, stability).
  Future<void> setBufferMode(PlaybackBufferMode mode);

  /// Applies or clears the two-tier software decode escalation strategy.
  ///
  /// - [SoftwareDecodeFallbackTier.none]: Reset to defaults (HW active).
  /// - [SoftwareDecodeFallbackTier.loopFilterSkip]: Skip loop filter on non-key frames (Tier 1).
  /// - [SoftwareDecodeFallbackTier.frameSkip]: Also skip non-reference frames (Tier 2).
  Future<void> applySoftwareDecodeEscalation(SoftwareDecodeFallbackTier tier);

  /// Re-attempts playback of the current source.
  Future<void> retry();

  /// Disposes all media and native handles.
  Future<void> dispose();


  // Streams
  Stream<PlayerStatus> get statusStream;
  Stream<Duration> get positionStream;
  Stream<Duration> get durationStream;
  Stream<Duration> get bufferStream;
  Stream<PlayerErrorType> get errorStream;
  Stream<List<PlayerAudioTrack>> get audioTracksStream;
  Stream<List<PlayerSubtitleTrack>> get subtitleTracksStream;
  Stream<PlayerMetrics> get metricsStream;

  // Immediate state access
  PlayerStatus get currentStatus;
  Duration get currentPosition;
  Duration get currentDuration;
  PlayerSource? get currentSource;

  /// Low-level platform or widget handle (e.g. MediaKit VideoController or VideoPlayerController).
  dynamic get platformHandle;
}
