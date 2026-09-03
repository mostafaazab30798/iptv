import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart' as mk;
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:iptv/core/logging/app_logger.dart';
import 'package:iptv/player/domain/entities/player_source.dart';
import 'package:iptv/player/domain/enums/playback_profile.dart';
import 'package:iptv/player/handoff/application/companion_sync_engine.dart';
import 'package:iptv/player/handoff/domain/audio_handoff_models.dart';
import 'package:iptv/player/handoff/infrastructure/audio_handoff_client.dart';

class CompanionAudioState extends Equatable {
  const CompanionAudioState({
    this.connectionState = HandoffConnectionState.idle,
    this.sessionInfo,
    this.currentSource,
    this.isPlaying = false,
    this.isBuffering = false,
    this.driftMs = 0,
    this.isInSync = true,
    this.bluetoothOffsetMs = 0,
    this.volume = 1.0,
    this.isMuted = false,
    this.isTvMuted = false,
    this.networkRttMs = 20,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.errorMessage,
  });

  final HandoffConnectionState connectionState;
  final HandoffSessionInfo? sessionInfo;
  final PlayerSource? currentSource;
  final bool isPlaying;
  final bool isBuffering;
  final int driftMs;
  final bool isInSync;
  final int bluetoothOffsetMs;
  final double volume;
  final bool isMuted;
  final bool isTvMuted;
  final int networkRttMs;
  final Duration position;
  final Duration duration;
  final String? errorMessage;

  bool get isConnected => connectionState == HandoffConnectionState.connected;

  CompanionAudioState copyWith({
    HandoffConnectionState? connectionState,
    HandoffSessionInfo? sessionInfo,
    PlayerSource? currentSource,
    bool? isPlaying,
    bool? isBuffering,
    int? driftMs,
    bool? isInSync,
    int? bluetoothOffsetMs,
    double? volume,
    bool? isMuted,
    bool? isTvMuted,
    int? networkRttMs,
    Duration? position,
    Duration? duration,
    String? errorMessage,
  }) {
    return CompanionAudioState(
      connectionState: connectionState ?? this.connectionState,
      sessionInfo: sessionInfo ?? this.sessionInfo,
      currentSource: currentSource ?? this.currentSource,
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      driftMs: driftMs ?? this.driftMs,
      isInSync: isInSync ?? this.isInSync,
      bluetoothOffsetMs: bluetoothOffsetMs ?? this.bluetoothOffsetMs,
      volume: volume ?? this.volume,
      isMuted: isMuted ?? this.isMuted,
      isTvMuted: isTvMuted ?? this.isTvMuted,
      networkRttMs: networkRttMs ?? this.networkRttMs,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        connectionState,
        sessionInfo,
        currentSource,
        isPlaying,
        isBuffering,
        driftMs,
        isInSync,
        bluetoothOffsetMs,
        volume,
        isMuted,
        isTvMuted,
        networkRttMs,
        position,
        duration,
        errorMessage,
      ];
}

/// Controller that manages headless (audio-only) playback on the companion phone
/// and keeps it tightly synchronized with the TV playback stream.
class CompanionAudioController extends StateNotifier<CompanionAudioState> {
  CompanionAudioController({
    AudioHandoffClient? client,
  })  : _client = client ?? AudioHandoffClient(),
        super(const CompanionAudioState()) {
    _initSyncEngine();
    _initClientListeners();
  }

  final AudioHandoffClient _client;
  late final CompanionSyncEngine _syncEngine;
  mk.Player? _audioPlayer;
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  /// Fresh engine position for sync math; Riverpod [state.position] stays coarse.
  Duration _latestPosition = Duration.zero;
  static const _riverpodProgressThrottle = Duration(milliseconds: 250);
  DateTime? _lastPositionStateEmit;
  DateTime? _lastDurationStateEmit;

  AudioHandoffClient get client => _client;

