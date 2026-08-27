import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/app/theme/app_icons.dart';
import 'package:iptv/domain/entities/channel.dart';
import 'package:iptv/features/favorites/favorite_channel_ids.dart';
import 'package:iptv/shared/focus/focusable_card.dart';
import 'package:iptv/shared/widgets/smart_channel_logo.dart';

/// State-of-the-Art Channel List Tile inspired by top Dribbble & Apple TV OTT designs:
/// - Dark reflective squircle container with specular border highlights
/// - 44x44 Squircle Logo Stage with dark reflective canvas and active cyan glow ring
/// - Multi-tier metadata hierarchy (Channel ID chip, category, live time/clock)
/// - Bold high-contrast channel typography with glowing active state
/// - Animated/styled Live Equalizer indicator when playing
/// - Instant 1-tap quick Favorite heart button + contextual 3-dots menu
class ChannelListTile extends ConsumerWidget {
  const ChannelListTile({
    super.key,
    required this.channel,
    required this.isPlaying,
    required this.onTap,
    this.categoryName,
    this.timeOrEpg,
    this.onMoreOptions,
  });

  final Channel channel;
  final bool isPlaying;
  final VoidCallback onTap;
  final String? categoryName;
  final String? timeOrEpg;
  final VoidCallback? onMoreOptions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasEpgOrTime = timeOrEpg != null && timeOrEpg!.trim().isNotEmpty;

    return FocusableCard(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      backgroundColor: isPlaying
          ? AppColors.accent.withAlpha(28)
          : const Color(0xFF10131B),
      borderColor: isPlaying
          ? AppColors.accent.withAlpha(160)
          : Colors.white.withAlpha(18),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          // 1. Left 44x44 Squircle Logo Stage
          _buildLogoStage(),
          const SizedBox(width: 14),

          // 2. Middle Content Column: Channel Name (+ EPG info if available)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Main Channel Name
                Text(
                  channel.name,
                  style: TextStyle(
                    color: isPlaying ? AppColors.accent : AppColors.textPrimary,
                    fontSize: 15.0,
                    fontWeight: isPlaying ? FontWeight.w800 : FontWeight.w600,
                    letterSpacing: 0.2,
                    shadows: isPlaying
                        ? [
                            Shadow(
                              color: AppColors.accent.withAlpha(150),
                              blurRadius: 10,
                            ),
                          ]
                        : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                if (hasEpgOrTime) ...[
                  const SizedBox(height: 3),
                  // Time / EPG Tag
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HugeIcon(
                        icon: AppIcons.history,
                        size: 11.5,
                        color: isPlaying ? AppColors.accent : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          timeOrEpg!,
                          style: TextStyle(
                            color: isPlaying ? AppColors.accent : AppColors.textSecondary,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),

          // 3. Right Status & Actions Area
          if (isPlaying) ...[
            _buildLiveEqualizerBadge(),
            const SizedBox(width: 8),
          ],

          // Quick Favorite Toggle Button
          _QuickFavoriteButton(channel: channel),
          const SizedBox(width: 2),

          // 3-Dots Context Menu Button
          _buildMoreMenu(context, ref),
        ],
      ),
    );
  }

  Widget _buildLogoStage() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: isPlaying ? const Color(0xFF0F1B2B) : const Color(0xFF0D1017),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPlaying
              ? AppColors.accent
              : Colors.white.withAlpha(20),
          width: isPlaying ? 1.5 : 0.9,
        ),
        boxShadow: isPlaying
            ? [
                BoxShadow(
                  color: AppColors.accent.withAlpha(120),
                  blurRadius: 12,
                  spreadRadius: -1,
                  offset: const Offset(0, 2),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withAlpha(60),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Center(
            child: SmartChannelLogo(
              channel: channel,
              width: 36,
              height: 36,
              fit: BoxFit.contain,
              fallbackIcon: isPlaying ? AppIcons.play : AppIcons.live,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLiveEqualizerBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.accent, Color(0xFF0088FF)],
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withAlpha(130),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(icon: AppIcons.waveform, color: Colors.black, size: 14),
          SizedBox(width: 4),
          Text(
            'PLAYING',
            style: TextStyle(
              color: Colors.black,
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoreMenu(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      tooltip: 'Options',
      padding: EdgeInsets.zero,
      color: AppColors.bg2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border, width: 0.8),
      ),
      icon: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.white.withAlpha(8),
        ),
        child: const HugeIcon(
          icon: AppIcons.moreVert,
          size: 18,
          color: AppColors.textSecondary,
        ),
      ),
      onSelected: (value) async {
        switch (value) {
          case 'play':
            onTap();
            break;
          case 'favorite':
            final ids = ref.read(favoriteChannelIdsProvider);
            final wasFav = ids.contains(channel.streamId);
            await ref.read(favoriteChannelIdsProvider.notifier).toggleChannel(
                  itemId: channel.streamId,
                  name: channel.name,
                  imageUrl: channel.streamIcon,
                );
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    wasFav
                        ? 'Removed ${channel.name} from Favorites'
                        : 'Added ${channel.name} to Favorites',
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem<String>(
          value: 'play',
          child: Row(
            children: [
              HugeIcon(icon: AppIcons.play, color: AppColors.accent, size: 18),
              SizedBox(width: 10),
              Text('Play Channel', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'favorite',
          child: Row(
            children: [
              HugeIcon(icon: AppIcons.star, color: AppColors.warning, size: 18),
              SizedBox(width: 10),
              Text('Toggle Favorite', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Instant 1-tap quick Favorite heart button — membership from a batched ID set.
class _QuickFavoriteButton extends ConsumerWidget {
  const _QuickFavoriteButton({required this.channel});
  final Channel channel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFav = ref.watch(
      favoriteChannelIdsProvider.select((ids) => ids.contains(channel.streamId)),
    );

    return IconButton(
      tooltip: isFav ? 'Remove Favorite' : 'Add to Favorites',
      iconSize: 18,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      onPressed: () async {
        await ref.read(favoriteChannelIdsProvider.notifier).toggleChannel(
              itemId: channel.streamId,
              name: channel.name,
              imageUrl: channel.streamIcon,
            );
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isFav
                  ? 'Removed ${channel.name} from Favorites'
                  : 'Added ${channel.name} to Favorites',
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: HugeIcon(
          icon: AppIcons.favorites,
          key: ValueKey(isFav),
          color: isFav ? AppColors.live : AppColors.textSecondary.withAlpha(160),
          size: 18,
        ),
      ),
    );
  }
}
