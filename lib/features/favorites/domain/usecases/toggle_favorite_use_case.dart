import '../repositories/favorites_repository.dart';

class ToggleFavoriteUseCase {
  final FavoritesRepository _repository;

  const ToggleFavoriteUseCase(this._repository);

  Future<void> call(int productId) {
    return _repository.toggleFavorite(productId);
  }
}
