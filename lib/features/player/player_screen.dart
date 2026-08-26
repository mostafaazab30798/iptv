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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _enterFullscreenMode();
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

  void _enterFullscreenMode() {
    if (PlatformService.instance.isAndroid || PlatformService.instance.isAndroidTv) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  void _exitFullscreenMode() {
    if (PlatformService.instance.isAndroid || PlatformService.instance.isAndroidTv) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
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

  void _toggleFullscreen() {
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    if (isPortrait || !ref.read(playerControllerProvider).isFullscreen) {
      // Force Landscape Fullscreen
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      _controller?.setFullscreen(true);
      _enterFullscreenMode();
    } else {
      // Force Portrait
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      _controller?.setFullscreen(false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _restoreDefaultOrientations();
    _exitFullscreenMode();
    _controller?.savePlaybackProgress();
    _controller?.stop();
    super.dispose();
  }

  void _handleBack() {
    _restoreDefaultOrientations();
    _controller?.savePlaybackProgress();
    _controller?.stop();
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      try {
        context.go('/home');
      } catch (_) {}
    }
  }


  @override
  Widget build(BuildContext context) {
    // Narrow selectors — each widget only rebuilds on the fields it actually needs.
    // This prevents the entire Stack from rebuilding on every position tick from mpv.
    final isBufferingOrLoading = ref.watch(
      playerControllerProvider.select((s) => s.isBuffering || s.isLoading),
    );
    final hasError = ref.watch(
      playerControllerProvider.select((s) => s.hasError),
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

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          _controller?.stop();
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

            // 2. Debounced Buffering Indicator — only rebuilds on buffering/loading changes.
            BufferingIndicator(
              isBuffering: isBufferingOrLoading,
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
