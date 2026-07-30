import '../entities/favorite_entity.dart';
import '../repositories/favorites_repository.dart';

class GetFavoritesUseCase {
  final FavoritesRepository _repository;

  const GetFavoritesUseCase(this._repository);

  Future<List<FavoriteEntity>> call() {
    return _repository.getFavorites();
  }
}