  void _initSyncEngine() {
    _syncEngine = CompanionSyncEngine(
      microSeekThresholdMs: 100,
      hardSeekThresholdMs: 1500,
      onSeek: (targetPosition) async {
        if (_audioPlayer != null) {
          try {
            await _audioPlayer!.seek(targetPosition);
          } catch (e) {
            AppLogger.warning(
              'Companion seek error: $e',
              feature: 'audio_handoff',
            );
          }
        }
      },
      onAdjustRate: (rate) async {
        if (_audioPlayer != null) {
          try {
            await _audioPlayer!.setRate(rate);
          } catch (e) {
            AppLogger.warning(
              'Companion rate adjustment error: $e',
              feature: 'audio_handoff',
            );
          }
        }
      },
    );
  }

  void _initClientListeners() {
    _subscriptions.add(
      _client.stateStream.listen((connState) {
        state = state.copyWith(connectionState: connState);
        if (connState == HandoffConnectionState.disconnected ||
            connState == HandoffConnectionState.error) {
          _stopAudioPlayer();
        }
      }),
    );

    _subscriptions.add(
      _client.sourceStream.listen((source) {
        if (source.url.isEmpty) {
          unawaited(_stopAudioPlayer());
          state = state.copyWith(currentSource: source);
          return;
        }
        state = state.copyWith(currentSource: source);
        _syncEngine.reset();
        _syncEngine.setIsLive(source.isLive);
        _loadAudioStream(source);
      }),
    );

    _subscriptions.add(
      _client.syncStream.listen(_handleSyncPacket),
    );
  }

  /// Connects to a TV session using session info (from QR code or manual input).
  Future<bool> connect(HandoffSessionInfo sessionInfo) async {
    state = state.copyWith(
      sessionInfo: sessionInfo,
      currentSource: sessionInfo.source,
      connectionState: HandoffConnectionState.connecting,
      errorMessage: null,
    );

    try {
      await _client.connect(sessionInfo);
      if (_client.state == HandoffConnectionState.connected) {
        state = state.copyWith(connectionState: HandoffConnectionState.connected);
        // Audio follows over the socket; never block the remote sheet on mpv.
        if (sessionInfo.source.url.isNotEmpty) {
          unawaited(_loadAudioStream(sessionInfo.source));
        }
        return true;
      }
    } catch (e) {
      AppLogger.error('Companion connect error: $e', feature: 'audio_handoff');
    }

    state = state.copyWith(
      connectionState: HandoffConnectionState.error,
      errorMessage:
          'Could not connect to TV at ${sessionInfo.hostIp}:${sessionInfo.port}',
    );
    return false;
  }

  Future<void> _ensureAudioPlayerInitialized() async {
    if (_audioPlayer != null) return;

    _audioPlayer = mk.Player(
      configuration: const mk.PlayerConfiguration(),
    );

    // Optimized audio-only properties in libmpv
    if (_audioPlayer?.platform is mk.NativePlayer) {
      final native = _audioPlayer!.platform as mk.NativePlayer;
      await native.setProperty('vo', 'null'); // Disable video output rendering
      await native.setProperty('audio-pitch-correction', 'yes');
      await native.setProperty('audio-client-name', 'IPTV_Companion');
      await native.setProperty('force-window', 'no');
      await native.setProperty('idle', 'yes');
      await native.setProperty('keep-open', 'yes');
    }

    _subscriptions.add(
      _audioPlayer!.stream.position.listen((pos) {
        _latestPosition = pos;
        final now = DateTime.now();
        final due = _lastPositionStateEmit == null ||
            now.difference(_lastPositionStateEmit!) >= _riverpodProgressThrottle;
        if (due && state.position != pos) {
          _lastPositionStateEmit = now;
          state = state.copyWith(position: pos);
        }
      }),
    );

    _subscriptions.add(
      _audioPlayer!.stream.duration.listen((dur) {
        final now = DateTime.now();
        final due = _lastDurationStateEmit == null ||
            now.difference(_lastDurationStateEmit!) >= _riverpodProgressThrottle;
        if (due && state.duration != dur) {
          _lastDurationStateEmit = now;
          state = state.copyWith(duration: dur);
        }
      }),
    );

    _subscriptions.add(
      _audioPlayer!.stream.playing.listen((playing) {
        state = state.copyWith(isPlaying: playing);
      }),
    );

    _subscriptions.add(
      _audioPlayer!.stream.buffering.listen((buffering) {
        state = state.copyWith(isBuffering: buffering);
      }),
    );
  }

