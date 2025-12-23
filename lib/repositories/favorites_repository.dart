import '../models/favorite_model.dart';
import '../services/auth_service.dart';

class FavoritesException implements Exception {
  final String message;
  FavoritesException(this.message);
  @override
  String toString() => message;
}

class FavoritesRepository {
  final AuthService _authService;

  FavoritesRepository({AuthService? authService})
      : _authService = authService ?? AuthService();

  Future<T> _makeAuthenticatedRequest<T>(Future<T> Function() apiCall) async {
    try {
      if (!await _authService.isLoggedIn()) {
        throw FavoritesException('You must be logged in to manage favorites.');
      }
      return await apiCall();
    } on Exception catch (e) {
      if (e.toString().contains('401') || e.toString().contains('Authentication failed')) {
        final refreshed = await _authService.refreshAccessToken();
        if (refreshed) {
          return await apiCall();
        } else {
          throw FavoritesException('Your session has expired. Please log in again.');
        }
      }
      rethrow;
    }
  }

  Future<List<FavoriteModel>> getFavorites() async {
    return _makeAuthenticatedRequest(() async {
      final result = await _authService.getFavorites();
      if (result['success'] == true) {
        return result['data'] as List<FavoriteModel>;
      } else {
        throw FavoritesException(result['message'] ?? 'Failed to fetch favorites.');
      }
    });
  }

  Future<void> toggleFavorite(int productId) async {
    await _makeAuthenticatedRequest(() async {
      final result = await _authService.toggleFavorite(productId);
      if (result['success'] != true) {
        throw FavoritesException(result['message'] ?? 'Failed to update favorite status.');
      }
    });
  }
}