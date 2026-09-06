import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:iptv/app/theme/app_spacing.dart';
import 'package:iptv/shared/widgets/section_header.dart';

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

    return DpadRegion(
      memoryKey: 'home/${title.toLowerCase()}',
      debugLabel: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: title,
            icon: icon,
            badgeText: badgeText,
            onSeeAll: onSeeAll,
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
}
