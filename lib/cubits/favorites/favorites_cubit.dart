import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grocery_app/repositories/favorites_repository.dart';
import 'package:grocery_app/cubits/favorites/favorites_state.dart';

class FavoritesCubit extends Cubit<FavoritesState> {
  final FavoritesRepository _favoritesRepository;

  FavoritesCubit({required FavoritesRepository favoritesRepository})
      : _favoritesRepository = favoritesRepository,
        super(FavoritesInitial());

  Future<void> loadFavorites() async {
    try {
      emit(FavoritesLoading());
      final favorites = await _favoritesRepository.getFavorites();
      emit(FavoritesSuccess(favorites));
    } on FavoritesException catch (e) {
      emit(FavoritesError(e.message));
    } catch (e) {
      emit(const FavoritesError('An unexpected error occurred.'));
    }
  }

  Future<void> toggleFavorite(int productId) async {
    try {
      // We don't show a full-screen loader for a quick toggle action.
      // The UI can show a local indicator on the favorite button itself.
      await _favoritesRepository.toggleFavorite(productId);
      // After toggling, refresh the entire list to ensure consistency.
      await loadFavorites();
    } on FavoritesException catch (e) {
      emit(FavoritesError(e.message));
      // Re-load to revert the UI state if the toggle failed
      await loadFavorites();
    } catch (e) {
      emit(const FavoritesError('Failed to update favorite status.'));
    }
  }

  void clearFavoritesState() {
    emit(FavoritesInitial());
  }
}