  String? _loadingUrl;

  Future<void> _loadAudioStream(PlayerSource source) async {
    if (source.url.isEmpty) return;
    if (_loadingUrl == source.url && _audioPlayer != null) return;
    _loadingUrl = source.url;

    try {
      await _ensureAudioPlayerInitialized();
      if (_audioPlayer == null) return;

      // Configure system audio session for background playback
      try {
        final session = await AudioSession.instance;
        await session.configure(const AudioSessionConfiguration.music());
        await session.setActive(true);
      } catch (e) {
        AppLogger.warning(
          'Could not activate audio session: $e',
          feature: 'audio_handoff',
        );
      }

      // Keep network socket and CPU alive when screen is locked
      try {
        await WakelockPlus.enable();
      } catch (e) {
        AppLogger.warning(
          'Could not enable wakelock: $e',
          feature: 'audio_handoff',
        );
      }

      _syncEngine.setIsLive(source.isLive);
      await _applyAudioDelay(state.bluetoothOffsetMs);

      // Live: start immediately at the live edge. VOD: wait for the first
      // sync tick so we can seek to the TV position before audio starts.
      await _audioPlayer!.open(
        mk.Media(
          source.url,
          httpHeaders: source.headers,
        ),
        play: source.isLive,
      );

      await _audioPlayer!.setVolume(state.isMuted ? 0 : (state.volume * 100));
      AppLogger.info(
        'Headless audio player started for: ${source.title}',
        feature: 'audio_handoff',
      );
    } catch (e) {
      AppLogger.error(
        'Failed to load headless audio: $e',
        feature: 'audio_handoff',
      );
      state = state.copyWith(errorMessage: 'Failed to stream audio: $e');
    }
  }

  void _handleSyncPacket(HandoffSyncPacket packet) {
    final live = packet.isLive || (state.currentSource?.isLive ?? false);
    _syncEngine.setIsLive(live);

    final incomingUrl = packet.streamUrl;
    if (incomingUrl != null &&
        incomingUrl.isNotEmpty &&
        incomingUrl != state.currentSource?.url) {
      final source = PlayerSource(
        url: incomingUrl,
        title: packet.title ?? state.currentSource?.title ?? 'TV Stream',
        channelId: packet.channelId ?? state.currentSource?.channelId,
        profile: live ? PlaybackProfile.live : PlaybackProfile.vod,
        headers: state.currentSource?.headers ?? const {},
      );
      state = state.copyWith(currentSource: source);
      _syncEngine.reset();
      unawaited(_loadAudioStream(source));
    }

    state = state.copyWith(
      networkRttMs: _client.estimatedRttMs,
    );

    // If TV is playing / paused, mirror state
    if (packet.isPlaying && !state.isPlaying && _audioPlayer != null) {
      _audioPlayer!.play();
    } else if (!packet.isPlaying &&
        !packet.isBuffering &&
        state.isPlaying &&
        _audioPlayer != null) {
      _audioPlayer!.pause();
    }

    // Process sync tick in the sync engine
    unawaited(_syncEngine.processSyncTick(
      packet: packet,
      localPhonePosition: _latestPosition,
      estimatedRttMs: _client.estimatedRttMs,
      isPhonePlaying: state.isPlaying,
    ));

    state = state.copyWith(
      driftMs: _syncEngine.smoothDriftMs.round(),
      isInSync: _syncEngine.isInSync,
    );
  }

  Future<void> _applyAudioDelay(int offsetMs) async {
    final player = _audioPlayer;
    if (player == null) return;
    if (player.platform is! mk.NativePlayer) return;
    final native = player.platform as mk.NativePlayer;
    // Live has no shared timeline: delay decoded audio instead of seeking.
    // VOD applies the offset via seek target, so keep audio-delay at 0.
    final delaySec = _syncEngine.isLive ? (offsetMs / 1000.0) : 0.0;
    try {
      await native.setProperty('audio-delay', delaySec.toString());
    } catch (e) {
      AppLogger.warning(
        'Companion audio-delay error: $e',
        feature: 'audio_handoff',
      );
    }
  }

