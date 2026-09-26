import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:iptv/player/domain/entities/player_metrics.dart';
import 'package:iptv/player/domain/entities/player_source.dart';
import 'package:iptv/player/domain/entities/player_track.dart';
import 'package:iptv/player/domain/enums/playback_buffer_mode.dart';
import 'package:iptv/player/domain/enums/player_backend.dart';
import 'package:iptv/player/domain/enums/player_error_type.dart';
import 'package:iptv/player/domain/enums/player_status.dart';
import 'package:iptv/player/domain/enums/software_decode_fallback_tier.dart';
import 'package:iptv/player/domain/interfaces/player_engine.dart';
import 'package:video_player/video_player.dart';

/// Android backends used when the viewer explicitly selects Media3 or VLC.
/// video_player_android is the endorsed Media3 implementation of video_player.
class AndroidAlternativePlayerEngine implements PlayerEngine {
  AndroidAlternativePlayerEngine(this.backend);

  final PlayerBackend backend;
  final _status = StreamController<PlayerStatus>.broadcast();
  final _position = StreamController<Duration>.broadcast();
  final _duration = StreamController<Duration>.broadcast();
  final _buffer = StreamController<Duration>.broadcast();
  final _errors = StreamController<PlayerErrorType>.broadcast();
  final _audioTracks = StreamController<List<PlayerAudioTrack>>.broadcast();
  final _subtitleTracks =
      StreamController<List<PlayerSubtitleTrack>>.broadcast();
  final _metrics = StreamController<PlayerMetrics>.broadcast();

  VideoPlayerController? _media3;
  VlcPlayerController? _vlc;
  PlayerSource? _source;
  PlayerStatus _currentStatus = PlayerStatus.idle;
  Duration _currentPosition = Duration.zero;
  Duration _currentDuration = Duration.zero;
  PlaybackBufferMode _bufferMode = PlaybackBufferMode.balanced;
  double _volumeLevel = 1;
  bool _muted = false;
  bool _vlcTracksRefreshed = false;
  int _generation = 0;
  bool _closed = false;

  @override
  Future<void> initialize() async {}

  void _setStatus(PlayerStatus status) {
    if (_closed || _currentStatus == status) return;
    _currentStatus = status;
    _status.add(status);
  }

  void _setPosition(Duration value) {
    if (_closed || _currentPosition == value) return;
    _currentPosition = value;
    _position.add(value);
  }

  void _setDuration(Duration value) {
    if (_closed || _currentDuration == value) return;
    _currentDuration = value;
    _duration.add(value);
  }

  void _onMedia3Value(VideoPlayerController controller, int generation) {
    if (_closed || generation != _generation) return;
    final value = controller.value;
    if (value.hasError) {
      _setStatus(PlayerStatus.error);
      _errors.add(PlayerErrorType.playbackFailure);
      return;
    }
    _setPosition(value.position);
    _setDuration(value.duration);
    if (value.buffered.isNotEmpty) {
      _buffer.add(value.buffered.last.end);
    }
    _setStatus(
      value.isBuffering
          ? PlayerStatus.buffering
          : value.isPlaying
          ? PlayerStatus.playing
          : value.isCompleted
          ? PlayerStatus.completed
          : value.isInitialized
          ? PlayerStatus.paused
          : PlayerStatus.loading,
    );
  }

  void _onVlcValue(VlcPlayerController controller, int generation) {
    if (_closed || generation != _generation) return;
    final value = controller.value;
    if (value.hasError) {
      _setStatus(PlayerStatus.error);
      _errors.add(PlayerErrorType.playbackFailure);
      return;
    }
    _setPosition(value.position);
    _setDuration(value.duration);
    if (value.isPlaying && !_vlcTracksRefreshed) {
      _vlcTracksRefreshed = true;
      unawaited(_refreshVlcTracks(controller));
    }
    _setStatus(
      value.isBuffering
          ? PlayerStatus.buffering
          : value.isPlaying
          ? PlayerStatus.playing
          : value.isEnded
          ? PlayerStatus.completed
          : value.isInitialized
          ? PlayerStatus.paused
          : PlayerStatus.loading,
    );
  }

