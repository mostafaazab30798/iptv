import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show PlatformViewHitTestBehavior;
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/app/theme/app_icons.dart';
import 'package:iptv/player/domain/entities/web_video_handle.dart';
import 'package:iptv/player/domain/enums/player_aspect_ratio_mode.dart';
import 'package:media_kit_video/media_kit_video.dart' as mkv;
import 'package:video_player/video_player.dart' as native_video;

/// Calculates the optimal scaling factor for the video surface.
///
/// If aspect ratio difference between viewport and video is <= 14%
/// (e.g. 16:9 on 16:10 laptop screen or 18:9 mobile phone), it completely
/// eliminates black bars with minimal safe-zone crop (<= 6.5% on each edge).
///
/// For larger aspect ratio mismatches (e.g. 21:9 Cinemascope movie on 16:9,
/// or 4:3 on 16:9), it scales by a safe threshold (~1.12x) to shrink black
/// borders by 35-45% without ever cutting off subtitles, actors, or heads.
double calculateBestFitScale({
  required double viewportWidth,
  required double viewportHeight,
  required double videoWidth,
  required double videoHeight,
  double maxSafeCropPercent = 0.12,
}) {
  if (viewportWidth <= 0 ||
      viewportHeight <= 0 ||
      videoWidth <= 0 ||
      videoHeight <= 0) {
    return 1.0;
  }
  final screenRatio = viewportWidth / viewportHeight;
  final videoRatio = videoWidth / videoHeight;

  // The full cover scale needed to reach zero black bars:
  final fullCoverScale = screenRatio > videoRatio
      ? screenRatio / videoRatio
      : videoRatio / screenRatio;

  if (fullCoverScale <= 1.005) {
    return 1.0;
  }

  // Small aspect ratio mismatch: completely eliminate black bars.
  if (fullCoverScale <= 1.14) {
    return fullCoverScale;
  }

  // Large mismatch: reduce black borders substantially while strictly preserving content.
  final maxScale = 1.0 + maxSafeCropPercent;
  return fullCoverScale.clamp(1.0, maxScale);
}

/// Rendering surface for video stream output.
class PlayerView extends StatelessWidget {
  const PlayerView({
    super.key,
    required this.aspectRatioIndex,
    required this.platformHandle,
    this.useNativeControls = false,
    this.videoWidth,
    this.videoHeight,
  });

  /// 0: Best Fit, 1: Fit, 2: Fill, 3: 16:9, 4: 4:3
  final int aspectRatioIndex;
  final dynamic platformHandle;

  /// Lets Safari's native video controls receive touch input for iOS VOD.
  final bool useNativeControls;
  final int? videoWidth;
  final int? videoHeight;

