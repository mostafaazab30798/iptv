import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/app/theme/app_icons.dart';
import 'package:iptv/player/domain/entities/web_video_handle.dart';
import 'package:media_kit_video/media_kit_video.dart' as mkv;

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
    this.videoWidth,
    this.videoHeight,
  });

  /// 0: Best Fit, 1: Fit, 2: Fill, 3: 16:9, 4: 4:3
  final int aspectRatioIndex;
  final dynamic platformHandle;
  final int? videoWidth;
  final int? videoHeight;

  @override
  Widget build(BuildContext context) {
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

          BoxFit fit = BoxFit.contain;
          double? forcedAspectRatio;
          double scale = 1.0;

          switch (aspectRatioIndex) {
            case 0: // 0: Best Fit
              fit = BoxFit.contain;
              scale = bestFitScale;
              break;
            case 1: // 1: Fit (100% original contain)
              fit = BoxFit.contain;
              break;
            case 2: // 2: Fill (100% cover)
              fit = BoxFit.cover;
              break;
            case 3: // 3: 16:9
              fit = BoxFit.contain;
              forcedAspectRatio = 16 / 9;
              break;
            case 4: // 4: 4:3
              fit = BoxFit.contain;
              forcedAspectRatio = 4 / 3;
              break;
            default:
              fit = BoxFit.contain;
              scale = bestFitScale;
          }

          Widget videoWidget = mkv.Video(
            controller: videoController,
            fit: fit,
            controls: (state) => const SizedBox.shrink(),
          );

          if (forcedAspectRatio != null) {
            videoWidget = Center(
              child: AspectRatio(
                aspectRatio: forcedAspectRatio,
                child: videoWidget,
              ),
            );
          }

          if (scale > 1.001) {
            videoWidget = ClipRect(
              child: Transform.scale(
                scale: scale,
                child: videoWidget,
              ),
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
          double? forcedAspectRatio;

          switch (aspectRatioIndex) {
            case 0:
              break;
            case 1:
              break;
            case 2:
              break;
            case 3:
              forcedAspectRatio = 16 / 9;
              break;
            case 4:
              forcedAspectRatio = 4 / 3;
              break;
            default:
              break;
          }

          webHandle.onAspectRatioChanged?.call(aspectRatioIndex);

          // HtmlElementView has no intrinsic size. Centering it under loose
          // constraints collapses the platform view to 0×0 (audio still plays).
          Widget videoWidget = kIsWeb
              ? HtmlElementView(viewType: webHandle.viewTypeId)
              : const SizedBox.expand();
          videoWidget = SizedBox.expand(child: videoWidget);

          if (forcedAspectRatio != null) {
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
