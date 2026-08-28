import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iptv/app/providers.dart';
import 'package:iptv/app/router.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/app/theme/app_icons.dart';
import 'package:iptv/app/theme/app_motion.dart';
import 'package:iptv/app/theme/app_radius.dart';
import 'package:iptv/app/theme/app_spacing.dart';
import 'package:iptv/data/datasources/xtream_remote_datasource.dart';
import 'package:iptv/domain/entities/category.dart';
import 'package:iptv/domain/entities/season.dart';
import 'package:iptv/domain/entities/series.dart';
import 'package:iptv/features/series/series_controller.dart';

import 'package:iptv/player/player_controller.dart';
import 'package:iptv/player/player_source.dart';
import 'package:iptv/shared/extensions/context_extensions.dart';
import 'package:iptv/shared/focus/focusable_card.dart';
import 'package:iptv/shared/widgets/cached_image.dart';
import 'package:iptv/shared/widgets/category_card.dart';
import 'package:iptv/shared/widgets/empty_state.dart';
import 'package:iptv/shared/widgets/skeleton_loaders.dart';

/// Category-First Series Screen:
/// Stage 1: Categories Hub showcases Series Categories with show count badges.
/// Stage 2: Series Grid View with cover posters, ratings, and in-category search.
class SeriesScreen extends ConsumerStatefulWidget {
  const SeriesScreen({super.key});

  @override
  ConsumerState<SeriesScreen> createState() => _SeriesScreenState();
}

class _SeriesScreenState extends ConsumerState<SeriesScreen> {
  Category? _selectedCategory;
  bool _isAllSeriesSelected = false;

  final TextEditingController _seriesSearchController = TextEditingController();

  @override
  void dispose() {
    _seriesSearchController.dispose();
    super.dispose();
  }

