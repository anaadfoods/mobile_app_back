import 'package:equatable/equatable.dart';
import '../../domain/entities/favorite_entity.dart';
export '../../domain/entities/favorite_entity.dart';

abstract class FavoritesState extends Equatable {
  const FavoritesState();

  @override
  List<Object?> get props => [];
}

class FavoritesInitial extends FavoritesState {}

class FavoritesLoading extends FavoritesState {}

class FavoritesSuccess extends FavoritesState {
  final List<FavoriteEntity> favorites;
  final Set<int> favoriteProductIds;

  FavoritesSuccess(this.favorites)
      : favoriteProductIds = favorites.map((fav) => fav.productId).toSet();

  @override
  List<Object?> get props => [favorites, favoriteProductIds];
}

class FavoritesError extends FavoritesState {
  final String message;

  const FavoritesError(this.message);

  @override
  List<Object?> get props => [message];
}