  Future<void> _refreshVlcTracks(VlcPlayerController controller) async {
    try {
      final audio = await controller.getAudioTracks();
      final subtitles = await controller.getSpuTracks();
      if (_vlc != controller || _closed) return;
      _audioTracks.add([
        for (final entry in audio.entries)
          PlayerAudioTrack(id: '${entry.key}', title: entry.value),
      ]);
      _subtitleTracks.add([
        PlayerSubtitleTrack.noTrack,
        for (final entry in subtitles.entries)
          if (entry.key >= 0)
            PlayerSubtitleTrack(id: '${entry.key}', title: entry.value),
      ]);
    } catch (_) {
      // Some live streams do not expose a track list until later.
      _vlcTracksRefreshed = false;
    }
  }

  Future<void> _configureVlcAfterInit(
    VlcPlayerController controller,
    PlayerSource source,
    int generation,
  ) async {
    if (_closed || generation != _generation || _vlc != controller) return;
    try {
      await controller.setVolume(_muted ? 0 : (_volumeLevel * 100).round());
      if (source.startAt case final start?) await controller.seekTo(start);
    } catch (_) {
      if (!_closed && generation == _generation && _vlc == controller) {
        _setStatus(PlayerStatus.error);
        _errors.add(PlayerErrorType.playbackFailure);
      }
    }
  }

  @override
  Future<void> open(PlayerSource source) async {
    await stop();
    if (_closed) return;
    _source = source;
    _vlcTracksRefreshed = false;
    final generation = ++_generation;
    _setStatus(PlayerStatus.loading);
    _metrics.add(PlayerMetrics(bufferMode: _bufferMode));
    try {
      if (backend == PlayerBackend.media3) {
        final controller = VideoPlayerController.networkUrl(
          Uri.parse(source.url),
          httpHeaders: source.headers,
        );
        _media3 = controller;
        controller.addListener(() => _onMedia3Value(controller, generation));
        await controller.initialize();
        if (generation != _generation) return;
        if (source.startAt case final start?) await controller.seekTo(start);
        await controller.setVolume(_muted ? 0 : _volumeLevel);
        await controller.play();
      } else {
        final unsupportedHeaders = source.headers.keys.where((key) {
          final normalized = key.toLowerCase();
          return normalized != 'user-agent' && normalized != 'referer';
        });
        if (unsupportedHeaders.isNotEmpty) {
          _setStatus(PlayerStatus.error);
          _errors.add(PlayerErrorType.invalidSource);
          return;
        }
        final userAgent = source.headers.entries
            .where((entry) => entry.key.toLowerCase() == 'user-agent')
            .map((entry) => entry.value)
            .firstOrNull;
        final referer = source.headers.entries
            .where((entry) => entry.key.toLowerCase() == 'referer')
            .map((entry) => entry.value)
            .firstOrNull;
        final controller = VlcPlayerController.network(
          source.url,
          autoPlay: true,
          hwAcc: HwAcc.auto,
          options: VlcPlayerOptions(
            http: VlcHttpOptions([
              VlcHttpOptions.httpReconnect(true),
              if (userAgent != null) VlcHttpOptions.httpUserAgent(userAgent),
              if (referer != null) VlcHttpOptions.httpReferrer(referer),
            ]),
          ),
        );
        _vlc = controller;
        // VlcPlayer supplies the native view id and initializes the controller.
        // Configure playback only after that platform-view handshake completes.
        _setStatus(PlayerStatus.buffering);
        controller.addListener(() => _onVlcValue(controller, generation));
        controller.addOnInitListener(() {
          unawaited(_configureVlcAfterInit(controller, source, generation));
        });
      }
    } catch (_) {
      if (generation == _generation && !_closed) {
        _setStatus(PlayerStatus.error);
        _errors.add(PlayerErrorType.playbackFailure);
      }
    }
  }

  @override
  Future<void> play() async {
    if (_media3 case final controller?) await controller.play();
    if (_vlc case final controller?) await controller.play();
  }

