import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iptv/app/providers.dart';
import 'package:iptv/domain/entities/favorite.dart';
import 'package:iptv/domain/repositories/favorites_repository.dart';

/// Batch-loaded favorite channel item IDs for scroll-friendly heart toggles.
class FavoriteChannelIdsNotifier extends StateNotifier<Set<int>> {
  FavoriteChannelIdsNotifier(this._repo) : super(const {}) {
    refresh();
  }

  final FavoritesRepository _repo;

  Future<void> refresh() async {
    final res = await _repo.getFavorites(type: FavoriteType.channel);
    final ids = res.when(
      ok: (list) => {for (final f in list) f.itemId},
      err: (_) => <int>{},
    );
    if (mounted) state = ids;
  }

  bool contains(int itemId) => state.contains(itemId);

  /// Returns `true` if the channel is favorited after the toggle.
  Future<bool> toggleChannel({
    required int itemId,
    required String name,
    String? imageUrl,
  }) async {
    final currentlyFav = state.contains(itemId);
    if (currentlyFav) {
      await _repo.removeFavoriteByItemId(
        type: FavoriteType.channel,
        itemId: itemId,
      );
      if (!mounted) return false;
      state = {...state}..remove(itemId);
      return false;
    }

    await _repo.addFavorite(
      Favorite(
        id: itemId,
        type: FavoriteType.channel,
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

final favoriteChannelIdsProvider =
    StateNotifierProvider<FavoriteChannelIdsNotifier, Set<int>>((ref) {
  ref.keepAlive();
  return FavoriteChannelIdsNotifier(ref.watch(favoritesRepositoryProvider));
});
