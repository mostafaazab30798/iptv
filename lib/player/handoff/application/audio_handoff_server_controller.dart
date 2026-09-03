import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iptv/core/logging/app_logger.dart';
import 'package:iptv/player/handoff/application/companion_input_manager.dart';
import 'package:iptv/player/handoff/domain/audio_handoff_models.dart';
import 'package:iptv/player/handoff/infrastructure/audio_handoff_server.dart';
import 'package:iptv/player/player.dart';

class AudioHandoffServerState extends Equatable {
  const AudioHandoffServerState({
    this.isHosting = false,
    this.sessionInfo,
    this.availableIps = const [],
    this.connectedClientCount = 0,
    this.isTvMuted = false,
    this.savedTvVolume = 1.0,
    this.error,
  });

  final bool isHosting;
  final HandoffSessionInfo? sessionInfo;
  final List<String> availableIps;
  final int connectedClientCount;
  final bool isTvMuted;
  final double savedTvVolume;
  final String? error;

  AudioHandoffServerState copyWith({
    bool? isHosting,
    HandoffSessionInfo? sessionInfo,
    List<String>? availableIps,
    int? connectedClientCount,
    bool? isTvMuted,
    double? savedTvVolume,
    String? error,
  }) {
    return AudioHandoffServerState(
      isHosting: isHosting ?? this.isHosting,
      sessionInfo: sessionInfo ?? this.sessionInfo,
      availableIps: availableIps ?? this.availableIps,
      connectedClientCount:
          connectedClientCount ?? this.connectedClientCount,
      isTvMuted: isTvMuted ?? this.isTvMuted,
      savedTvVolume: savedTvVolume ?? this.savedTvVolume,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
        isHosting,
        sessionInfo,
        availableIps,
        connectedClientCount,
        isTvMuted,
        savedTvVolume,
        error,
      ];
}

class AudioHandoffServerController
    extends StateNotifier<AudioHandoffServerState> {
  AudioHandoffServerController({
    AudioHandoffServer? server,
    CompanionInputManager? inputManager,
  })  : _server = server ?? AudioHandoffServer(),
        _inputManager = inputManager,
        super(const AudioHandoffServerState());

  final AudioHandoffServer _server;
  final CompanionInputManager? _inputManager;

  /// Live player binding. Closures read this field so mute/sync keep working
  /// after the LAN server is started at app boot (when no player exists yet).
  PlayerController? _boundPlayer;
  bool _autoMuteTv = true;

  AudioHandoffServer get server => _server;
  CompanionInputManager? get inputManager => _inputManager;

  int _positionMs() =>
      _boundPlayer?.positionListenable.value.inMilliseconds ??
      _boundPlayer?.state.position.inMilliseconds ??
      0;

  int _durationMs() => _boundPlayer?.state.duration.inMilliseconds ?? 0;

  /// True while the TV is actually decoding. Buffering/loading still count as
  /// "should play" so the companion does not pause on every rebuffer.
  bool _isPlaying() {
    final player = _boundPlayer;
    if (player == null) return false;
    return player.state.isPlaying ||
        player.state.isBuffering ||
        player.state.isLoading;
  }

  bool _isBuffering() => _boundPlayer?.state.isBuffering ?? false;

  void _onClientCountChanged(int count) {
    if (!mounted) return;
    state = state.copyWith(connectedClientCount: count);
    final player = _boundPlayer;
    if (player == null) return;
    if (count > 0 && _autoMuteTv && !state.isTvMuted) {
      unawaited(muteTvAudio(player));
    } else if (count == 0 && state.isTvMuted) {
      unawaited(unmuteTvAudio(player));
    }
  }

  /// Starts the TV Audio & Remote Companion Server.
  ///
  /// Safe to call repeatedly: if the server is already running, the player is
  /// rebound and the advertised LAN IP is refreshed without dropping clients.
  Future<HandoffSessionInfo?> startHosting({
    PlayerSource? source,
    PlayerController? playerController,
    bool autoMuteTv = true,
  }) async {
    try {
      _autoMuteTv = autoMuteTv;
      if (playerController != null) {
        _boundPlayer = playerController;
      }

      final effectiveSource =
          source ?? _boundPlayer?.state.source ?? state.sessionInfo?.source;

      if (_server.isRunning && state.isHosting) {
        _server.bindPlaybackSuppliers(
          getPositionMs: _positionMs,
          getDurationMs: _durationMs,
          getIsPlaying: _isPlaying,
          getIsBuffering: _isBuffering,
          onCommand: _handleClientCommand,
          onClientCountChanged: _onClientCountChanged,
        );
        if (effectiveSource != null && effectiveSource.url.isNotEmpty) {
          updateSource(effectiveSource);
        }
        final refreshed = await _server.refreshAdvertisedIp();
        final availableIps = await _server.getAvailableLocalIps();
        state = state.copyWith(
          sessionInfo: refreshed ?? state.sessionInfo,
          availableIps: availableIps,
        );
        if (_autoMuteTv &&
            _server.clientCount > 0 &&
            !state.isTvMuted &&
            _boundPlayer != null) {
          unawaited(muteTvAudio(_boundPlayer!));
        }
        return state.sessionInfo;
      }

      final initialVol = _boundPlayer?.state.volume ?? 1.0;

      final session = await _server.start(
        source: effectiveSource,
        getPositionMs: _positionMs,
        getDurationMs: _durationMs,
        getIsPlaying: _isPlaying,
        getIsBuffering: _isBuffering,
        onCommand: _handleClientCommand,
        onClientCountChanged: _onClientCountChanged,
      );

      final availableIps = await _server.getAvailableLocalIps();

      state = state.copyWith(
        isHosting: true,
        sessionInfo: session,
        availableIps: availableIps,
        savedTvVolume: initialVol > 0 ? initialVol : 1.0,
      );

      return session;
    } catch (e) {
      AppLogger.error(
        'Failed to start Audio Handoff server: $e',
        feature: 'audio_handoff',
      );
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Attaches the active player so companion mute/play/sync commands reach it.
  void bindPlayback(PlayerController player, {PlayerSource? source}) {
    _boundPlayer = player;
    if (_server.isRunning) {
      _server.bindPlaybackSuppliers(
        getPositionMs: _positionMs,
        getDurationMs: _durationMs,
        getIsPlaying: _isPlaying,
        getIsBuffering: _isBuffering,
        onCommand: _handleClientCommand,
        onClientCountChanged: _onClientCountChanged,
      );
    }
    final nextSource = source ?? player.state.source;
    if (nextSource != null && nextSource.url.isNotEmpty) {
      updateSource(nextSource);
    }
    if (_autoMuteTv && _server.clientCount > 0) {
      if (state.isTvMuted) {
        // Re-apply after mpv open, which can restore speaker volume.
        unawaited(player.setVolume(0.0));
      } else {
        unawaited(muteTvAudio(player));
      }
    }
  }

  /// Clears the player binding when playback stops. Keeps the LAN server up
  /// so discovery and remote control still work from the home screen.
  void unbindPlayback() {
    if (state.isTvMuted && _boundPlayer != null) {
      unawaited(unmuteTvAudio(_boundPlayer!));
    }
    _boundPlayer = null;
    if (_server.isRunning) {
      _server.updateSource(
        const PlayerSource(url: '', title: 'IPTV Screen'),
      );
    }
  }

  /// Switches the advertised LAN IP address when multiple network adapters exist.
  void changeHostIp(String newIp) {
    if (state.sessionInfo != null) {
      final old = state.sessionInfo!;
      final updated = HandoffSessionInfo(
        hostIp: newIp,
        port: old.port,
        sessionToken: old.sessionToken,
        pinCode: old.pinCode,
        source: old.source,
        serverDeviceName: old.serverDeviceName,
      );
      _server.updateAdvertisedSession(updated);
      state = state.copyWith(sessionInfo: updated);
    }
  }

  void _handleClientCommand(HandoffCommand command) {
    final player = _boundPlayer;
    switch (command.action) {
      case HandoffCommand.actionMuteTv:
        if (player != null) {
          unawaited(muteTvAudio(player));
        } else {
          AppLogger.warning(
            'Mute TV ignored: no player bound',
            feature: 'audio_handoff',
          );
        }
        break;
      case HandoffCommand.actionUnmuteTv:
        if (player != null) {
          unawaited(unmuteTvAudio(player));
        }
        break;
      case HandoffCommand.actionTogglePlayPause:
        if (player != null) {
          if (player.state.isPlaying) {
            player.pause();
          } else {
            player.play();
          }
        }
        break;
      case HandoffCommand.actionSeek:
        final posMs = (command.payload['pos'] as num?)?.toInt();
        if (posMs != null && player != null) {
          player.seek(Duration(milliseconds: posMs));
        }
        break;


      // Remote Mouse / Touchpad Commands
      case HandoffCommand.actionMouseMove:
        final dx = (command.payload['dx'] as num?)?.toDouble() ?? 0.0;
        final dy = (command.payload['dy'] as num?)?.toDouble() ?? 0.0;
        _inputManager?.handleMouseMove(dx, dy);
        break;
      case HandoffCommand.actionMouseTap:
        _inputManager?.handleMouseTap();
        break;
      case HandoffCommand.actionMouseClick:
        final button = command.payload['button'] as String? ?? 'left';
        final down = command.payload['down'] as bool? ?? true;
        _inputManager?.handleMouseClick(button: button, down: down);
        break;
      case HandoffCommand.actionMouseScroll:
        final dx = (command.payload['dx'] as num?)?.toDouble() ?? 0.0;
        final dy = (command.payload['dy'] as num?)?.toDouble() ?? 0.0;
        _inputManager?.handleMouseScroll(dx, dy);
        break;

      // Remote Keyboard & D-Pad Commands
      case HandoffCommand.actionKeyPress:
        final key = command.payload['key'] as String? ?? '';
        _inputManager?.handleKeyPress(
          key,
          onPlayPauseToggle: () {
            if (player != null) {
              if (player.state.isPlaying) {
                player.pause();
              } else {
                player.play();
              }
            }
          },
        );
        break;

      case HandoffCommand.actionTypeText:
        final text = command.payload['text'] as String? ?? '';
        final replace = command.payload['replace'] as bool? ?? false;
        _inputManager?.handleTypeText(text, replace: replace);
        break;
    }
  }

  /// Mutes TV speakers while companion is listening.
  Future<void> muteTvAudio(PlayerController playerController) async {
    if (!state.isTvMuted) {
      final curVol = playerController.state.volume;
      state = state.copyWith(
        isTvMuted: true,
        savedTvVolume: curVol > 0 ? curVol : state.savedTvVolume,
      );
      await playerController.setVolume(0.0);
    } else {
      await playerController.setVolume(0.0);
    }
  }

  /// Restores TV speaker volume.
  Future<void> unmuteTvAudio(PlayerController playerController) async {
    if (state.isTvMuted) {
      final restoreVol = state.savedTvVolume;
      state = state.copyWith(isTvMuted: false);
      await playerController.setVolume(restoreVol > 0 ? restoreVol : 1.0);
    }
  }

  /// Toggles TV audio mute.
  Future<void> toggleTvMute(PlayerController playerController) async {
    if (state.isTvMuted) {
      await unmuteTvAudio(playerController);
    } else {
      await muteTvAudio(playerController);
    }
  }

  /// Updates media source on the TV server when changing channels.
  void updateSource(PlayerSource source) {
    _server.updateSource(source);
    if (state.sessionInfo != null) {
      state = state.copyWith(
        sessionInfo: _server.sessionInfo,
      );
    }
  }

  /// Stops hosting the handoff server.
  Future<void> stopHosting([PlayerController? playerController]) async {
    final player = playerController ?? _boundPlayer;
    if (state.isTvMuted && player != null) {
      await unmuteTvAudio(player);
    }
    _boundPlayer = null;
    await _server.stop();
    state = const AudioHandoffServerState();
  }

  @override
  void dispose() {
    _server.stop();
    super.dispose();
  }
}

final audioHandoffServerProvider = StateNotifierProvider<
    AudioHandoffServerController, AudioHandoffServerState>(
  (ref) {
    final inputManager = ref.read(companionInputProvider.notifier);
    return AudioHandoffServerController(inputManager: inputManager);
  },
);

