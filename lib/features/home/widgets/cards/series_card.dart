import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/app/theme/app_icons.dart';
import 'package:iptv/app/theme/app_radius.dart';
import 'package:iptv/domain/entities/favorite.dart';
import 'package:iptv/domain/entities/series.dart';
import 'package:iptv/features/home/widgets/cards/movie_card.dart';
import 'package:iptv/features/home/widgets/cards/poster_card_layout.dart';
import 'package:iptv/shared/widgets/cached_image.dart';
import 'package:iptv/shared/widgets/favorite_toggle_button.dart';

class SeriesCard extends StatelessWidget {
  const SeriesCard({
    super.key,
    required this.series,
    required this.onTap,
    this.width = PosterCardLayout.defaultWidth,
    this.height = PosterCardLayout.defaultPosterHeight,
    this.expand = false,
    this.borderRadius = AppRadius.lg,
    this.heartSize = 20,
    this.memCacheWidth,
    this.memCacheHeight,
    this.titlePlacement = PosterTitlePlacement.below,
  });

  final Series series;
  final VoidCallback onTap;
  final double width;
  final double height;

  /// When true, ignore [width]/[height] and scale from parent constraints
  /// (grid cells). Prefer explicit sizes for horizontal rows.
  final bool expand;

  final double borderRadius;
  final double heartSize;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final PosterTitlePlacement titlePlacement;

  int get _seriesItemId =>
      series.seriesId != 0 ? series.seriesId : series.id;

  @override
  Widget build(BuildContext context) {
    if (expand) {
      return LayoutBuilder(
        builder: (context, constraints) {
          if (titlePlacement == PosterTitlePlacement.overlay) {
            final w = constraints.maxWidth.isFinite && constraints.maxWidth > 0
                ? constraints.maxWidth
                : PosterCardLayout.defaultWidth;
            final h = constraints.maxHeight.isFinite && constraints.maxHeight > 0
                ? constraints.maxHeight
                : PosterCardLayout.posterHeightForWidth(w);
            return _buildOverlayCard(w, h);
          }
          final fitted = PosterCardLayout.fit(
            maxWidth: constraints.maxWidth,
            maxHeight:
                constraints.maxHeight.isFinite ? constraints.maxHeight : null,
          );
          return _buildBelowCard(fitted.width, fitted.posterHeight);
        },
      );
    }
    if (titlePlacement == PosterTitlePlacement.overlay) {
      return _buildOverlayCard(width, height);
    }
    return _buildBelowCard(width, height);
  }

  BorderRadius get _radius => BorderRadius.circular(borderRadius);

  (int, int) _cacheSize(double w, double posterH) {
    final cacheW =
        memCacheWidth ?? (w * 1.5).round().clamp(80, 240);
    final cacheH =
        memCacheHeight ?? (posterH * 1.5).round().clamp(120, 360);
    return (cacheW, cacheH);
  }

  Widget _favorite(
    FocusNode heartFocus,
    DpadDirectionCallback onHeartDirection,
  ) {
    return FavoriteToggleButton(
      type: FavoriteType.series,
      itemId: _seriesItemId,
      name: series.name,
      imageUrl: series.cover,
      size: heartSize,
      padding: 2,
      focusNode: heartFocus,
      onDirection: onHeartDirection,
    );
  }

  Widget _buildBelowCard(double w, double posterH) {
    final (cacheW, cacheH) = _cacheSize(w, posterH);

    return SizedBox(
      width: w,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: w,
            height: posterH,
            child: PosterHeartCard(
              onTap: onTap,
              borderRadius: _radius,
              favorite: _favorite,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedImage(
                    imageUrl: series.cover,
                    width: w,
                    height: posterH,
                    fit: BoxFit.cover,
                    borderRadius: _radius,
                    fallbackIcon: AppIcons.series,
                    memCacheWidth: cacheW,
                    memCacheHeight: cacheH,
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: IgnorePointer(
                      child: PosterTopActions(
                        compact: true,
                        rating: series.rating,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: PosterCardLayout.titleGap),
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

  Widget _buildOverlayCard(double w, double posterH) {
    final (cacheW, cacheH) = _cacheSize(w, posterH);

    return SizedBox(
      width: w,
      height: posterH,
      child: PosterHeartCard(
        onTap: onTap,
        borderRadius: _radius,
        favorite: _favorite,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedImage(
              imageUrl: series.cover,
              width: w,
              height: posterH,
              fit: BoxFit.cover,
              borderRadius: _radius,
              fallbackIcon: AppIcons.series,
              memCacheWidth: cacheW,
              memCacheHeight: cacheH,
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: PosterTopActions(rating: series.rating),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(borderRadius),
                  ),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xE6000000)],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      series.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (series.releaseYear != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${series.releaseYear}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
