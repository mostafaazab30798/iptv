import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/app/theme/app_icons.dart';
import 'package:iptv/app/theme/app_radius.dart';
import 'package:iptv/domain/entities/favorite.dart';
import 'package:iptv/shared/extensions/context_extensions.dart';
import 'package:iptv/shared/focus/focusable_card.dart';
import 'package:iptv/shared/widgets/cached_image.dart';

/// Compact favorites list row (not a poster — used when list view is selected).
class FavoriteListTile extends StatelessWidget {
  const FavoriteListTile({
    super.key,
    required this.item,
    required this.typeLabel,
    required this.onTap,
    required this.onRemove,
  });

  final Favorite item;
  final String typeLabel;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return FocusableCard(
      onTap: onTap,
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.bg2,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: CachedImage(
              imageUrl: item.imageUrl,
              fallbackIcon: item.type == FavoriteType.channel
                  ? AppIcons.live
                  : (item.type == FavoriteType.movie
                        ? AppIcons.movies
                        : AppIcons.series),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              memCacheWidth: 64,
              memCacheHeight: 64,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withAlpha(25),
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                  child: Text(
                    typeLabel,
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const HugeIcon(
              icon: AppIcons.delete,
              color: AppColors.textDisabled,
              size: 20,
            ),
            tooltip: context.l10n.actionDelete,
            onPressed: onRemove,
          ),
          const SizedBox(width: 4),
          const HugeIcon(
            icon: AppIcons.play,
            color: AppColors.accent,
            size: 24,
          ),
        ],
      ),
    );
  }
}
