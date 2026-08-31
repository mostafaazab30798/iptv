import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iptv/app/providers.dart';
import 'package:iptv/domain/entities/favorite.dart';
import 'package:iptv/domain/repositories/favorites_repository.dart';
import 'package:iptv/features/favorites/favorite_channel_ids.dart';

final favoritesListProvider = FutureProvider<List<Favorite>>((ref) async {
  final repo = ref.watch(favoritesRepositoryProvider);
  final allowed = await ref.watch(kidsAllowedContentProvider.future);
  final res = await repo.getFavorites();
  return res.when(
    ok: (list) => list.where(allowed.allowsFavorite).toList(),
    err: (_) => [],
  );
});

/// Batch-loaded favorite item IDs for a single [FavoriteType].
class FavoriteIdsNotifier extends StateNotifier<Set<int>> {
  FavoriteIdsNotifier(this._repo, this.type) : super(const {}) {
    refresh();
  }

  final FavoritesRepository _repo;
  final FavoriteType type;

  Future<void> refresh() async {
    final res = await _repo.getFavorites(type: type);
    final ids = res.when(
      ok: (list) => {for (final f in list) f.itemId},
      err: (_) => <int>{},
    );
    if (mounted) state = ids;
  }

  bool contains(int itemId) => state.contains(itemId);

  /// Returns `true` if the item is favorited after the toggle.
  Future<bool> toggle({
    required int itemId,
    required String name,
    String? imageUrl,
  }) async {
    final currentlyFav = state.contains(itemId);
    if (currentlyFav) {
      await _repo.removeFavoriteByItemId(type: type, itemId: itemId);
      if (!mounted) return false;
      state = {...state}..remove(itemId);
      return false;
    }

    await _repo.addFavorite(
      Favorite(
        id: itemId,
        type: type,
        itemId: itemId,
        name: name,
        imageUrl: imageUrl,
        addedAt: DateTime.now(),
      ),
    );
    if (!mounted) return true;
    state = {...state, itemId};
    return true;
  }
}

final favoriteMovieIdsProvider =
    StateNotifierProvider<FavoriteIdsNotifier, Set<int>>((ref) {
  ref.keepAlive();
  return FavoriteIdsNotifier(
    ref.watch(favoritesRepositoryProvider),
    FavoriteType.movie,
  );
});

final favoriteSeriesIdsProvider =
    StateNotifierProvider<FavoriteIdsNotifier, Set<int>>((ref) {
  ref.keepAlive();
  return FavoriteIdsNotifier(
    ref.watch(favoritesRepositoryProvider),
    FavoriteType.series,
  );
});

/// Refresh all favorite ID caches (e.g. after Favorites screen remove).
Future<void> refreshAllFavoriteIds(WidgetRef ref) async {
  await Future.wait([
    ref.read(favoriteChannelIdsProvider.notifier).refresh(),
    ref.read(favoriteMovieIdsProvider.notifier).refresh(),
    ref.read(favoriteSeriesIdsProvider.notifier).refresh(),
  ]);
}
