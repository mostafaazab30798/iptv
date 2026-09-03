import 'package:flutter/material.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/app/theme/app_icons.dart';
import 'package:iptv/domain/entities/channel.dart';
import 'package:iptv/shared/focus/focusable_card.dart';
import 'package:iptv/shared/widgets/smart_channel_logo.dart';

/// Compact channel poster used in Home rows and live grids.
///
/// Avoids per-card gradients/glow shadows that dominate scroll raster time.
class ChannelCard extends StatelessWidget {
  const ChannelCard({
    super.key,
    required this.channel,
    required this.onTap,
    this.width = 148,
    this.height = 124,
    this.showBadge = true,
    this.isPlaying = false,
    this.categoryName,
  });

  final Channel channel;
  final VoidCallback onTap;
  final double width;
  final double height;
  final bool showBadge;
  final bool isPlaying;
  final String? categoryName;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: FocusableCard(
        onTap: onTap,
        padding: const EdgeInsets.all(5),
        borderRadius: BorderRadius.circular(14),
        backgroundColor: isPlaying
            ? AppColors.accent.withAlpha(30)
            : const Color(0xFF10131B),
        borderColor: isPlaying
            ? AppColors.accent.withAlpha(180)
            : Colors.white.withAlpha(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: isPlaying
                      ? AppColors.accent.withAlpha(20)
                      : const Color(0xFF0A0C13),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isPlaying
                        ? AppColors.accent.withAlpha(120)
                        : Colors.white.withAlpha(15),
                    width: 0.9,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        child: Center(
                          child: SmartChannelLogo(
                            channel: channel,
                            width: width - 26,
                            height: height * 0.55,
                            fit: BoxFit.contain,
                            fallbackIcon:
                                isPlaying ? AppIcons.play : AppIcons.live,
                          ),
                        ),
                      ),
                    ),
                    if (isPlaying)
                      const Positioned(
                        top: 4,
                        right: 4,
                        child: _MicroBadge(
                          label: 'PLAYING',
                          foreground: Colors.black,
                          background: AppColors.accent,
                        ),
                      )
                    else if (showBadge)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: _MicroBadge(
                          label: 'LIVE',
                          foreground: const Color(0xFF00FF87),
                          background: const Color(0xFF00FF87).withAlpha(30),
                          borderColor: const Color(0xFF00FF87).withAlpha(120),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Text(
                channel.name,
                style: TextStyle(
                  color: isPlaying ? AppColors.accent : Colors.white,
                  fontSize: 11.5,
                  fontWeight: isPlaying ? FontWeight.w800 : FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 2),
          ],
        ),
      ),
    );
  }
}

class _MicroBadge extends StatelessWidget {
  const _MicroBadge({
    required this.label,
    required this.foreground,
    required this.background,
    this.borderColor,
  });

  final String label;
  final Color foreground;
  final Color background;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1.5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(4),
        border: borderColor == null
            ? null
            : Border.all(color: borderColor!, width: 0.7),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 7.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
