import 'package:grocery_app/models/favorite_model.dart';
import 'package:grocery_app/services/api_client.dart';
import 'package:grocery_app/services/api_config.dart';

abstract class FavoritesRemoteDataSource {
  Future<List<FavoriteModel>> fetchFavorites();
  Future<void> toggleFavorite(int productId);
}

class FavoritesRemoteDataSourceImpl implements FavoritesRemoteDataSource {
  final ApiClient _apiClient;

  const FavoritesRemoteDataSourceImpl(this._apiClient);

  @override
  Future<List<FavoriteModel>> fetchFavorites() async {
    final response = await _apiClient.get(
      ApiConfig.favoritesEndpoint,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = response.data;
      return data.map((json) => FavoriteModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch favorites');
    }
  }

  @override
  Future<void> toggleFavorite(int productId) async {
    final response = await _apiClient.post(
      '${ApiConfig.favoritesEndpoint}$productId/toggle/',
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to toggle favorite status');
    }
  }
}
