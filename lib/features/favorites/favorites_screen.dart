import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iptv/app/providers.dart';
import 'package:iptv/app/router.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/app/theme/app_icons.dart';
import 'package:iptv/app/theme/app_spacing.dart';
import 'package:iptv/data/datasources/xtream_remote_datasource.dart';
import 'package:iptv/domain/entities/favorite.dart';
import 'package:iptv/player/player.dart';
import 'package:iptv/shared/extensions/context_extensions.dart';
import 'package:iptv/shared/focus/focusable_card.dart';
import 'package:iptv/shared/widgets/cached_image.dart';
import 'package:iptv/shared/widgets/empty_state.dart';
import 'package:iptv/shared/widgets/skeleton_loaders.dart';

final favoritesListProvider = FutureProvider<List<Favorite>>((ref) async {
  final repo = ref.watch(favoritesRepositoryProvider);
  final allowed = await ref.watch(kidsAllowedContentProvider.future);
  final res = await repo.getFavorites();
  return res.when(
    ok: (list) => list.where(allowed.allowsFavorite).toList(),
    err: (_) => [],
  );
});

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  FavoriteType? _selectedTypeFilter;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isGridView = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.home);
    }
  }

  void _playFavorite(Favorite fav) {
    final session = ref.read(sessionProvider).valueOrNull;
    if (session == null) return;

    if (fav.type == FavoriteType.movie) {
      final streamUrl = XtreamRemoteDataSource.buildVodStreamUrl(
        serverUrl: session.serverUrl,
        username: session.username,
        password: session.password,
        streamId: fav.itemId,
      );
      ref.read(playerControllerProvider.notifier).load(
        VodSource(
          url: streamUrl,
          title: fav.name,
          movieId: fav.itemId,
          posterUrl: fav.imageUrl,
        ),
      );
    } else if (fav.type == FavoriteType.series) {
      final streamUrl = XtreamRemoteDataSource.buildSeriesStreamUrl(
        serverUrl: session.serverUrl,
        username: session.username,
        password: session.password,
        streamId: fav.itemId,
      );
      ref.read(playerControllerProvider.notifier).load(
        EpisodeSource(
          url: streamUrl,
          title: fav.name,
          episodeId: fav.itemId,
          posterUrl: fav.imageUrl,
        ),
      );
    } else {
      final streamUrl = XtreamRemoteDataSource.buildLiveStreamUrl(
        serverUrl: session.serverUrl,
        username: session.username,
        password: session.password,
        streamId: fav.itemId,
      );
      ref.read(playerControllerProvider.notifier).load(
        LiveSource(
          url: streamUrl,
          channelName: fav.name,
          channelId: fav.itemId,
          logoUrl: fav.imageUrl,
        ),
      );
    }

    context.push(Routes.player);
  }

  @override
  Widget build(BuildContext context) {
    final favoritesAsync = ref.watch(favoritesListProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: Scaffold(
        backgroundColor: AppColors.bg0,
        body: favoritesAsync.when(
          loading: () => const FavoritesSkeleton(),
          error: (e, _) => Center(
            child: Text('Error: $e', style: const TextStyle(color: AppColors.error)),
          ),
          data: (allItems) {
            if (allItems.isEmpty) {
              return EmptyState(
                title: context.l10n.favoritesEmptyTitle,
                subtitle: context.l10n.favoritesEmptySubtitle,
                icon: AppIcons.star,
              );
            }

            final channelCount = allItems.where((i) => i.type == FavoriteType.channel).length;
            final movieCount = allItems.where((i) => i.type == FavoriteType.movie).length;
            final seriesCount = allItems.where((i) => i.type == FavoriteType.series).length;

            final filteredItems = allItems.where((item) {
              if (_selectedTypeFilter != null && item.type != _selectedTypeFilter) {
                return false;
              }
              if (_searchQuery.isNotEmpty &&
                  !item.name.toLowerCase().contains(_searchQuery.toLowerCase())) {
                return false;
              }
              return true;
            }).toList();

            return Column(
              children: [
                // Top Filter & Search Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                  decoration: const BoxDecoration(
                    color: AppColors.bg1,
                    border: Border(bottom: BorderSide(color: AppColors.border, width: 0.8)),
                  ),
                  child: Row(
                    children: [
                      // Header Title & Total Badge
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const HugeIcon(icon: AppIcons.star, size: 18, color: AppColors.accent),
                          const SizedBox(width: 8),
                          Text(
                            context.l10n.favoritesTitle,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
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
                              '${allItems.length}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        key: const ValueKey('favorites_view_mode_toggle'),
                        icon: HugeIcon(
                          icon: _isGridView ? AppIcons.listView : AppIcons.gridView,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                        tooltip: _isGridView ? 'Switch to List View' : 'Switch to Grid View',
                        onPressed: () => setState(() => _isGridView = !_isGridView),
                      ),
                    ],
                  ),
                ),

                // Search & Filter Row
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
                  child: Column(
                    children: [
                      // Search Bar
                      SizedBox(
                        height: 38,
                        child: TextField(
                          controller: _searchController,
                          onChanged: (q) {
                            setState(() => _searchQuery = q.trim());
                          },
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: context.l10n.searchHint,
                            prefixIcon: const HugeIcon(icon: AppIcons.search, size: 18, color: AppColors.textSecondary),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const HugeIcon(icon: AppIcons.close, size: 16, color: AppColors.textSecondary),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      // Filter Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip(
                              label: context.l10n.labelAll,
                              count: allItems.length,
                              isSelected: _selectedTypeFilter == null,
                              onTap: () => setState(() => _selectedTypeFilter = null),
                            ),
                            if (channelCount > 0) ...[
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                label: context.l10n.labelChannels,
                                count: channelCount,
                                isSelected: _selectedTypeFilter == FavoriteType.channel,
                                onTap: () => setState(() => _selectedTypeFilter = FavoriteType.channel),
                              ),
                            ],
                            if (movieCount > 0) ...[
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                label: context.l10n.labelMovies,
                                count: movieCount,
                                isSelected: _selectedTypeFilter == FavoriteType.movie,
                                onTap: () => setState(() => _selectedTypeFilter = FavoriteType.movie),
                              ),
                            ],
                            if (seriesCount > 0) ...[
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                label: context.l10n.labelSeries,
                                count: seriesCount,
                                isSelected: _selectedTypeFilter == FavoriteType.series,
                                onTap: () => setState(() => _selectedTypeFilter = FavoriteType.series),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.sm),

                // Favorites Content
                Expanded(
                  child: filteredItems.isEmpty
                      ? EmptyState(
                          title: context.l10n.labelNoResults,
                          subtitle: context.l10n.searchNoResultsSubtitle,
                          icon: AppIcons.searchOff,
                        )
                      : _isGridView
                          ? GridView.builder(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 180,
                                childAspectRatio: 0.82,
                                crossAxisSpacing: AppSpacing.sm,
                                mainAxisSpacing: AppSpacing.sm,
                              ),
                              itemCount: filteredItems.length,
                              itemBuilder: (context, i) {
                                final item = filteredItems[i];
                                return _buildGridCard(item);
                              },
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              itemCount: filteredItems.length,
                              separatorBuilder: (_, index) => const SizedBox(height: AppSpacing.sm),
                              itemBuilder: (context, i) {
                                final item = filteredItems[i];
                                return _buildListCard(item);
                              },
                            ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent.withAlpha(35) : AppColors.bg1,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.border,
            width: isSelected ? 1.2 : 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.accent : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accent.withAlpha(60) : AppColors.bg2,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textDisabled,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListCard(Favorite item) {
    return FocusableCard(
      onTap: () => _playFavorite(item),
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.bg2,
              borderRadius: BorderRadius.circular(8),
            ),
            child: CachedImage(
              imageUrl: item.imageUrl,
              fallbackIcon: item.type == FavoriteType.channel
                  ? AppIcons.live
                  : (item.type == FavoriteType.movie ? AppIcons.movies : AppIcons.series),
              borderRadius: BorderRadius.circular(8),
              memCacheWidth: 64,
              memCacheHeight: 64,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withAlpha(25),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getTypeLabel(item.type),
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const HugeIcon(icon: AppIcons.delete, color: AppColors.textDisabled, size: 20),
            tooltip: context.l10n.actionDelete,
            onPressed: () async {
              await ref.read(favoritesRepositoryProvider).removeFavorite(item.id);
              ref.invalidate(favoritesListProvider);
            },
          ),
          const SizedBox(width: 4),
          const HugeIcon(icon: AppIcons.play, color: AppColors.accent, size: 24),
        ],
      ),
    );
  }

  Widget _buildGridCard(Favorite item) {
    return FocusableCard(
      onTap: () => _playFavorite(item),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.bg2,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: CachedImage(
                      imageUrl: item.imageUrl,
                      fallbackIcon: item.type == FavoriteType.channel
                          ? AppIcons.live
                          : (item.type == FavoriteType.movie ? AppIcons.movies : AppIcons.series),
                      fit: BoxFit.cover,
                      borderRadius: BorderRadius.circular(8),
                      memCacheWidth: 150,
                      memCacheHeight: 150,
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () async {
                      await ref.read(favoritesRepositoryProvider).removeFavorite(item.id);
                      ref.invalidate(favoritesListProvider);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(160),
                        shape: BoxShape.circle,
                      ),
                      child: const HugeIcon(icon: AppIcons.delete, color: Colors.white70, size: 14),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 4,
                  left: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(180),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _getTypeLabel(item.type),
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 8.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.name,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _getTypeLabel(FavoriteType type) {
    switch (type) {
      case FavoriteType.channel:
        return 'LIVE TV';
      case FavoriteType.movie:
        return 'MOVIE';
      case FavoriteType.series:
        return 'SERIES';
    }
  }
}
