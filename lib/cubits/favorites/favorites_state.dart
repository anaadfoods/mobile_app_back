import 'package:equatable/equatable.dart';
import '../../models/favorite_model.dart';

abstract class FavoritesState extends Equatable {
  const FavoritesState();
  @override
  List<Object> get props => [];
}

class FavoritesInitial extends FavoritesState {}

class FavoritesLoading extends FavoritesState {}

class FavoritesSuccess extends FavoritesState {
  final List<FavoriteModel> favorites;
  // A set of product IDs for efficient O(1) lookups in the UI
  final Set<int> favoriteProductIds;

  FavoritesSuccess(this.favorites)
      : favoriteProductIds = favorites.map((fav) => fav.productId).toSet();

  @override
  List<Object> get props => [favorites, favoriteProductIds];
}

class FavoritesError extends FavoritesState {
  final String message;
  const FavoritesError(this.message);
  @override
  List<Object> get props => [message];
}