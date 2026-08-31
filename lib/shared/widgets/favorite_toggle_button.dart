import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/domain/entities/favorite.dart';
import 'package:iptv/features/favorites/favorite_channel_ids.dart';
import 'package:iptv/features/favorites/favorite_ids.dart';
import 'package:iptv/shared/widgets/favorite_snackbar.dart';

/// Compact heart toggle for channels, movies, and series.
/// Outline when idle; solid filled when favorited.
class FavoriteToggleButton extends ConsumerWidget {
  const FavoriteToggleButton({
    super.key,
    required this.type,
    required this.itemId,
    required this.name,
    this.imageUrl,
    this.size = 22,
    this.padding = 4,
    this.showSnackBar = true,
    this.idleColor,
  });

  final FavoriteType type;
  final int itemId;
  final String name;
  final String? imageUrl;
  final double size;
  final double padding;
  final bool showSnackBar;
  /// Outline color when not favorited. Defaults to white.
  final Color? idleColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFav = switch (type) {
      FavoriteType.channel => ref.watch(
          favoriteChannelIdsProvider.select((ids) => ids.contains(itemId)),
        ),
      FavoriteType.movie => ref.watch(
          favoriteMovieIdsProvider.select((ids) => ids.contains(itemId)),
        ),
      FavoriteType.series => ref.watch(
          favoriteSeriesIdsProvider.select((ids) => ids.contains(itemId)),
        ),
    };

    return IconButton(
      tooltip: isFav ? 'Remove Favorite' : 'Add to Favorites',
      iconSize: size,
      padding: EdgeInsets.all(padding),
      constraints: BoxConstraints(
        minWidth: size + padding * 2,
        minHeight: size + padding * 2,
      ),
      visualDensity: VisualDensity.compact,
      onPressed: () async {
        final nowFav = await _toggle(ref);
        ref.invalidate(favoritesListProvider);
        if (!showSnackBar || !context.mounted) return;
        showFavoriteSnackBar(context, name: name, isFavorite: nowFav);
      },
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOutBack,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) {
          return ScaleTransition(
            scale: animation,
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        child: Icon(
          isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          key: ValueKey(isFav),
          size: size,
          color: isFav ? AppColors.live : (idleColor ?? Colors.white),
          shadows: const [
            Shadow(color: Colors.black87, blurRadius: 6, offset: Offset(0, 1)),
            Shadow(color: Colors.black54, blurRadius: 2),
          ],
        ),
      ),
    );
  }

  Future<bool> _toggle(WidgetRef ref) {
    return switch (type) {
      FavoriteType.channel =>
        ref.read(favoriteChannelIdsProvider.notifier).toggleChannel(
              itemId: itemId,
              name: name,
              imageUrl: imageUrl,
            ),
      FavoriteType.movie => ref.read(favoriteMovieIdsProvider.notifier).toggle(
            itemId: itemId,
            name: name,
            imageUrl: imageUrl,
          ),
      FavoriteType.series =>
        ref.read(favoriteSeriesIdsProvider.notifier).toggle(
              itemId: itemId,
              name: name,
              imageUrl: imageUrl,
            ),
    };
  }
}

/// Top poster strip: heart (left) + rating badge (right), same baseline.
class PosterTopActions extends StatelessWidget {
  const PosterTopActions({
    super.key,
    required this.favoriteButton,
    this.rating,
    this.compact = false,
  });

  final Widget favoriteButton;
  final String? rating;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final hasRating = rating != null && rating!.trim().isNotEmpty;
    final starSize = compact ? 10.0 : 11.0;
    final textSize = compact ? 9.5 : 10.0;
    final hPad = compact ? 5.0 : 6.0;
    final vPad = compact ? 2.0 : 2.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          favoriteButton,
          const Spacer(),
          if (hasRating)
            Container(
              padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(200),
                borderRadius: BorderRadius.circular(compact ? 5 : 4),
                border: Border.all(
                  color: AppColors.warning.withAlpha(compact ? 120 : 255),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.star_rounded,
                    color: AppColors.warning,
                    size: starSize,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    rating!,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: textSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
