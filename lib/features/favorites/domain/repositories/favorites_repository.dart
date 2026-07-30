import '../entities/favorite_entity.dart';

abstract class FavoritesRepository {
  Future<List<FavoriteEntity>> getFavorites();
  Future<void> toggleFavorite(int productId);
}