  void _onBack() {
    if (_selectedCategory != null || _isAllSeriesSelected) {
      setState(() {
        _selectedCategory = null;
        _isAllSeriesSelected = false;
      });
      _seriesSearchController.clear();
      ref.read(seriesControllerProvider.notifier).showCategoriesHub();
    } else {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(Routes.home);
      }
    }
  }

  void _selectCategory(Category? category, {bool isAll = false}) {
    setState(() {
      _selectedCategory = category;
      _isAllSeriesSelected = isAll;
    });
    _seriesSearchController.clear();
    final notifier = ref.read(seriesControllerProvider.notifier);
    if (isAll) {
      notifier.showAllSeries();
    } else if (category != null) {
      notifier.selectCategory(category.id);
    } else {
      notifier.showCategoriesHub();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCategorySelected =
        _selectedCategory != null || _isAllSeriesSelected;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: Scaffold(
        backgroundColor: AppColors.bg0,
        body: AnimatedSwitcher(
          duration: MotionPolicy.of(context).standard,
          child: isCategorySelected
              ? _SeriesGridConsumer(builder: _buildSeriesGridView)
              : _SeriesCategoriesConsumer(builder: _buildCategoriesHub),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Stage 1: Series Categories Hub
  // ---------------------------------------------------------------------------

  Widget _buildCategoriesHub(SeriesState seriesState) {
    if (seriesState.isLoading && seriesState.categories.isEmpty) {
      return const CategoryListSkeleton();
    }

    final categories = seriesState.categories;

    return KeyedSubtree(
      key: const ValueKey('series_categories_hub'),
      child: categories.isEmpty
          ? EmptyState(
              title: context.l10n.labelNoResults,
              subtitle: context.l10n.homeCheckConnection,
              icon: AppIcons.series,
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              cacheExtent: 350,
              itemCount: categories.length + 1,
              separatorBuilder: (_, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return CategoryCard(
                    title: context.l10n.labelAllSeries,
                    itemCount: seriesState.totalSeriesCount,
                    itemCountLabel: context.l10n.labelSeries,
                    isAllCard: true,
                    onTap: () => _selectCategory(null, isAll: true),
                  );
                }

                final category = categories[index - 1];
                final count = seriesState.categoryCounts[category.id] ?? 0;
                final logoUrl = seriesState.categoryLeadingCovers[category.id];

                return CategoryCard(
                  title: category.name,
                  itemCount: count,
                  itemCountLabel: context.l10n.labelSeries,
                  logoUrl: logoUrl,
                  onTap: () => _selectCategory(category),
                );
              },
            ),
    );
  }

  // ---------------------------------------------------------------------------
  // Stage 2: Series Grid View
  // ---------------------------------------------------------------------------

  Widget _buildSeriesGridView(SeriesState seriesState) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final categoryTitle = _isAllSeriesSelected
        ? context.l10n.labelAllSeries
        : (_selectedCategory?.name ?? context.l10n.navSeries);
    final backIcon = isRtl ? AppIcons.chevronRight : AppIcons.chevronLeft;

    return Column(
      key: const ValueKey('series_grid_view'),
      children: [
        // Category Breadcrumb Header Bar
        LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 600;
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: const BoxDecoration(
                color: AppColors.bg1,
                border: Border(
                  bottom: BorderSide(color: AppColors.border, width: 0.8),
                ),
              ),
              child: Row(
                children: [
                  if (isCompact)
                    IconButton(
                      onPressed: _onBack,
                      tooltip: context.l10n.labelCategories,
                      icon: HugeIcon(
                        icon: backIcon,
                        size: 14,
                        color: AppColors.accent,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.accent.withAlpha(25),
                        padding: const EdgeInsets.all(8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    )
                  else
                    TextButton.icon(
                      onPressed: _onBack,
                      icon: HugeIcon(
                        icon: backIcon,
                        size: 14,
                        color: AppColors.accent,
                      ),
                      label: Text(
                        context.l10n.labelCategories,
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.accent.withAlpha(25),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            categoryTitle,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.bg3,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${seriesState.filteredSeries.length}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Responsive Search input
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isCompact ? 120 : 200,
                      minWidth: 80,
                    ),
                    child: SizedBox(
                      height: 34,
                      child: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _seriesSearchController,
                        builder: (context, value, _) {
                          return TextField(
                            controller: _seriesSearchController,
                            onChanged: (q) {
                              ref
                                  .read(seriesControllerProvider.notifier)
                                  .search(q);
                            },
                            style: const TextStyle(fontSize: 12),
                            decoration: InputDecoration(
                              hintText: isCompact
                                  ? context.l10n.actionSearch
                                  : context.l10n.seriesSearchHint,
                              prefixIcon: const HugeIcon(
                                icon: AppIcons.search,
                                size: 15,
                                color: AppColors.textSecondary,
                              ),
                              suffixIcon: value.text.isNotEmpty
                                  ? IconButton(
                                      icon: const HugeIcon(
                                        icon: AppIcons.close,
                                        size: 13,
                                        color: AppColors.textSecondary,
                                      ),
                                      onPressed: () {
                                        _seriesSearchController.clear();
                                        ref
                                            .read(
                                              seriesControllerProvider.notifier,
                                            )
                                            .search('');
                                      },
                                    )
                                  : null,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 0,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        // Series Poster Grid
        Expanded(
          child: seriesState.isLoading
              ? const PosterGridSkeleton()
              : seriesState.filteredSeries.isEmpty
              ? EmptyState(
                  title: context.l10n.seriesNoSeriesFound,
                  subtitle: context.l10n.searchNoResultsSubtitle,
                  icon: AppIcons.series,
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  cacheExtent: 350,
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 170,
                    childAspectRatio: 2 / 3,
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.md,
                  ),
                  itemCount: seriesState.filteredSeries.length,
                  itemBuilder: (context, i) {
                    final series = seriesState.filteredSeries[i];
                    return _SeriesPosterCard(
                      series: series,
                      onTap: () => _openSeriesDetails(context, series),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _openSeriesDetails(BuildContext context, Series series) {
    showSeriesDetailsModal(context, series);
  }
}

class _SeriesCategoriesConsumer extends ConsumerWidget {
  const _SeriesCategoriesConsumer({required this.builder});

  final Widget Function(SeriesState state) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(
      seriesControllerProvider.select(
        (state) => (
          categories: state.categories,
          totalSeriesCount: state.totalSeriesCount,
          categoryCounts: state.categoryCounts,
          categoryLeadingCovers: state.categoryLeadingCovers,
          isLoading: state.isLoading,
        ),
      ),
    );
    return builder(
      SeriesState(
        categories: state.categories,
        totalSeriesCount: state.totalSeriesCount,
        categoryCounts: state.categoryCounts,
        categoryLeadingCovers: state.categoryLeadingCovers,
        isLoading: state.isLoading,
      ),
    );
  }
}

class _SeriesGridConsumer extends ConsumerWidget {
  const _SeriesGridConsumer({required this.builder});

  final Widget Function(SeriesState state) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(
      seriesControllerProvider.select(
        (state) =>
            (filteredSeries: state.filteredSeries, isLoading: state.isLoading),
      ),
    );
    return builder(
      SeriesState(
        filteredSeries: state.filteredSeries,
        isLoading: state.isLoading,
      ),
    );
  }
}

/// Helper to present series seasons & episodes modal from any screen.
void showSeriesDetailsModal(BuildContext context, Series series) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.bg1,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _SeriesDetailsModal(series: series),
  );
}

class _SeriesDetailsModal extends ConsumerStatefulWidget {
  const _SeriesDetailsModal({required this.series});
  final Series series;

  @override
  ConsumerState<_SeriesDetailsModal> createState() =>
      _SeriesDetailsModalState();
}

class _SeriesDetailsModalState extends ConsumerState<_SeriesDetailsModal> {
  int _selectedSeasonIndex = 0;
  List<Season> _seasons = const [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSeasons();
  }

  Future<void> _loadSeasons() async {
    final repo = ref.read(seriesRepositoryProvider);
    if (repo == null) return;

    try {
      final seriesId = widget.series.seriesId != 0
          ? widget.series.seriesId
          : widget.series.id;
      final res = await repo.getSeasons(seriesId);
      res.when(
        ok: (seasons) {
          if (mounted) {
            setState(() {
              _seasons = seasons;
              _selectedSeasonIndex = 0;
              _isLoading = false;
            });
          }
        },
        err: (e) {
          if (mounted) {
            setState(() {
              _error = e.message;
              _isLoading = false;
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _playEpisode(Episode episode) {
    final session = ref.read(sessionProvider).valueOrNull;
    if (session == null) return;

    EpisodeSource buildSource(Episode ep, int seasonNum) {
      final streamId = ep.streamId != 0 ? ep.streamId : ep.id;
      final streamUrl = XtreamRemoteDataSource.buildSeriesStreamUrl(
        serverUrl: session.serverUrl,
        username: session.username,
        password: session.password,
        streamId: streamId,
        extension: ep.containerExtension ?? 'mp4',
      );
      return EpisodeSource(
        url: streamUrl,
        title:
            '${widget.series.name} - S${seasonNum}E${ep.episodeNum}: ${ep.title}',
        episodeId: streamId,
        seriesName: widget.series.name,
        posterUrl: ep.cover ?? widget.series.cover,
      );
    }

    // Flatten all seasons so next/prev can move across the series.
    final playlist = <PlayerSource>[];
    var initialIndex = 0;
    for (final season in _seasons) {
      for (final ep in season.episodes) {
        if (ep.id == episode.id ||
            (ep.streamId != 0 && ep.streamId == episode.streamId) ||
            (episode.streamId != 0 && ep.id == episode.streamId)) {
          initialIndex = playlist.length;
        }
        playlist.add(buildSource(ep, season.seasonNumber));
      }
    }

    if (playlist.isEmpty) {
      final seasonNum =
          (_selectedSeasonIndex >= 0 && _selectedSeasonIndex < _seasons.length)
          ? _seasons[_selectedSeasonIndex].seasonNumber
          : episode.seasonLocalId;
      playlist.add(buildSource(episode, seasonNum));
    }

    final playerNotifier = ref.read(playerControllerProvider.notifier);
    playerNotifier.setChannelPlaylist(playlist, initialIndex: initialIndex);
    playerNotifier.load(playlist[initialIndex]);

    Navigator.of(context).pop();
    context.push(Routes.player);
  }

  @override
  Widget build(BuildContext context) {
    final safeSeasonIndex =
        (_selectedSeasonIndex >= 0 && _selectedSeasonIndex < _seasons.length)
        ? _selectedSeasonIndex
        : 0;

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
            // Header with Series Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 70,
                      height: 100,
                      child: CachedImage(
                        imageUrl: widget.series.cover,
                        width: 70,
                        height: 100,
                        fit: BoxFit.cover,
                        fallbackIcon: AppIcons.series,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.series.name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            if (widget.series.rating != null &&
                                widget.series.rating!.isNotEmpty) ...[
                              const HugeIcon(
                                icon: AppIcons.star,
                                color: AppColors.warning,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.series.rating!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            if (widget.series.releaseYear != null) ...[
                              Text(
                                '${widget.series.releaseYear}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            if (widget.series.genre != null &&
                                widget.series.genre!.isNotEmpty)
                              Expanded(
                                child: Text(
                                  widget.series.genre!,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                        if (widget.series.plot != null &&
                            widget.series.plot!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            widget.series.plot!,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12),

            // Body: Seasons & Episodes
            Expanded(
              child: _isLoading
                  ? const SeriesDetailSkeleton()
                  : _error != null
                  ? Center(
                      child: Text(
                        'Error: $_error',
                        style: const TextStyle(color: AppColors.error),
                      ),
                    )
                  : _seasons.isEmpty
                  ? Center(
                      child: Text(
                        context.l10n.labelNoResults,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Season Tabs
                        if (_seasons.length > 1)
                          SizedBox(
                            height: 40,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemCount: _seasons.length,
                              separatorBuilder: (_, index) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (context, idx) {
                                final isSelected = idx == safeSeasonIndex;
                                final season = _seasons[idx];
                                final epCount = season.episodes.length;
                                final seasonTitle =
                                    season.name ??
                                    context.l10n.labelSeason(
                                      season.seasonNumber,
                                    );
                                final labelText = epCount > 0
                                    ? '$seasonTitle ($epCount)'
                                    : seasonTitle;

                                return ChoiceChip(
                                  label: Text(labelText),
                                  selected: isSelected,
                                  onSelected: (_) => setState(
                                    () => _selectedSeasonIndex = idx,
                                  ),
                                  selectedColor: AppColors.accent,
                                  backgroundColor: AppColors.bg2,
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.textSecondary,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    fontSize: 12,
                                  ),
                                );
                              },
                            ),
                          ),
                        const SizedBox(height: 8),

                        // Episode List
                        Expanded(
                          child: _seasons[safeSeasonIndex].episodes.isEmpty
                              ? Center(
                                  child: Text(
                                    context.l10n.labelNoResults,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  controller: scrollController,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  itemCount:
                                      _seasons[safeSeasonIndex].episodes.length,
                                  separatorBuilder: (_, index) =>
                                      const SizedBox(height: 8),
                                  itemBuilder: (context, epIdx) {
                                    final ep = _seasons[safeSeasonIndex]
                                        .episodes[epIdx];
                                    return FocusableCard(
                                      onTap: () => _playEpisode(ep),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          // Episode image thumbnail or number badge
                                          if (ep.cover != null &&
                                              ep.cover!.isNotEmpty)
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              child: Stack(
                                                alignment:
                                                    Alignment.bottomRight,
                                                children: [
                                                  SizedBox(
                                                    width: 72,
                                                    height: 48,
                                                    child: CachedImage(
                                                      imageUrl: ep.cover,
                                                      fit: BoxFit.cover,
                                                      fallbackIcon:
                                                          AppIcons.movies,
                                                    ),
                                                  ),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 4,
                                                          vertical: 1,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.black
                                                          .withAlpha(200),
                                                      borderRadius:
                                                          const BorderRadius.only(
                                                            topLeft:
                                                                Radius.circular(
                                                                  4,
                                                                ),
                                                          ),
                                                    ),
                                                    child: Text(
                                                      'E${ep.episodeNum}',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 9,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                          else
                                            Container(
                                              width: 36,
                                              height: 36,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                color: AppColors.bg3,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                '${ep.episodeNum}',
                                                style: const TextStyle(
                                                  color: AppColors.textPrimary,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  ep.title,
                                                  style: const TextStyle(
                                                    color:
                                                        AppColors.textPrimary,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                if (ep.plot != null &&
                                                    ep.plot!.isNotEmpty) ...[
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    ep.plot!,
                                                    style: const TextStyle(
                                                      color: AppColors
                                                          .textSecondary,
                                                      fontSize: 11,
                                                    ),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ],
                                                if (ep.durationSecs != null &&
                                                    ep.durationSecs! > 0) ...[
                                                  const SizedBox(height: 3),
                                                  Text(
                                                    '${(ep.durationSecs! / 60).round()} min',
                                                    style: const TextStyle(
                                                      color: AppColors.accent,
                                                      fontSize: 10.5,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const HugeIcon(
                                            icon: AppIcons.play,
                                            color: AppColors.accent,
                                            size: 26,
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _SeriesPosterCard extends StatelessWidget {
  const _SeriesPosterCard({required this.series, required this.onTap});

  final Series series;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FocusableCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedImage(
            imageUrl: series.cover,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.circular(AppRadius.card),
            fallbackIcon: AppIcons.series,
            memCacheWidth: 170,
            memCacheHeight: 255,
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(AppRadius.card),
                ),
                gradient: LinearGradient(
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
          if (series.rating != null && series.rating!.isNotEmpty)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(200),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.warning, width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const HugeIcon(
                      icon: AppIcons.star,
                      color: AppColors.warning,
                      size: 11,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      series.rating!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