  @override
  Widget build(BuildContext context) {
    final mode = PlayerAspectRatioMode.fromIndex(aspectRatioIndex);

    if (platformHandle is native_video.VideoPlayerController) {
      final controller = platformHandle as native_video.VideoPlayerController;
      if (!controller.value.isInitialized) {
        return const ColoredBox(color: Colors.black);
      }
      return _BackendVideoSurface(
        mode: mode,
        sourceAspectRatio: controller.value.aspectRatio,
        child: native_video.VideoPlayer(controller),
      );
    }

    if (platformHandle is VlcPlayerController) {
      final controller = platformHandle as VlcPlayerController;
      return ValueListenableBuilder<VlcPlayerValue>(
        valueListenable: controller,
        builder: (context, value, _) {
          final sourceAspectRatio = value.aspectRatio > 0
              ? value.aspectRatio
              : 16 / 9;
          return _BackendVideoSurface(
            mode: mode,
            sourceAspectRatio: sourceAspectRatio,
            child: VlcPlayer(
              controller: controller,
              aspectRatio: sourceAspectRatio,
            ),
          );
        },
      );
    }

    if (platformHandle is mkv.VideoController) {
      final videoController = platformHandle as mkv.VideoController;

      return LayoutBuilder(
        builder: (context, constraints) {
          final vw = (videoWidth != null && videoWidth! > 0)
              ? videoWidth!.toDouble()
              : 16.0;
          final vh = (videoHeight != null && videoHeight! > 0)
              ? videoHeight!.toDouble()
              : 9.0;

          final bestFitScale = calculateBestFitScale(
            viewportWidth: constraints.maxWidth,
            viewportHeight: constraints.maxHeight,
            videoWidth: vw,
            videoHeight: vh,
          );

          final scale = mode == PlayerAspectRatioMode.bestFit
              ? bestFitScale
              : 1.0;

          Widget videoWidget = mkv.Video(
            controller: videoController,
            fit: mode.surfaceFit,
            controls: (state) => const SizedBox.shrink(),
          );

          if (mode.forcedAspectRatio case final forcedAspectRatio?) {
            videoWidget = Center(
              child: AspectRatio(
                aspectRatio: forcedAspectRatio,
                child: videoWidget,
              ),
            );
          }

          if (scale > 1.001) {
            videoWidget = ClipRect(
              child: Transform.scale(scale: scale, child: videoWidget),
            );
          }

          return RepaintBoundary(
            child: Container(
              color: Colors.black,
              width: double.infinity,
              height: double.infinity,
              alignment: Alignment.center,
              child: videoWidget,
            ),
          );
        },
      );
    }

    if (platformHandle is WebVideoHandle) {
      final webHandle = platformHandle as WebVideoHandle;

      return LayoutBuilder(
        builder: (context, _) {
          webHandle.onAspectRatioChanged?.call(aspectRatioIndex);

          // HtmlElementView has no intrinsic size. Centering it under loose
          // constraints collapses the platform view to 0×0 (audio still plays).
          Widget videoWidget = kIsWeb
              ? HtmlElementView(
                  viewType: webHandle.viewTypeId,
                  // VOD uses Safari's own controls and must receive touches.
                  // Live TV keeps the Flutter overlay above a passive surface.
                  hitTestBehavior: useNativeControls
                      ? PlatformViewHitTestBehavior.opaque
                      : PlatformViewHitTestBehavior.transparent,
                )
              : const SizedBox.expand();
          videoWidget = SizedBox.expand(child: videoWidget);

          if (mode.forcedAspectRatio case final forcedAspectRatio?) {
            videoWidget = Center(
              child: AspectRatio(
                aspectRatio: forcedAspectRatio,
                child: videoWidget,
              ),
            );
          }

          return RepaintBoundary(
            child: Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: Colors.black),
                videoWidget,
              ],
            ),
          );
        },
      );
    }

    return const ColoredBox(
      color: Colors.black,
      child: Center(
        child: HugeIcon(
          icon: AppIcons.live,
          color: AppColors.textDisabled,
          size: 84,
        ),
      ),
    );
  }
}

/// Gives Media3 and VLC the same five display policies as MediaKit.
class _BackendVideoSurface extends StatelessWidget {
  const _BackendVideoSurface({
    required this.mode,
    required this.sourceAspectRatio,
    required this.child,
  });

  final PlayerAspectRatioMode mode;
  final double sourceAspectRatio;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final safeSourceAspectRatio =
              sourceAspectRatio.isFinite && sourceAspectRatio > 0
              ? sourceAspectRatio
              : 16 / 9;
          final frameAspectRatio =
              mode.forcedAspectRatio ?? safeSourceAspectRatio;
          final bestFitScale = calculateBestFitScale(
            viewportWidth: constraints.maxWidth,
            viewportHeight: constraints.maxHeight,
            videoWidth: safeSourceAspectRatio,
            videoHeight: 1,
          );

          Widget surface = Center(
            child: AspectRatio(aspectRatio: frameAspectRatio, child: child),
          );
          if (mode == PlayerAspectRatioMode.fill) {
            surface = ClipRect(
              child: SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: safeSourceAspectRatio * 1000,
                    height: 1000,
                    child: child,
                  ),
                ),
              ),
            );
          } else if (mode == PlayerAspectRatioMode.bestFit &&
              bestFitScale > 1.001) {
            surface = ClipRect(
              child: Transform.scale(scale: bestFitScale, child: surface),
            );
          }
          return RepaintBoundary(child: surface);
        },
      ),
    );
  }
}
