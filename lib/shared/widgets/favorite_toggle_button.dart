import 'dart:async';

import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/app/theme/app_radius.dart';
import 'package:iptv/domain/entities/favorite.dart';
import 'package:iptv/features/favorites/favorite_channel_ids.dart';
import 'package:iptv/features/favorites/favorite_ids.dart';
import 'package:iptv/shared/focus/focusable_card.dart';
import 'package:iptv/shared/focus/tv_focusable.dart';
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
    this.focusNode,
    this.onDirection,
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
  final FocusNode? focusNode;
  final DpadDirectionCallback? onDirection;

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

    return TvFocusable(
      scale: 1.18,
      focusNode: focusNode,
      onDirection: onDirection,
      onSelect: () => unawaited(_handlePressed(context, ref)),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Padding(
          padding: EdgeInsets.all(padding),
          // No AnimatedSwitcher / text shadows — Home rows host dozens of these.
          child: Icon(
            isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            size: size,
            color: isFav ? AppColors.live : (idleColor ?? Colors.white),
          ),
        ),
      ),
    );
  }

  Future<void> _handlePressed(BuildContext context, WidgetRef ref) async {
    final nowFav = await _toggle(ref);
    ref.invalidate(favoritesListProvider);
    if (!showSnackBar || !context.mounted) return;
    showFavoriteSnackBar(context, name: name, isFavorite: nowFav);
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

/// Poster with a separate D-pad stop for the favorite heart.
///
/// The heart is a sibling of [FocusableCard] (not a child), so it is not
/// swallowed by [DpadFocusable.excludeChildFocus]. Left/right on the card
/// row lands on the heart; Up/Down leave the card so the shell and hero
/// stay reachable.
class PosterHeartCard extends StatefulWidget {
  const PosterHeartCard({
    super.key,
    required this.onTap,
    required this.child,
    required this.favorite,
    this.borderRadius,
    this.backgroundColor,
    this.borderColor,
    this.padding,
    this.autofocus = false,
  });

  final VoidCallback onTap;
  final Widget child;
  final Widget Function(
    FocusNode heartFocus,
    DpadDirectionCallback onHeartDirection,
  ) favorite;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final EdgeInsets? padding;
  final bool autofocus;

  @override
  State<PosterHeartCard> createState() => _PosterHeartCardState();
}

class _PosterHeartCardState extends State<PosterHeartCard> {
  late final FocusNode _cardFocus;
  late final FocusNode _heartFocus;

  @override
  void initState() {
    super.initState();
    _cardFocus = FocusNode(debugLabel: 'poster');
    _heartFocus = FocusNode(debugLabel: 'favorite');
  }

  @override
  void dispose() {
    _cardFocus.dispose();
    _heartFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final towardHeart =
        rtl ? TraversalDirection.right : TraversalDirection.left;
    final towardCard =
        rtl ? TraversalDirection.left : TraversalDirection.right;

    return Stack(
      fit: StackFit.expand,
      children: [
        FocusableCard(
          autofocus: widget.autofocus,
          focusNode: _cardFocus,
          onTap: widget.onTap,
          padding: widget.padding ?? EdgeInsets.zero,
          borderRadius: widget.borderRadius ??
              BorderRadius.circular(AppRadius.card),
          backgroundColor: widget.backgroundColor,
          borderColor: widget.borderColor,
          onDirection: (direction) {
            if (direction == towardHeart) {
              _heartFocus.requestFocus();
              return true;
            }
            return false;
          },
          child: widget.child,
        ),
        // Use start (not physical left) so the heart stays opposite the
        // rating badge in both LTR and RTL (Arabic).
        PositionedDirectional(
          top: 0,
          start: 0,
          child: widget.favorite(
            _heartFocus,
            (direction) {
              if (direction == towardCard) {
                _cardFocus.requestFocus();
                return true;
              }
              return false;
            },
          ),
        ),
      ],
    );
  }
}

/// Top poster strip: optional heart (start) + rating badge (end).
class PosterTopActions extends StatelessWidget {
  const PosterTopActions({
    super.key,
    this.favoriteButton,
    this.rating,
    this.compact = false,
  });

  final Widget? favoriteButton;
  final String? rating;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final hasRating = rating != null && rating!.trim().isNotEmpty;
    final starSize = compact ? 10.0 : 11.0;
    final textSize = compact ? 9.5 : 10.0;
    final hPad = compact ? 5.0 : 6.0;
    final vPad = compact ? 2.0 : 2.0;

    final ratingBadge = !hasRating
        ? null
        : Container(
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
              textDirection: TextDirection.ltr,
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
          );

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (favoriteButton != null) favoriteButton!,
          const Spacer(),
          if (ratingBadge != null) ratingBadge,
        ],
      ),
    );
  }
}
