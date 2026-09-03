import 'package:flutter/material.dart';
import 'package:iptv/app/theme/app_icons.dart';
import 'package:iptv/domain/entities/favorite.dart';
import 'package:iptv/domain/entities/series.dart';
import 'package:iptv/shared/widgets/cached_image.dart';
import 'package:iptv/shared/widgets/favorite_toggle_button.dart';

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

  int get _seriesItemId =>
      series.seriesId != 0 ? series.seriesId : series.id;

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
            child: PosterHeartCard(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              favorite: (heartFocus, onHeartDirection) => FavoriteToggleButton(
                type: FavoriteType.series,
                itemId: _seriesItemId,
                name: series.name,
                imageUrl: series.cover,
                size: 20,
                padding: 2,
                focusNode: heartFocus,
                onDirection: onHeartDirection,
              ),
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
                    memCacheWidth: 160,
                    memCacheHeight: 240,
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
