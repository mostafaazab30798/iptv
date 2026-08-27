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
import 'package:iptv/data/datasources/xtream_remote_datasource.dart';
import 'package:iptv/domain/entities/category.dart';
import 'package:iptv/domain/entities/movie.dart';
import 'package:iptv/features/movies/movies_controller.dart';
import 'package:iptv/player/player_controller.dart';
import 'package:iptv/player/player_source.dart';
import 'package:iptv/shared/extensions/context_extensions.dart';
import 'package:iptv/shared/focus/focusable_card.dart';
import 'package:iptv/shared/widgets/cached_image.dart';
import 'package:iptv/shared/widgets/category_card.dart';
import 'package:iptv/shared/widgets/empty_state.dart';
import 'package:iptv/shared/widgets/skeleton_loaders.dart';

class MoviesScreen extends ConsumerStatefulWidget {
  const MoviesScreen({super.key});

  @override
  ConsumerState<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends ConsumerState<MoviesScreen> {
  Category? _selectedCategory;
  bool _isAllMoviesSelected = false;

  final TextEditingController _movieSearchController = TextEditingController();

  @override
  void dispose() {
    _movieSearchController.dispose();
    super.dispose();
  }

  void _onBack() {
    if (_selectedCategory != null || _isAllMoviesSelected) {
      setState(() {
        _selectedCategory = null;
        _isAllMoviesSelected = false;
      });
      _movieSearchController.clear();
      ref.read(moviesControllerProvider.notifier).showCategoriesHub();
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
      _isAllMoviesSelected = isAll;
    });
    _movieSearchController.clear();
    final notifier = ref.read(moviesControllerProvider.notifier);
    if (isAll) {
      notifier.showAllMovies();
    } else if (category != null) {
      notifier.selectCategory(category.id);
    } else {
      notifier.showCategoriesHub();
    }
  }

  void _playMovie(Movie movie) {
    final session = ref.read(sessionProvider).valueOrNull;
    if (session == null) return;

    final streamUrl = XtreamRemoteDataSource.buildVodStreamUrl(
      serverUrl: session.serverUrl,
      username: session.username,
      password: session.password,
      streamId: movie.streamId,
      extension: movie.containerExtension ?? 'mp4',
    );

    ref.read(playerControllerProvider.notifier).load(
      VodSource(
        movieId: movie.streamId,
        title: movie.name,
        url: streamUrl,
        posterUrl: movie.streamIcon,
      ),
    );

    context.push(Routes.player);
  }

