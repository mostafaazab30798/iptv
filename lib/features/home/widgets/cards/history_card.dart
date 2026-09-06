import 'package:flutter/material.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/app/theme/app_icons.dart';
import 'package:iptv/domain/entities/watch_history.dart';
import 'package:iptv/features/home/widgets/cards/poster_card_layout.dart';
import 'package:iptv/shared/focus/focusable_card.dart';
import 'package:iptv/shared/widgets/cached_image.dart';

class HistoryCard extends StatelessWidget {
  const HistoryCard({
    super.key,
    required this.entry,
    required this.onTap,
    this.width = PosterCardLayout.defaultWidth,
    this.height = PosterCardLayout.defaultPosterHeight,
    this.expand = false,
  });

  final WatchHistoryEntry entry;
  final VoidCallback onTap;
  final double width;
  final double height;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    if (expand) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final fitted = PosterCardLayout.fit(
            maxWidth: constraints.maxWidth,
            maxHeight:
                constraints.maxHeight.isFinite ? constraints.maxHeight : null,
          );
          return _buildCard(fitted.width, fitted.posterHeight);
        },
      );
    }
    return _buildCard(width, height);
  }

  Widget _buildCard(double w, double posterH) {
    final progress = entry.progressFraction;
    final cacheW = (w * 1.5).round().clamp(80, 240);
    final cacheH = (posterH * 1.5).round().clamp(120, 360);

    return SizedBox(
      width: w,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: w,
            height: posterH,
            child: FocusableCard(
              onTap: onTap,
              padding: EdgeInsets.zero,
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedImage(
                    imageUrl: entry.imageUrl,
                    width: w,
                    height: posterH,
                    fit: BoxFit.cover,
                    borderRadius: BorderRadius.circular(16),
                    fallbackIcon: AppIcons.play,
                    memCacheWidth: cacheW,
                    memCacheHeight: cacheH,
                  ),
                  if (progress > 0) ...[
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 48,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(16),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withAlpha(160),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 8,
                      right: 8,
                      bottom: 8,
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(100),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(120),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Directionality(
                          textDirection: TextDirection.ltr,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(100),
                            child: LinearProgressIndicator(
                              value: progress.clamp(0.0, 1.0),
                              backgroundColor: Colors.white.withAlpha(50),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.accent,
                              ),
                              minHeight: 4,
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: PosterCardLayout.titleGap),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              entry.name,
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
