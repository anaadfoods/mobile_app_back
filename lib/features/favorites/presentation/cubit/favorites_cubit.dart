import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/favorite_entity.dart';
import '../../domain/usecases/get_favorites_use_case.dart';
import '../../domain/usecases/toggle_favorite_use_case.dart';
import 'favorites_state.dart';

class FavoritesCubit extends Cubit<FavoritesState> {
  final GetFavoritesUseCase _getFavoritesUseCase;
  final ToggleFavoriteUseCase _toggleFavoriteUseCase;

  final Map<int, int> _favoriteToggleCounts = {};
  final Map<int, Timer> _favoriteDebouncers = {};

  FavoritesCubit({
    required GetFavoritesUseCase getFavoritesUseCase,
    required ToggleFavoriteUseCase toggleFavoriteUseCase,
  })  : _getFavoritesUseCase = getFavoritesUseCase,
        _toggleFavoriteUseCase = toggleFavoriteUseCase,
        super(FavoritesInitial());

  Future<void> loadFavorites() async {
    try {
      emit(FavoritesLoading());
      final favorites = await _getFavoritesUseCase();
      emit(FavoritesSuccess(favorites));
    } catch (e) {
      emit(FavoritesError(e.toString()));
    }
  }

  void toggleFavorite(int productId) {
    final currentState = state;
    if (currentState is! FavoritesSuccess) return;

    final existingFavorites = List<FavoriteEntity>.from(currentState.favorites);
    final isAlreadyFav = currentState.favoriteProductIds.contains(productId);

    // Optimistically update the list
    if (isAlreadyFav) {
      existingFavorites.removeWhere((fav) => fav.productId == productId);
    } else {
      existingFavorites.add(
        FavoriteEntity(
          id: -1,
          productId: productId,
          price: '',
          name: '',
          weight: '',
          createdAt: DateTime.now(),
          image: '',
          productCategory: '',
        ),
      );
    }

    // Emit optimistic success state immediately
    emit(FavoritesSuccess(existingFavorites));

    // Debounce the backend sync call by 500ms
    _favoriteToggleCounts[productId] = (_favoriteToggleCounts[productId] ?? 0) + 1;
    _favoriteDebouncers[productId]?.cancel();

    _favoriteDebouncers[productId] = Timer(
      const Duration(milliseconds: 500),
      () async {
        final tapCount = _favoriteToggleCounts[productId] ?? 0;
        _favoriteToggleCounts[productId] = 0; // Reset toggle count
        
        // If even number of taps, the net state returns to unchanged. Skip sync.
        if (tapCount % 2 == 0) return;

        try {
          await _toggleFavoriteUseCase(productId);
          // Load fresh from backend to sync actual IDs
          final freshFavorites = await _getFavoritesUseCase();
          emit(FavoritesSuccess(freshFavorites));
        } catch (e) {
          emit(FavoritesError(e.toString()));
          // Re-load to revert to original state
          await loadFavorites();
        }
      },
    );
  }

  void clearFavoritesState() {
    emit(FavoritesInitial());
  }

  @override
  Future<void> close() {
    for (final timer in _favoriteDebouncers.values) {
      timer.cancel();
    }
    return super.close();
  }
}
