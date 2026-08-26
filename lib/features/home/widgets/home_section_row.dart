import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/app/theme/app_icons.dart';
import 'package:iptv/app/theme/app_spacing.dart';

import 'package:iptv/shared/extensions/context_extensions.dart';

class HomeSectionRow<T> extends StatelessWidget {
  const HomeSectionRow({
    super.key,
    required this.title,
    this.icon,
    this.badgeText,
    this.onSeeAll,
    required this.items,
    required this.itemBuilder,
    this.height = 140,
  });

  final String title;
  final dynamic icon;
  final String? badgeText;
  final VoidCallback? onSeeAll;
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Row(
            children: [
              if (icon != null) ...[
                icon is IconData
                    ? Icon(icon as IconData, color: AppColors.accent, size: 18)
                    : HugeIcon(icon: icon as List<List<dynamic>>, color: AppColors.accent, size: 18),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              if (badgeText != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.bg3,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Text(
                    badgeText!,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              if (onSeeAll != null)
                TextButton(
                  onPressed: onSeeAll,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.l10n.actionSeeAll,
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      HugeIcon(
                        icon: isRtl ? AppIcons.chevronLeft : AppIcons.chevronRight,
                        color: AppColors.accent,
                        size: 12,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        // Horizontal scrolling items
        SizedBox(
          height: height,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, index) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, i) => itemBuilder(context, items[i], i),
          ),
        ),

        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}
