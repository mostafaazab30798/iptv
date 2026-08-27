import 'package:iptv/core/utils/result.dart';
import 'package:iptv/domain/entities/favorite.dart';

abstract interface class FavoritesRepository {
  Future<Result<List<Favorite>>> getFavorites({FavoriteType? type});
  Future<Result<void>> addFavorite(Favorite favorite);
  Future<Result<void>> removeFavorite(int favoriteId);
  Future<Result<void>> removeFavoriteByItemId({
    required FavoriteType type,
    required int itemId,
  });
  Future<bool> isFavorite({required FavoriteType type, required int itemId});
}
