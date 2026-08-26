import 'package:flutter/material.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/player/domain/entities/player_source.dart';
import 'package:iptv/shared/widgets/smart_channel_logo.dart';

/// Channel info and current EPG timeline overlay banner.
class ChannelOverlayBanner extends StatelessWidget {
  const ChannelOverlayBanner({
    super.key,
    required this.source,
  });

  final PlayerSource source;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Channel Logo
          SmartChannelLogo(
            channelName: source.title,
            logoUrl: source.logoUrl,
            width: 52,
            height: 52,
            borderRadius: BorderRadius.circular(8),
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 16),
          // Info & Program
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  source.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                // Current program or fallback
                Text(
                  source.currentProgramTitle ?? 'Live Broadcast',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                // Progress Bar if available
                if (source.programProgress != null) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: LinearProgressIndicator(
                        value: source.programProgress!.clamp(0.0, 1.0),
                        minHeight: 4,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                      ),
                    ),
                  ),
                ],
                // Next Program if available
                if (source.nextProgramTitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Next: ${source.nextProgramTitle}',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
