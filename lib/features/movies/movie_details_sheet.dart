import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iptv/app/providers.dart';
import 'package:iptv/app/router.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/app/theme/app_icons.dart';
import 'package:iptv/app/theme/app_radius.dart';
import 'package:iptv/app/theme/app_spacing.dart';
import 'package:iptv/domain/entities/favorite.dart';
import 'package:iptv/domain/entities/movie.dart';
import 'package:iptv/player/player_controller.dart';
import 'package:iptv/player/player_source.dart';
import 'package:iptv/shared/extensions/context_extensions.dart';
import 'package:iptv/shared/widgets/cached_image.dart';
import 'package:iptv/shared/widgets/favorite_toggle_button.dart';

/// Helper to present movie details modal from any screen.
void showMovieDetailsModal(BuildContext context, Movie movie) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.bg1,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _MovieDetailsModal(movie: movie),
  );
}

class _MovieDetailsModal extends ConsumerStatefulWidget {
  const _MovieDetailsModal({required this.movie});

  final Movie movie;

  @override
  ConsumerState<_MovieDetailsModal> createState() => _MovieDetailsModalState();
}

class _MovieDetailsModalState extends ConsumerState<_MovieDetailsModal> {
  late Movie _movie;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _movie = widget.movie;
    _loadMovieDetails();
  }

  Future<void> _loadMovieDetails() async {
    final repo = ref.read(vodRepositoryProvider);
    if (repo == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final res = await repo.getMovieDetails(_movie.streamId, fallback: _movie);
      if (mounted) {
        setState(() {
          if (res.isOk) {
            _movie = res.value;
          }
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _playMovie() {
    final session = ref.read(sessionProvider).valueOrNull;
    if (session == null) return;

    final streamUrl = ref.read(streamUrlBuilderProvider).vodForSession(
      session,
      streamId: _movie.streamId,
      extension: _movie.containerExtension ?? 'mp4',
    );

    ref.read(playerControllerProvider.notifier).load(
      VodSource(
        movieId: _movie.streamId,
        title: _movie.name,
        url: streamUrl,
        posterUrl: _movie.streamIcon,
      ),
    );

    Navigator.of(context).pop();
    context.push(Routes.player);
  }

  String? _formatDuration(int? secs) {
    if (secs == null || secs <= 0) return null;
    final hours = secs ~/ 3600;
    final minutes = (secs % 3600) ~/ 60;
    if (hours > 0) {
      return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    }
    return '$minutes min';
  }

  @override
  Widget build(BuildContext context) {
    final durationStr = _formatDuration(_movie.durationSecs);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Main scrollable content
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xs,
                ),
                children: [
                  // Header with Movie Info
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Poster
                      SizedBox(
                        width: 76,
                        height: 110,
                        child: CachedImage(
                          imageUrl: _movie.streamIcon,
                          width: 76,
                          height: 110,
                          fit: BoxFit.cover,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          fallbackIcon: AppIcons.movies,
                          memCacheWidth: 152,
                          memCacheHeight: 220,
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Title & Badges
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    _movie.name,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 16.5,
                                      fontWeight: FontWeight.bold,
                                      height: 1.25,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                FavoriteToggleButton(
                                  type: FavoriteType.movie,
                                  itemId: _movie.streamId,
                                  name: _movie.name,
                                  imageUrl: _movie.streamIcon,
                                  size: 22,
                                  padding: 4,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Metadata Badges Row
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                if (_movie.rating != null &&
                                    (double.tryParse(_movie.rating!.replaceAll(',', '.')) ?? 0.0) > 0.0) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.warning.withAlpha(35),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const HugeIcon(
                                          icon: AppIcons.star,
                                          color: AppColors.warning,
                                          size: 13,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          _movie.rating!,
                                          style: const TextStyle(
                                            color: AppColors.warning,
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                if (_movie.releaseYear != null &&
                                    _movie.releaseYear! > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.bg3,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Text(
                                      '${_movie.releaseYear}',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                if (durationStr != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.bg3,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Text(
                                      durationStr,
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                if (_movie.videoResolution != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.accent.withAlpha(30),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Text(
                                      _movie.videoResolution!,
                                      style: const TextStyle(
                                        color: AppColors.accent,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                if (_movie.mpaaRating != null &&
                                    _movie.mpaaRating!.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 1.5,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: AppColors.border,
                                        width: 0.8,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      _movie.mpaaRating!,
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),

                            if (_movie.genre != null &&
                                _movie.genre!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                _movie.genre!,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Prominent Play Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: _playMovie,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.textOnAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        shadowColor: AppColors.accentGlow,
                      ),
                      icon: const HugeIcon(
                        icon: AppIcons.play,
                        color: AppColors.textOnAccent,
                        size: 20,
                      ),
                      label: Text(
                        context.l10n.actionPlay,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 12),

                  // Story / Plot Section
                  Text(
                    context.l10n.labelPlot,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (_isLoading && (_movie.plot == null || _movie.plot!.isEmpty))
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    )
                  else
                    Text(
                      (_movie.plot != null && _movie.plot!.isNotEmpty)
                          ? _movie.plot!
                          : context.l10n.labelNoDescription,
                      style: TextStyle(
                        color: (_movie.plot != null && _movie.plot!.isNotEmpty)
                            ? AppColors.textPrimary.withAlpha(210)
                            : AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Additional Details (Director, Cast, Release Date, Country, Format)
                  _buildDetailsSection(context),

                  // Backdrop Gallery (if available)
                  if (_movie.backdropPaths != null &&
                      _movie.backdropPaths!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text(
                      'Gallery',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 100,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _movie.backdropPaths!.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          final imgUrl = _movie.backdropPaths![i];
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedImage(
                              imageUrl: imgUrl,
                              width: 170,
                              height: 100,
                              fit: BoxFit.cover,
                              fallbackIcon: AppIcons.imageFallback,
                              memCacheWidth: 340,
                              memCacheHeight: 200,
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailsSection(BuildContext context) {
    final details = <_DetailItem>[];

    if (_movie.director != null && _movie.director!.isNotEmpty) {
      details.add(
        _DetailItem(label: context.l10n.labelDirector, value: _movie.director!),
      );
    }

    if (_movie.cast != null && _movie.cast!.isNotEmpty) {
      details.add(
        _DetailItem(label: context.l10n.labelCast, value: _movie.cast!),
      );
    }

    if (_movie.releaseDate != null && _movie.releaseDate!.isNotEmpty) {
      details.add(
        _DetailItem(
          label: context.l10n.labelReleaseDate,
          value: _movie.releaseDate!,
        ),
      );
    }

    if (_movie.country != null && _movie.country!.isNotEmpty) {
      details.add(_DetailItem(label: 'Country', value: _movie.country!));
    }

    if (_movie.containerExtension != null &&
        _movie.containerExtension!.isNotEmpty) {
      details.add(
        _DetailItem(
          label: 'Format',
          value: _movie.containerExtension!.toUpperCase(),
        ),
      );
    }

    if (details.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Column(
        children: details.map((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 90,
                  child: Text(
                    item.label,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.value,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DetailItem {
  const _DetailItem({required this.label, required this.value});
  final String label;
  final String value;
}