  /// Sets Bluetooth audio sync offset in milliseconds (-1000 to +1000).
  void setBluetoothOffset(int offsetMs) {
    _syncEngine.setBluetoothOffset(offsetMs);
    state = state.copyWith(bluetoothOffsetMs: offsetMs);
    unawaited(_applyAudioDelay(offsetMs));
  }

  /// Sets companion local phone volume (0.0 to 1.0).
  Future<void> setVolume(double volume) async {
    final clamped = volume.clamp(0.0, 1.0);
    state = state.copyWith(volume: clamped);
    if (!state.isMuted && _audioPlayer != null) {
      await _audioPlayer!.setVolume(clamped * 100);
    }
  }

  /// Toggles companion phone local mute.
  Future<void> toggleMute() async {
    final nextMuted = !state.isMuted;
    state = state.copyWith(isMuted: nextMuted);
    if (_audioPlayer != null) {
      await _audioPlayer!.setVolume(nextMuted ? 0 : (state.volume * 100));
    }
  }

  /// Toggles TV speakers mute remotely via WebSocket command.
  void toggleTvMute() {
    final nextTvMuted = !state.isTvMuted;
    state = state.copyWith(isTvMuted: nextTvMuted);
    _client.sendCommand(
      HandoffCommand(
        action: nextTvMuted
            ? HandoffCommand.actionMuteTv
            : HandoffCommand.actionUnmuteTv,
      ),
    );
  }

  /// Sends play/pause toggle to host TV.
  void toggleTvPlayPause() {
    _client.sendCommand(
      const HandoffCommand(action: HandoffCommand.actionTogglePlayPause),
    );
  }

  /// Sends relative mouse movement delta to TV screen.
  void sendMouseMove(double dx, double dy) {
    _client.sendCommand(HandoffCommand.mouseMove(dx: dx, dy: dy));
  }

  /// Sends trackpad tap (simulates Left Click on TV).
  void sendMouseTap([String button = 'left']) {
    _client.sendCommand(HandoffCommand.mouseTap(button: button));
  }

  /// Sends continuous mouse click down/up event.
  void sendMouseClick({String button = 'left', bool down = true}) {
    _client.sendCommand(HandoffCommand.mouseClick(button: button, down: down));
  }

  /// Sends scroll gesture deltas.
  void sendMouseScroll(double dx, double dy) {
    _client.sendCommand(HandoffCommand.mouseScroll(dx: dx, dy: dy));
  }

  /// Sends D-pad or navigation key (up, down, left, right, select, back, home, backspace).
  void sendKeyPress(String key) {
    _client.sendCommand(HandoffCommand.keyPress(key));
  }

  /// Sends typed text to inject into focused text field on TV.
  void sendTypeText(String text, {bool replace = false}) {
    if (text.isNotEmpty) {
      _client.sendCommand(HandoffCommand.typeText(text, replace: replace));
    }
  }


  /// Disconnects companion listening and frees the audio player.
  Future<void> disconnect() async {
    _client.sendCommand(
      const HandoffCommand(action: HandoffCommand.actionDisconnect),
    );
    await _client.disconnect();
    await _stopAudioPlayer();
    _syncEngine.reset();
    _latestPosition = Duration.zero;
    _lastPositionStateEmit = null;
    _lastDurationStateEmit = null;
    state = const CompanionAudioState();
  }

  Future<void> _stopAudioPlayer() async {
    try {
      await WakelockPlus.disable();
    } catch (_) {}

    try {
      final session = await AudioSession.instance;
      await session.setActive(false);
    } catch (_) {}

    if (_audioPlayer != null) {
      try {
        await _audioPlayer!.stop();
        await _audioPlayer!.dispose();
      } catch (_) {}
      _audioPlayer = null;
    }
    _loadingUrl = null;
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    final player = _audioPlayer;
    _audioPlayer = null;
    if (player != null) {
      unawaited(() async {
        try {
          await player.stop();
          await player.dispose();
        } catch (_) {}
      }());
    }
    _client.dispose();
    super.dispose();
  }
}

/// Global provider for Companion Audio Controller.
final companionAudioProvider =
    StateNotifierProvider<CompanionAudioController, CompanionAudioState>(
  (ref) => CompanionAudioController(),
);
