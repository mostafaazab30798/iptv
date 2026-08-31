import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/app/theme/app_icons.dart';
import 'package:iptv/domain/entities/series.dart';
import 'package:iptv/shared/focus/focusable_card.dart';
import 'package:iptv/shared/widgets/cached_image.dart';

class SeriesCard extends StatelessWidget {
  const SeriesCard({
    super.key,
    required this.series,
    required this.onTap,
    this.width = 120,
    this.height = 175,
  });

  final Series series;
  final VoidCallback onTap;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: width,
            height: height,
            child: FocusableCard(
              onTap: onTap,
              padding: EdgeInsets.zero,
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedImage(
                    imageUrl: series.cover,
                    width: width,
                    height: height,
                    fit: BoxFit.cover,
                    borderRadius: BorderRadius.circular(16),
                    fallbackIcon: AppIcons.series,
                  ),
                  if (series.rating != null && series.rating!.isNotEmpty)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(200),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: AppColors.warning.withAlpha(120), width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const HugeIcon(icon: AppIcons.star, color: AppColors.warning, size: 10),
                            const SizedBox(width: 2),
                            Text(
                              series.rating!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 7),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              series.name,
              style: const TextStyle(
                color: Color(0xFFC5C9D3),
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