  @override
  Widget build(BuildContext context) {
    final moviesState = ref.watch(moviesControllerProvider);
    final isCategorySelected = _selectedCategory != null || _isAllMoviesSelected;

    return PopScope(
      canPop: !isCategorySelected,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && isCategorySelected) {
          _onBack();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bg0,
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: isCategorySelected
              ? _buildMoviesGridView(moviesState)
              : _buildCategoriesHub(moviesState),
        ),
      ),
    );
  }

  Widget _buildCategoriesHub(MoviesState moviesState) {
    if (moviesState.isLoading && moviesState.categories.isEmpty) {
      return const CategoryListSkeleton();
    }

    final categories = moviesState.categories;

    return KeyedSubtree(
      key: const ValueKey('movies_categories_hub'),
      child: categories.isEmpty
          ? EmptyState(
              title: context.l10n.labelNoResults,
              subtitle: context.l10n.homeCheckConnection,
              icon: AppIcons.movies,
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
              cacheExtent: 350,
              itemCount: categories.length + 1,
              separatorBuilder: (_, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return CategoryCard(
                    title: context.l10n.labelAllMovies,
                    itemCount: moviesState.totalMovieCount,
                    itemCountLabel: context.l10n.labelMovies,
                    isAllCard: true,
                    onTap: () => _selectCategory(null, isAll: true),
                  );
                }

                final category = categories[index - 1];
                final count = moviesState.categoryCounts[category.id] ?? 0;
                final logoUrl = moviesState.categoryLeadingLogos[category.id];

                return CategoryCard(
                  title: category.name,
                  itemCount: count,
                  itemCountLabel: context.l10n.labelMovies,
                  logoUrl: logoUrl,
                  onTap: () => _selectCategory(category),
                );
              },
            ),
    );
  }

  Widget _buildMoviesGridView(MoviesState moviesState) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final categoryTitle = _isAllMoviesSelected
        ? context.l10n.labelAllMovies
        : (_selectedCategory?.name ?? context.l10n.navMovies);
    final backIcon = isRtl ? AppIcons.chevronRight : AppIcons.chevronLeft;

    return Column(
      key: const ValueKey('movies_grid_view'),
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 600;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              decoration: const BoxDecoration(
                color: AppColors.bg1,
                border: Border(bottom: BorderSide(color: AppColors.border, width: 0.8)),
              ),
              child: Row(
                children: [
                  if (isCompact)
                    IconButton(
                      onPressed: _onBack,
                      tooltip: context.l10n.labelCategories,
                      icon: HugeIcon(icon: backIcon, size: 14, color: AppColors.accent),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.accent.withAlpha(25),
                        padding: const EdgeInsets.all(8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    )
                  else
                    TextButton.icon(
                      onPressed: _onBack,
                      icon: HugeIcon(icon: backIcon, size: 14, color: AppColors.accent),
                      label: Text(
                        context.l10n.labelCategories,
                        style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.accent.withAlpha(25),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.bg3,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${moviesState.filteredMovies.length}',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 10.5, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isCompact ? 120 : 200,
                      minWidth: 80,
                    ),
                    child: SizedBox(
                      height: 34,
                      child: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _movieSearchController,
                        builder: (context, value, _) {
                          return TextField(
                            controller: _movieSearchController,
                            onChanged: (q) {
                              ref.read(moviesControllerProvider.notifier).search(q);
                            },
                            style: const TextStyle(fontSize: 12),
                            decoration: InputDecoration(
                              hintText: isCompact ? context.l10n.actionSearch : context.l10n.moviesSearchHint,
                              prefixIcon: const HugeIcon(icon: AppIcons.search, size: 15, color: AppColors.textSecondary),
                              suffixIcon: value.text.isNotEmpty
                                  ? IconButton(
                                      icon: const HugeIcon(icon: AppIcons.close, size: 13, color: AppColors.textSecondary),
                                      onPressed: () {
                                        _movieSearchController.clear();
                                        ref.read(moviesControllerProvider.notifier).search('');
                                      },
                                    )
                                  : null,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
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
        Expanded(
          child: moviesState.isLoading
              ? const PosterGridSkeleton()
              : moviesState.filteredMovies.isEmpty
                  ? EmptyState(
                      title: context.l10n.moviesNoMoviesFound,
                      subtitle: context.l10n.searchNoResultsSubtitle,
                      icon: AppIcons.movies,
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
                      itemCount: moviesState.filteredMovies.length,
                      itemBuilder: (context, i) {
                        final movie = moviesState.filteredMovies[i];
                        return _MovieGridCard(
                          movie: movie,
                          onTap: () => _playMovie(movie),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

class _MovieGridCard extends StatelessWidget {
  const _MovieGridCard({required this.movie, required this.onTap});

  final Movie movie;
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
            imageUrl: movie.streamIcon,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.circular(AppRadius.card),
            fallbackIcon: AppIcons.movies,
            // Grid cells are max 170×255 logical px — cap decoded bitmap to display size
            // to avoid loading 300–1000px source posters into multi-MB decoded bitmaps.
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
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(AppRadius.card)),
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
                    movie.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (movie.releaseYear != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${movie.releaseYear}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (movie.rating != null && movie.rating!.isNotEmpty)
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
                    const HugeIcon(icon: AppIcons.star, color: AppColors.warning, size: 11),
                    const SizedBox(width: 3),
                    Text(
                      movie.rating!,
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
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
