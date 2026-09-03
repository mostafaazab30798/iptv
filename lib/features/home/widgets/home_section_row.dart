import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/app/theme/app_icons.dart';
import 'package:iptv/app/theme/app_spacing.dart';

import 'package:iptv/shared/extensions/context_extensions.dart';
import 'package:iptv/shared/focus/tv_focusable.dart';

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
    this.itemWidth,
  });

  final String title;
  final dynamic icon;
  final String? badgeText;
  final VoidCallback? onSeeAll;
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final double height;

  /// When set, enables fixed [ListView] item extents (width + gap) for cheaper layout.
  final double? itemWidth;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return DpadRegion(
      memoryKey: 'home/${title.toLowerCase()}',
      debugLabel: title,
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (icon != null) ...[
                icon is IconData
                    ? Icon(icon as IconData, color: AppColors.accent, size: 18)
                    : HugeIcon(icon: icon as List<List<dynamic>>, color: AppColors.accent, size: 18),
                const SizedBox(width: 8),
              ],
              _buildTitle(context, title),
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
                TvFocusable(
                  onSelect: onSeeAll,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                ),
            ],
          ),
        ),

        // Horizontal scrolling items — extra height so scaled TV focus isn't clipped.
        SizedBox(
          height: height + 20,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            primary: false,
            // Keep off-screen card FocusNodes / images from staying warm forever.
            addAutomaticKeepAlives: false,
            addRepaintBoundaries: true,
            // Small cache: decoding/painting off-screen posters is a top jank source.
            cacheExtent: 120,
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 10),
            itemCount: items.length,
            itemExtent: itemWidth == null ? null : itemWidth! + 12,
            itemBuilder: (context, index) {
              final child = itemBuilder(context, items[index], index);
              if (itemWidth == null) {
                return Padding(
                  padding: EdgeInsetsDirectional.only(
                    end: index == items.length - 1 ? 0 : 12,
                  ),
                  child: child,
                );
              }
              return Padding(
                padding: const EdgeInsetsDirectional.only(end: 12),
                child: SizedBox(width: itemWidth, child: child),
              );
            },
          ),
        ),

        const SizedBox(height: AppSpacing.xl),
      ],
    ),
    );
  }

  Widget _buildTitle(BuildContext context, String title) {
    final trimmed = title.trim();
    final spaceIdx = trimmed.indexOf(' ');
    const blueTone = Color(0xFF00C2FF);
    final isEn = Localizations.localeOf(context).languageCode == 'en';

    if (spaceIdx == -1) {
      return Text(
        trimmed.toUpperCase(),
        style: TextStyle(
          color: isEn ? blueTone : Colors.white,
          fontSize: 16.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      );
    }

    final firstWord = trimmed.substring(0, spaceIdx).toUpperCase();
    final rest = trimmed.substring(spaceIdx + 1).toUpperCase();

    // In English: first word (e.g. CONTINUE, FEATURED, POPULAR) is white,
    // and second word (WATCHING, MOVIES, SERIES, CHANNELS) is blue!
    final firstColor = isEn ? Colors.white : blueTone;
    final firstWeight = isEn ? FontWeight.w800 : FontWeight.w400;
    final secondColor = isEn ? blueTone : Colors.white;
    final secondWeight = isEn ? FontWeight.w800 : FontWeight.w900;

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$firstWord ',
            style: TextStyle(
              color: firstColor,
              fontSize: 16.5,
              fontWeight: firstWeight,
              letterSpacing: 0.8,
            ),
          ),
          TextSpan(
            text: rest,
            style: TextStyle(
              color: secondColor,
              fontSize: 16.5,
              fontWeight: secondWeight,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
