import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/app/theme/app_icons.dart';
import 'package:iptv/app/theme/app_motion.dart';
import 'package:iptv/app/theme/app_radius.dart';
import 'package:iptv/app/theme/app_spacing.dart';
import 'package:iptv/domain/entities/category.dart';
import 'package:iptv/domain/entities/movie.dart';
import 'package:iptv/features/catalog/catalog_categories_hub.dart';
import 'package:iptv/features/home/widgets/cards/movie_card.dart';
import 'package:iptv/features/movies/movie_details_sheet.dart';
import 'package:iptv/features/movies/movies_controller.dart';

export 'package:iptv/features/movies/movie_details_sheet.dart'
    show showMovieDetailsModal;
import 'package:iptv/shared/extensions/context_extensions.dart';
import 'package:iptv/shared/navigation/app_back_navigation.dart';
import 'package:iptv/shared/widgets/empty_state.dart';
import 'package:iptv/shared/widgets/error_view.dart';
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
      popOrGoHome(context);
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

  @override
  Widget build(BuildContext context) {
    final isCategorySelected =
        _selectedCategory != null || _isAllMoviesSelected;

    return InnerBackScope(
      onBack: () {
        if (_selectedCategory == null && !_isAllMoviesSelected) return false;
        _onBack();
        return true;
      },
      child: Scaffold(
        backgroundColor: AppColors.bg0,
        body: AnimatedSwitcher(
          duration: MotionPolicy.of(context).standard,
          child: isCategorySelected
              ? _MoviesGridConsumer(builder: _buildMoviesGridView)
              : _MoviesCategoriesConsumer(builder: _buildCategoriesHub),
        ),
      ),
    );
  }

  Widget _buildCategoriesHub(MoviesState moviesState) {
    return CatalogCategoriesHub<Movie, String?>(
      state: moviesState,
      hubKey: const ValueKey('movies_categories_hub'),
      allTitle: context.l10n.labelAllMovies,
      itemCountLabel: context.l10n.labelMovies,
      emptyIcon: AppIcons.movies,
      onRetry: () => ref
          .read(moviesControllerProvider.notifier)
          .loadData(forceRefresh: true),
      onSelectAll: () => _selectCategory(null, isAll: true),
      onSelectCategory: _selectCategory,
      leadingUrlOf: (logo) => logo,
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
                            '${moviesState.filteredMovies.length}',
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
                              ref
                                  .read(moviesControllerProvider.notifier)
                                  .search(q);
                            },
                            style: const TextStyle(fontSize: 12),
                            decoration: InputDecoration(
                              hintText: isCompact
                                  ? context.l10n.actionSearch
                                  : context.l10n.moviesSearchHint,
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
                                        _movieSearchController.clear();
                                        ref
                                            .read(
                                              moviesControllerProvider.notifier,
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
        Expanded(
          child: moviesState.isLoading
              ? const PosterGridSkeleton()
              : moviesState.filteredMovies.isEmpty
              ? (moviesState.error != null
                    ? ErrorView(
                        message: context.l10n.homeCheckConnection,
                        eyebrow: context.l10n.moviesNoMoviesFound,
                        onRetry: () => ref
                            .read(moviesControllerProvider.notifier)
                            .loadData(forceRefresh: true),
                      )
                    : EmptyState(
                        title: context.l10n.moviesNoMoviesFound,
                        subtitle: context.l10n.searchNoResultsSubtitle,
                        icon: AppIcons.movies,
                      ))
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
                    return MovieCard(
                      movie: movie,
                      expand: true,
                      borderRadius: AppRadius.card,
                      heartSize: 22,
                      memCacheWidth: 170,
                      memCacheHeight: 255,
                      titlePlacement: PosterTitlePlacement.overlay,
                      onTap: () => showMovieDetailsModal(context, movie),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _MoviesCategoriesConsumer extends ConsumerWidget {
  const _MoviesCategoriesConsumer({required this.builder});

  final Widget Function(MoviesState state) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(
      moviesControllerProvider.select(
        (state) => (
          categories: state.categories,
          totalCount: state.totalCount,
          categoryCounts: state.categoryCounts,
          categoryLeading: state.categoryLeading,
          isLoading: state.isLoading,
          error: state.error,
        ),
      ),
    );
    return builder(
      MoviesState(
        categories: state.categories,
        totalCount: state.totalCount,
        categoryCounts: state.categoryCounts,
        categoryLeading: state.categoryLeading,
        isLoading: state.isLoading,
        error: state.error,
      ),
    );
  }
}

class _MoviesGridConsumer extends ConsumerWidget {
  const _MoviesGridConsumer({required this.builder});

  final Widget Function(MoviesState state) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(
      moviesControllerProvider.select(
        (state) => (
          filteredItems: state.filteredItems,
          isLoading: state.isLoading,
          error: state.error,
        ),
      ),
    );
    return builder(
      MoviesState(
        filteredItems: state.filteredItems,
        isLoading: state.isLoading,
        error: state.error,
      ),
    );
  }
}
