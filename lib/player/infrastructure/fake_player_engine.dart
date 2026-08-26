import 'dart:async';
import 'package:iptv/player/domain/entities/player_metrics.dart';
import 'package:iptv/player/domain/entities/player_source.dart';
import 'package:iptv/player/domain/entities/player_track.dart';
import 'package:iptv/player/domain/enums/playback_buffer_mode.dart';
import 'package:iptv/player/domain/enums/player_error_type.dart';
import 'package:iptv/player/domain/enums/player_status.dart';
import 'package:iptv/player/domain/enums/software_decode_fallback_tier.dart';
import 'package:iptv/player/domain/interfaces/player_engine.dart';

/// Deterministic fake [PlayerEngine] for unit and widget testing without real hardware/network media.
class FakePlayerEngine implements PlayerEngine {
  final _statusController = StreamController<PlayerStatus>.broadcast();
  final _positionController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration>.broadcast();
  final _bufferController = StreamController<Duration>.broadcast();
  final _errorController = StreamController<PlayerErrorType>.broadcast();
  final _audioTracksController = StreamController<List<PlayerAudioTrack>>.broadcast();
  final _subtitleTracksController = StreamController<List<PlayerSubtitleTrack>>.broadcast();
  final _metricsController = StreamController<PlayerMetrics>.broadcast();

  PlayerStatus _status = PlayerStatus.idle;
  Duration _position = Duration.zero;
  final Duration _duration = const Duration(minutes: 90);
  PlayerSource? _currentSource;
  final PlayerMetrics _metrics = PlayerMetrics.empty;
  double _volume = 1.0;
  bool _muted = false;
  PlayerAudioTrack? _selectedAudioTrack;
  PlayerSubtitleTrack? _selectedSubtitleTrack;

  bool shouldFailOnOpen = false;
  PlayerErrorType failureErrorType = PlayerErrorType.networkUnavailable;
  Duration openDelay = Duration.zero;

  /// Tracks the last tier applied via [applySoftwareDecodeEscalation] for test assertions.
  SoftwareDecodeFallbackTier lastAppliedSwDecodeTier = SoftwareDecodeFallbackTier.none;

  @override
  PlayerStatus get currentStatus => _status;

  @override
  Duration get currentPosition => _position;

  @override
  Duration get currentDuration => _duration;

  @override
  PlayerSource? get currentSource => _currentSource;

  @override
  dynamic get platformHandle => 'fake_handle';

  PlayerMetrics get currentMetrics => _metrics;

  double get volume => _volume;
  bool get isMuted => _muted;
  PlayerAudioTrack? get selectedAudioTrack => _selectedAudioTrack;
  PlayerSubtitleTrack? get selectedSubtitleTrack => _selectedSubtitleTrack;

  @override
  Stream<PlayerStatus> get statusStream => _statusController.stream;

  @override
  Stream<Duration> get positionStream => _positionController.stream;

  @override
  Stream<Duration> get durationStream => _durationController.stream;

  @override
  Stream<Duration> get bufferStream => _bufferController.stream;

  @override
  Stream<PlayerErrorType> get errorStream => _errorController.stream;

  @override
  Stream<List<PlayerAudioTrack>> get audioTracksStream => _audioTracksController.stream;

  @override
  Stream<List<PlayerSubtitleTrack>> get subtitleTracksStream => _subtitleTracksController.stream;

  @override
  Stream<PlayerMetrics> get metricsStream => _metricsController.stream;

  @override
  Future<void> initialize() async {
    _emitStatus(PlayerStatus.idle);
  }

  @override
  Future<void> open(PlayerSource source) async {
    _currentSource = source;
    _emitStatus(PlayerStatus.loading);

    if (openDelay > Duration.zero) {
      await Future<void>.delayed(openDelay);
    }

    if (shouldFailOnOpen) {
      _emitStatus(PlayerStatus.error);
      if (!_errorController.isClosed) {
        _errorController.add(failureErrorType);
      }
      return;
    }

    _emitStatus(PlayerStatus.playing);
    _emitPosition(const Duration(seconds: 1));
    _audioTracksController.add([
      const PlayerAudioTrack(id: '1', title: 'English [Stereo]', language: 'eng'),
      const PlayerAudioTrack(id: '2', title: 'Arabic [5.1]', language: 'ara'),
    ]);
    _subtitleTracksController.add([
      PlayerSubtitleTrack.noTrack,
      const PlayerSubtitleTrack(id: '1', title: 'English', language: 'eng'),
      const PlayerSubtitleTrack(id: '2', title: 'Arabic', language: 'ara'),
    ]);
  }

  @override
  Future<void> play() async {
    _emitStatus(PlayerStatus.playing);
  }

  @override
  Future<void> pause() async {
    _emitStatus(PlayerStatus.paused);
  }

  @override
  Future<void> stop() async {
    _currentSource = null;
    _position = Duration.zero;
    _emitStatus(PlayerStatus.stopped);
  }

  double _playbackRate = 1.0;
  double get playbackRate => _playbackRate;

  @override
  Future<void> seek(Duration position) async {
    _position = position;
    _emitPosition(position);
  }

  @override
  Future<void> seekRelative(Duration offset) async {
    var target = _position + offset;
    if (target < Duration.zero) target = Duration.zero;
    if (target > _duration) target = _duration;
    _position = target;
    _emitPosition(target);
  }

  @override
  Future<void> setPlaybackRate(double rate) async {
    _playbackRate = rate;
  }

  @override
  Future<void> setVolume(double volume) async {
    _volume = volume;
  }

  @override
  Future<void> setMuted(bool muted) async {
    _muted = muted;
  }

  @override
  Future<void> setAudioTrack(PlayerAudioTrack track) async {
    _selectedAudioTrack = track;
  }

  @override
  Future<void> setSubtitleTrack(PlayerSubtitleTrack track) async {
    _selectedSubtitleTrack = track;
  }

  @override
  Future<void> setBufferMode(PlaybackBufferMode mode) async {
    // Simulated buffer mode change
  }

  @override
  Future<void> applySoftwareDecodeEscalation(SoftwareDecodeFallbackTier tier) async {
    lastAppliedSwDecodeTier = tier;
  }

  @override
  Future<void> retry() async {
    if (_currentSource != null) {
      await open(_currentSource!);
    }
  }

  @override
  Future<void> dispose() async {
    _emitStatus(PlayerStatus.disposed);
    await _statusController.close();
    await _positionController.close();
    await _durationController.close();
    await _bufferController.close();
    await _errorController.close();
    await _audioTracksController.close();
    await _subtitleTracksController.close();
    await _metricsController.close();
  }

  // Helpers for tests
  void simulateBuffering() => _emitStatus(PlayerStatus.buffering);
  void simulatePlaying() => _emitStatus(PlayerStatus.playing);
  void simulateError(PlayerErrorType err) {
    _emitStatus(PlayerStatus.error);
    if (!_errorController.isClosed) _errorController.add(err);
  }
  void simulateCompleted() => _emitStatus(PlayerStatus.completed);

  void _emitStatus(PlayerStatus status) {
    _status = status;
    if (!_statusController.isClosed) _statusController.add(status);
  }

  void _emitPosition(Duration pos) {
    _position = pos;
    if (!_positionController.isClosed) _positionController.add(pos);
  }
}
