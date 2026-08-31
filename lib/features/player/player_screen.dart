import 'dart:async' show scheduleMicrotask;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iptv/core/platform/platform_service.dart';
import 'package:iptv/player/player.dart';
import 'package:iptv/player/presentation/buffering_indicator.dart';
import 'package:iptv/player/presentation/player_error_view.dart';
import 'package:iptv/player/presentation/player_overlay.dart';
import 'package:iptv/player/presentation/player_view.dart';

/// Fullscreen production IPTV player screen host.
///
/// Decoupled from media engine internals, handles orientation, immersive mode,
/// and routes user input to the PlayerController.
class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> with WidgetsBindingObserver {
  PlayerController? _controller;
  /// Cached so exit logic still works after system-back dispose (ref unusable).
  bool _isLiveSource = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller = ref.read(playerControllerProvider.notifier);
        _isLiveSource = ref.read(playerControllerProvider).isLive;
        _controller?.setPlayerRouteActive(true);
        _enterFullscreenMode();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _controller?.savePlaybackProgress();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller = ref.read(playerControllerProvider.notifier);
  }

  Future<void> _enterFullscreenMode() async {
    _controller ??= ref.read(playerControllerProvider.notifier);
    _controller?.setFullscreen(true);
    if (PlatformService.instance.isAndroid) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
    await PlatformService.instance.setFullScreen(true);
  }

  Future<void> _exitFullscreenMode() async {
    _controller ??= ref.read(playerControllerProvider.notifier);
    _controller?.setFullscreen(false);
    if (PlatformService.instance.isAndroid) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
    await PlatformService.instance.setFullScreen(false);
  }

  void _restoreDefaultOrientations() {
    if (PlatformService.instance.isAndroid) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  Future<void> _toggleFullscreen() async {
    final isMobile = PlatformService.instance.isAndroid;
    if (isMobile) {
      final isLandscape = MediaQuery.maybeOrientationOf(context) == Orientation.landscape;
      if (isLandscape) {
        await _exitFullscreenMode();
      } else {
        await _enterFullscreenMode();
      }
    } else {
      final isPlatformFull = await PlatformService.instance.isFullScreen();
      final isCurrentlyFull = ref.read(playerControllerProvider).isFullscreen;
      final shouldExit = isPlatformFull || isCurrentlyFull;
      if (shouldExit) {
        await _exitFullscreenMode();
      } else {
        await _enterFullscreenMode();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _restoreDefaultOrientations();
    PlatformService.instance.setFullScreen(false);
    final controller = _controller;
    super.dispose();
    // Defer provider writes until after the unmount cascade finishes. Calling
    // setState on listeners mid-unmount marks defunct elements dirty. Tests
    // must pump once after removing PlayerScreen to drain this microtask.
    scheduleMicrotask(() {
      if (controller == null || !controller.mounted) return;
      controller.setPlayerRouteActive(false);
      controller.setFullscreen(false);
    });
  }

  /// Leaves the fullscreen player without tearing down live playback so the
  /// Live TV mini preview can keep showing the same stream.
  void _leavePlayer({required bool alreadyPopped}) {
    if (!alreadyPopped) {
      _restoreDefaultOrientations();
      // Exit OS immersive mode immediately. Surface ownership is released in
      // dispose so LiveMiniPreview remounts after this Video is gone.
      PlatformService.instance.setFullScreen(false);
      if (mounted) {
        _isLiveSource = ref.read(playerControllerProvider).isLive;
      }
    }
    _controller?.savePlaybackProgress();

    // Keep playback only when Live TV registered a mini-preview handoff.
    // Favourites / search / history open live channels without that host, so
    // those must stop on exit or audio continues in the background.
    // Kick stop before pop; do not wrap in Future — that leaves pending
    // timers when the route is disposed under widget tests.
    final retainForMiniPreview =
        _isLiveSource && (_controller?.hasLivePreviewHandoff ?? false);
    if (!retainForMiniPreview) {
      _controller?.stop();
    }

    if (alreadyPopped) return;

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      try {
        context.go('/home');
      } catch (_) {}
    }
  }

  void _handleBack() => _leavePlayer(alreadyPopped: false);


  @override
  Widget build(BuildContext context) {
    // Narrow selectors — each widget only rebuilds on the fields it actually needs.
    // This prevents the entire Stack from rebuilding on every position tick from mpv.
    final isBufferingOrLoading = ref.watch(
      playerControllerProvider.select((s) => s.isBuffering || s.isLoading || s.isRetrying),
    );
    final hasError = ref.watch(
      playerControllerProvider.select((s) => s.hasError),
    );
    final isRetrying = ref.watch(
      playerControllerProvider.select((s) => s.isRetrying),
    );
    final retryAttempt = ref.watch(
      playerControllerProvider.select((s) => s.retryAttempt),
    );
    final maxRetries = ref.watch(
      playerControllerProvider.select((s) => s.maxRetries),
    );

    // Full state is read (not watched) here — passed to PlayerOverlay which has
    // its own ConsumerWidget children that selectively watch what they need.
    // The overlay rebuilds on control-related state changes (status, tracks, etc.)
    // but NOT on position ticks alone.
    final playerState = ref.watch(
      playerControllerProvider.select((s) => (
        status: s.status,
        source: s.source,
        isPlaying: s.isPlaying,
        isLive: s.isLive,
        volume: s.volume,
        isMuted: s.isMuted,
        isFullscreen: s.isFullscreen,
        aspectRatioIndex: s.aspectRatioIndex,
        playbackRate: s.playbackRate,
        isLocked: s.isLocked,
        bufferMode: s.bufferMode,
        error: s.error,
        errorMessage: s.errorMessage,
        currentAudioTrack: s.currentAudioTrack,
        currentSubtitleTrack: s.currentSubtitleTrack,
        availableAudioTracks: s.availableAudioTracks,
        availableSubtitleTracks: s.availableSubtitleTracks,
        capabilities: s.capabilities,
        metrics: s.metrics,
      )),
    );
    // Reconstruct a full PlayerState for widgets that need it.
    final fullPlayerState = ref.read(playerControllerProvider);
    final controller = ref.read(playerControllerProvider.notifier);
    _isLiveSource = fullPlayerState.isLive;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          _leavePlayer(alreadyPopped: true);
        } else {
          _handleBack();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Video Surface — isolated from position/metrics churn; only rebuilds
            // when the aspect-ratio setting actually changes.
            Consumer(
              builder: (context, ref, _) {
                final aspectRatioIndex = ref.watch(
                  playerControllerProvider.select((s) => s.aspectRatioIndex),
                );
                return PlayerView(
                  aspectRatioIndex: aspectRatioIndex,
                  platformHandle: controller.engine.platformHandle,
                );
              },
            ),

            // 2. Debounced Buffering Indicator / Non-blocking Auto-reconnect HUD
            BufferingIndicator(
              isBuffering: isBufferingOrLoading,
              statusMessage: isRetrying
                  ? 'Reconnecting... ($retryAttempt/$maxRetries)'
                  : null,
            ),

            // 3. Interactive Controls Overlay & Diagnostics HUD
            PlayerOverlay(
              playerState: fullPlayerState,
              onPlayPause: () {
                if (playerState.isPlaying) {
                  controller.pause();
                } else {
                  controller.play();
                }
              },
              onSeek: controller.seek,
              onSeekRelative: controller.seekRelative,
              onSelectPlaybackRate: controller.setPlaybackRate,
              onVolumeChanged: controller.setVolume,
              onToggleMute: controller.toggleMute,
              onNextChannel: controller.nextChannel,
              onPreviousChannel: controller.previousChannel,
              onCycleAspectRatio: controller.cycleAspectRatio,
              onSelectAspectRatio: controller.setAspectRatio,
              onSelectAudioTrack: controller.setAudioTrack,
              onSelectSubtitleTrack: controller.setSubtitleTrack,
              onSelectBufferMode: controller.setBufferMode,
              onToggleLock: controller.toggleLock,
              onToggleFullscreen: _toggleFullscreen,
              onClose: _handleBack,
            ),

            // 4. Classified Error Overlay — only rendered when hasError is true.
            if (hasError)
              PlayerErrorView(
                errorType: fullPlayerState.error!,
                customMessage: fullPlayerState.errorMessage,
                onRetry: controller.retry,
                onClose: _handleBack,
              ),
          ],
        ),
      ),
    );
  }
}
