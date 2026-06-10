import '../models/favorite_model.dart';
import '../services/token_service.dart';
import '../services/profile_service.dart';
import 'package:grocery_app/service_locator.dart';

class FavoritesException implements Exception {
  final String message;
  FavoritesException(this.message);
  @override
  String toString() => message;
}


class FavoritesRepository {
  final TokenService _tokenService;
  final ProfileService _profileService;

  FavoritesRepository({
    TokenService? tokenService,
    ProfileService? profileService,
  })  : _tokenService = tokenService ?? getIt<TokenService>(),
        _profileService = profileService ?? getIt<ProfileService>();

  Future<List<FavoriteModel>> getFavorites() async {
    if (!await _tokenService.isLoggedIn()) {
      throw FavoritesException('You must be logged in to manage favorites.');
    }
    final result = await _profileService.getFavorites();
    if (result['success'] == true) {
      return result['data'] as List<FavoriteModel>;
    } else {
      throw FavoritesException(result['message'] ?? 'Failed to fetch favorites.');
    }
  }

  Future<void> toggleFavorite(int productId) async {
    if (!await _tokenService.isLoggedIn()) {
      throw FavoritesException('You must be logged in to manage favorites.');
    }
    final result = await _profileService.toggleFavorite(productId);
    if (result['success'] != true) {
      throw FavoritesException(result['message'] ?? 'Failed to update favorite status.');
    }
  }
}