  @override
  Future<void> pause() async {
    if (_media3 case final controller?) await controller.pause();
    if (_vlc case final controller?) await controller.pause();
  }

  @override
  Future<void> stop() async {
    ++_generation;
    final media3 = _media3;
    final vlc = _vlc;
    _media3 = null;
    _vlc = null;
    _source = null;
    _currentPosition = Duration.zero;
    _currentDuration = Duration.zero;
    await media3?.dispose();
    // An unmounted VlcPlayerController has no native view id to dispose.
    if (vlc?.isReadyToInitialize == true) await vlc?.dispose();
    _setStatus(PlayerStatus.stopped);
  }

  @override
  Future<void> seek(Duration position) async {
    if (_media3 case final controller?) await controller.seekTo(position);
    if (_vlc case final controller?) await controller.seekTo(position);
    _setPosition(position);
  }

  @override
  Future<void> seekRelative(Duration offset) => seek(_currentPosition + offset);

  @override
  Future<void> seekForPreview(Duration position) => seek(position);

  @override
  Future<Uint8List?> captureFrame() async => null;

  @override
  Future<void> setPlaybackRate(double rate) async {
    if (_media3 case final controller?) await controller.setPlaybackSpeed(rate);
    if (_vlc case final controller?) await controller.setPlaybackSpeed(rate);
  }

  @override
  Future<void> setVolume(double volume) async {
    _volumeLevel = volume.clamp(0, 1);
    if (_media3 case final controller?) {
      await controller.setVolume(_muted ? 0 : _volumeLevel);
    }
    if (_vlc case final controller?) {
      await controller.setVolume(_muted ? 0 : (_volumeLevel * 100).round());
    }
  }

  @override
  Future<void> setMuted(bool muted) async {
    _muted = muted;
    await setVolume(_volumeLevel);
  }

  @override
  Future<void> setAudioTrack(PlayerAudioTrack track) async {
    final id = int.tryParse(track.id);
    if (id != null) {
      if (_vlc case final controller?) await controller.setAudioTrack(id);
    }
  }

  @override
  Future<void> setSubtitleTrack(PlayerSubtitleTrack track) async {
    final id = track == PlayerSubtitleTrack.noTrack
        ? -1
        : int.tryParse(track.id);
    if (id != null) {
      if (_vlc case final controller?) await controller.setSpuTrack(id);
    }
  }

  @override
  Future<void> setBufferMode(PlaybackBufferMode mode) async {
    _bufferMode = mode;
    _metrics.add(PlayerMetrics(bufferMode: mode));
  }

  @override
  Future<void> applySoftwareDecodeEscalation(
    SoftwareDecodeFallbackTier tier,
  ) async {}

  @override
  Future<void> retry() async {
    final source = _source;
    if (source != null) await open(source);
  }

  @override
  Future<void> dispose() async {
    await stop();
    _closed = true;
    await Future.wait([
      _status.close(),
      _position.close(),
      _duration.close(),
      _buffer.close(),
      _errors.close(),
      _audioTracks.close(),
      _subtitleTracks.close(),
      _metrics.close(),
    ]);
  }

  @override
  PlayerStatus get currentStatus => _currentStatus;
  @override
  Duration get currentPosition => _currentPosition;
  @override
  Duration get currentDuration => _currentDuration;
  @override
  PlayerSource? get currentSource => _source;
  @override
  dynamic get platformHandle => _media3 ?? _vlc;
  @override
  Stream<PlayerStatus> get statusStream => _status.stream;
  @override
  Stream<Duration> get positionStream => _position.stream;
  @override
  Stream<Duration> get durationStream => _duration.stream;
  @override
  Stream<Duration> get bufferStream => _buffer.stream;
  @override
  Stream<PlayerErrorType> get errorStream => _errors.stream;
  @override
  Stream<List<PlayerAudioTrack>> get audioTracksStream => _audioTracks.stream;
  @override
  Stream<List<PlayerSubtitleTrack>> get subtitleTracksStream =>
      _subtitleTracks.stream;
  @override
  Stream<PlayerMetrics> get metricsStream => _metrics.stream;
}
