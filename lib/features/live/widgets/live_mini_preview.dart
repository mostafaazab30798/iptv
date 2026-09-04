import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/app/theme/app_icons.dart';
import 'package:iptv/domain/entities/channel.dart';
import 'package:iptv/player/player.dart';
import 'package:iptv/player/presentation/buffering_indicator.dart';
import 'package:iptv/player/presentation/player_view.dart';
import 'package:iptv/shared/extensions/context_extensions.dart';
import 'package:iptv/shared/widgets/smart_channel_logo.dart';

/// Live mini-player preview panel embedded inside the Live TV section.
class LiveMiniPreview extends ConsumerWidget {
  const LiveMiniPreview({
    super.key,
    this.selectedChannel,
    required this.onExpandFullscreen,
  });

  final Channel? selectedChannel;
  final VoidCallback onExpandFullscreen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final source = ref.watch(playerControllerProvider.select((s) => s.source));
    final isPlaying = ref.watch(playerControllerProvider.select((s) => s.isPlaying));
    final isBuffering = ref.watch(playerControllerProvider.select((s) => s.isBuffering));
    final isMuted = ref.watch(playerControllerProvider.select((s) => s.isMuted));
    final aspectRatioIndex = ref.watch(playerControllerProvider.select((s) => s.aspectRatioIndex));
    // Only one mkv.Video may bind the shared controller at a time. While the
    // fullscreen PlayerScreen owns the surface, detach the mini preview.
    final isPlayerRouteActive =
        ref.watch(playerControllerProvider.select((s) => s.isPlayerRouteActive));
    final controller = ref.read(playerControllerProvider.notifier);

    final hasActiveSource = source != null;
    final showVideoSurface = hasActiveSource && !isPlayerRouteActive;

    if (!hasActiveSource && selectedChannel == null) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.bg1,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.bg2,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white10),
              ),
              child: const HugeIcon(
                icon: AppIcons.live,
                size: 48,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Live Preview',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Select any channel from the list to preview stream instantly',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final channelTitle = source?.title ?? selectedChannel?.name ?? 'Live Stream';
    final logoUrl = source?.logoUrl ?? selectedChannel?.streamIcon;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.bg1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Video Surface Stage
          AspectRatio(
            aspectRatio: 16 / 9,
            child: RepaintBoundary(
              child: Stack(
                fit: StackFit.expand,
                children: [
                if (showVideoSurface)
                  PlayerView(
                    aspectRatioIndex: aspectRatioIndex,
                    platformHandle: controller.engine.platformHandle,
                  )
                else
                  ColoredBox(
                    color: Colors.black,
                    child: Center(
                      child: hasActiveSource
                          ? null
                          : SmartChannelLogo(
                              channel: selectedChannel,
                              channelName: channelTitle,
                              logoUrl: logoUrl,
                              width: 64,
                              height: 64,
                              borderRadius: BorderRadius.circular(10),
                              fit: BoxFit.contain,
                            ),
                    ),
                  ),

                // Buffering State
                if (isBuffering)
                  Positioned.fill(
                    child: BufferingIndicator(isBuffering: isBuffering),
                  ),

                // Live Badge (Top Left)
                Positioned(
                  top: 10,
                  left: 10,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: AppColors.live,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.live.withValues(alpha: 0.5),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'LIVE PREVIEW',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Tap Video Overlay -> Fullscreen
                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onExpandFullscreen,
                      hoverColor: Colors.black26,
                      splashColor: AppColors.accent.withValues(alpha: 0.15),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            shape: BoxShape.circle,
                          ),
                          child: const HugeIcon(
                            icon: AppIcons.fullscreen,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            ),
          ),

          // Channel Info & Quick Actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SmartChannelLogo(
                      channel: selectedChannel,
                      channelName: channelTitle,
                      logoUrl: logoUrl,
                      width: 38,
                      height: 38,
                      borderRadius: BorderRadius.circular(6),
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        channelTitle,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    InkWell(
                      onTap: () {
                        if (isPlaying) {
                          controller.pause();
                        } else {
                          controller.play();
                        }
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: HugeIcon(
                          icon: isPlaying
                              ? AppIcons.pause
                              : AppIcons.play,
                          color: AppColors.accent,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: controller.toggleMute,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: HugeIcon(
                          icon: isMuted
                              ? AppIcons.volumeMute
                              : AppIcons.volumeHigh,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                      ),
                    ),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Tooltip(
                            message: context.l10n.playerPreviousChannel,
                            child: InkWell(
                              onTap: controller.previousChannel,
                              borderRadius: BorderRadius.circular(16),
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: HugeIcon(
                                  icon: AppIcons.previous,
                                  color: AppColors.textSecondary,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 2),
                          Tooltip(
                            message: context.l10n.playerNextChannel,
                            child: InkWell(
                              onTap: controller.nextChannel,
                              borderRadius: BorderRadius.circular(16),
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: HugeIcon(
                                  icon: AppIcons.next,
                                  color: AppColors.textSecondary,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: ElevatedButton.icon(
                          onPressed: onExpandFullscreen,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const HugeIcon(icon: AppIcons.fullscreen, size: 16, color: Colors.black),
                          label: const Text(
                            'Fullscreen',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
