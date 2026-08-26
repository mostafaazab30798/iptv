import 'package:drift/drift.dart';
import 'package:iptv/core/storage/database/app_database.dart' as db;
import 'package:iptv/core/utils/result.dart';
import 'package:iptv/domain/entities/favorite.dart';
import 'package:iptv/domain/repositories/favorites_repository.dart';

class FavoritesRepositoryImpl implements FavoritesRepository {
  const FavoritesRepositoryImpl({required this.database});

  final db.AppDatabase database;

  @override
  Future<Result<List<Favorite>>> getFavorites({FavoriteType? type}) async {
    try {
      final query = database.select(database.favorites);
      if (type != null) {
        query.where((tbl) => tbl.type.equals(type.name));
      }
      final rows = await query.get();
      final items = rows.map((r) {
        return Favorite(
          id: r.id,
          type: FavoriteType.values.firstWhere(
            (e) => e.name == r.type,
            orElse: () => FavoriteType.channel,
          ),
          itemId: r.itemId,
          name: r.name,
          imageUrl: r.imageUrl,
          addedAt: r.addedAt,
        );
      }).toList();
      return Ok(items);
    } catch (e) {
      return Err(AppResultError('Failed to load favorites', cause: e));
    }
  }

  @override
  Future<Result<void>> addFavorite(Favorite favorite) async {
    try {
      await database.into(database.favorites).insert(
        db.FavoritesCompanion.insert(
          type: favorite.type.name,
          itemId: favorite.itemId,
          name: favorite.name,
          imageUrl: Value(favorite.imageUrl),
        ),
      );
      return const Ok(null);
    } catch (e) {
      return Err(AppResultError('Failed to add favorite', cause: e));
    }
  }

  @override
  Future<Result<void>> removeFavorite(int favoriteId) async {
    try {
      await (database.delete(database.favorites)
            ..where((tbl) => tbl.id.equals(favoriteId)))
          .go();
      return const Ok(null);
    } catch (e) {
      return Err(AppResultError('Failed to remove favorite', cause: e));
    }
  }

  @override
  Future<bool> isFavorite({required FavoriteType type, required int itemId}) async {
    try {
      final row = await (database.select(database.favorites)
            ..where((tbl) => tbl.type.equals(type.name) & tbl.itemId.equals(itemId)))
          .getSingleOrNull();
      return row != null;
    } catch (_) {
      return false;
    }
  }
}
