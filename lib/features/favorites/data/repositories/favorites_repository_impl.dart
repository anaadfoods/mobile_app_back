import 'package:grocery_app/features/favorites/data/datasources/favorites_remote_data_source.dart';
import 'package:grocery_app/features/favorites/domain/entities/favorite_entity.dart';
import 'package:grocery_app/features/favorites/domain/failures/favorites_failure.dart';
import 'package:grocery_app/features/favorites/domain/repositories/favorites_repository.dart';
import 'package:grocery_app/models/favorite_model.dart';
import 'package:grocery_app/services/token_service.dart';

class FavoritesRepositoryImpl implements FavoritesRepository {
  final FavoritesRemoteDataSource _remoteDataSource;
  final TokenService _tokenService;

  const FavoritesRepositoryImpl({
    required FavoritesRemoteDataSource remoteDataSource,
    required TokenService tokenService,
  })  : _remoteDataSource = remoteDataSource,
        _tokenService = tokenService;

  @override
  Future<List<FavoriteEntity>> getFavorites() async {
    try {
      if (!await _tokenService.isLoggedIn()) {
        throw const FavoritesFailure(
          type: FavoritesFailureType.unauthorized,
          message: 'You must be logged in to manage favorites.',
        );
      }
      final DTOs = await _remoteDataSource.fetchFavorites();
      return DTOs.map((dto) => dto.toDomain()).toList();
    } on FavoritesFailure {
      rethrow;
    } catch (e) {
      throw FavoritesFailure(
        type: FavoritesFailureType.network,
        message: _getErrorMessage(e, 'Failed to fetch favorites.'),
      );
    }
  }

  @override
  Future<void> toggleFavorite(int productId) async {
    try {
      if (!await _tokenService.isLoggedIn()) {
        throw const FavoritesFailure(
          type: FavoritesFailureType.unauthorized,
          message: 'You must be logged in to manage favorites.',
        );
      }
      await _remoteDataSource.toggleFavorite(productId);
    } on FavoritesFailure {
      rethrow;
    } catch (e) {
      throw FavoritesFailure(
        type: FavoritesFailureType.network,
        message: _getErrorMessage(e, 'Failed to update favorite status.'),
      );
    }
  }

  String _getErrorMessage(dynamic e, String defaultMsg) {
    final s = e.toString().toLowerCase();
    
    if (s.contains('socketexception') ||
        s.contains('connection refused') ||
        s.contains('network is unreachable') ||
        s.contains('timed out') ||
        s.contains('timeout') ||
        s.contains('clientexception') ||
        s.contains('dioexception')) {
      return "Sorry, we are not available right now. Please try again later.";
    }

    if (s.contains('401') || s.contains('unauthorized')) {
      return "You must be logged in to manage favorites.";
    }

    final match = RegExp(r'"message"\s*:\s*"([^"]+)"').firstMatch(e.toString());
    if (match != null) {
      return match.group(1)!;
    }

    return defaultMsg;
  }
}

extension FavoriteModelMapper on FavoriteModel {
  FavoriteEntity toDomain() {
    return FavoriteEntity(
      id: id,
      productId: productId,
      price: price,
      name: name,
      weight: weight,
      createdAt: createdAt,
      image: image,
      productCategory: productCategory,
    );
  }
}
