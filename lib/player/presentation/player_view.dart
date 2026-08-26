import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/app/theme/app_icons.dart';
import 'package:media_kit_video/media_kit_video.dart' as mkv;

/// Rendering surface for video stream output.
class PlayerView extends StatelessWidget {
  const PlayerView({
    super.key,
    required this.aspectRatioIndex,
    required this.platformHandle,
  });

  final int aspectRatioIndex;
  final dynamic platformHandle;

  @override
  Widget build(BuildContext context) {
    if (platformHandle is mkv.VideoController) {
      final videoController = platformHandle as mkv.VideoController;

      BoxFit fit = BoxFit.contain; // 0: Fit
      double? forcedAspectRatio;

      switch (aspectRatioIndex) {
        case 1:
          fit = BoxFit.cover; // 1: Fill / Zoom
          break;
        case 2:
          fit = BoxFit.contain; // 2: 16:9
          forcedAspectRatio = 16 / 9;
          break;
        case 3:
          fit = BoxFit.contain; // 3: 4:3
          forcedAspectRatio = 4 / 3;
          break;
        default:
          fit = BoxFit.contain;
      }

      Widget videoWidget = Center(
        child: mkv.Video(
          controller: videoController,
          fit: fit,
          controls: (state) => const SizedBox.shrink(),
        ),
      );

      if (forcedAspectRatio != null) {
        videoWidget = Center(
          child: AspectRatio(
            aspectRatio: forcedAspectRatio,
            child: videoWidget,
          ),
        );
      }

      return Container(
        color: Colors.black,
        width: double.infinity,
        height: double.infinity,
        alignment: Alignment.center,
        child: videoWidget,
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
