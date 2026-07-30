import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:grocery_app/features/favorites/domain/failures/favorites_failure.dart';
import 'package:grocery_app/features/favorites/domain/repositories/favorites_repository.dart';
import 'package:grocery_app/features/favorites/domain/usecases/get_favorites_use_case.dart';
import 'package:grocery_app/features/favorites/domain/usecases/toggle_favorite_use_case.dart';
import 'package:grocery_app/features/favorites/presentation/cubit/favorites_cubit.dart';
import 'package:grocery_app/features/favorites/presentation/cubit/favorites_state.dart';
import 'package:grocery_app/features/favorites/domain/entities/favorite_entity.dart';

class MockFavoritesRepository extends Mock implements FavoritesRepository {}

void main() {
  late MockFavoritesRepository mockRepository;
  late FavoritesCubit favoritesCubit;
  late FavoriteEntity testFavorite;

  setUp(() {
    mockRepository = MockFavoritesRepository();
    testFavorite = FavoriteEntity(
      id: 1,
      productId: 101,
      price: '150.0',
      name: 'Item Name',
      weight: '500g',
      createdAt: DateTime.now(),
      image: 'img.png',
      productCategory: 'Category',
    );

    registerFallbackValue(101);
  });

  tearDown(() {
    favoritesCubit.close();
  });

  FavoritesCubit createCubit() {
    return FavoritesCubit(
      getFavoritesUseCase: GetFavoritesUseCase(mockRepository),
      toggleFavoriteUseCase: ToggleFavoriteUseCase(mockRepository),
    );
  }

  test('loadFavorites emits FavoritesLoading then FavoritesSuccess', () async {
    when(() => mockRepository.getFavorites()).thenAnswer((_) async => [testFavorite]);

    favoritesCubit = createCubit();
    final states = <FavoritesState>[];
    final subscription = favoritesCubit.stream.listen(states.add);

    await favoritesCubit.loadFavorites();
    await Future.delayed(Duration.zero);

    expect(states.length, 2);
    expect(states[0], isA<FavoritesLoading>());
    expect(states[1], isA<FavoritesSuccess>());
    expect((states[1] as FavoritesSuccess).favorites.length, 1);
    expect((states[1] as FavoritesSuccess).favoriteProductIds.contains(101), true);

    await subscription.cancel();
  });

  test('toggleFavorite performs optimistic update immediately and debounces backend sync', () async {
    // Initial state holds the favorite item
    when(() => mockRepository.getFavorites()).thenAnswer((_) async => [testFavorite]);
    when(() => mockRepository.toggleFavorite(any())).thenAnswer((_) async {});

    favoritesCubit = createCubit();
    await favoritesCubit.loadFavorites();
    await Future.delayed(Duration.zero);

    final states = <FavoritesState>[];
    final subscription = favoritesCubit.stream.listen(states.add);

    // Act: Toggle item 101 (which is currently in favorites, so it should be removed optimistically)
    favoritesCubit.toggleFavorite(101);
    await Future.delayed(Duration.zero);

    // Assert: Immediate optimistic update state emitted
    expect(states.length, 1);
    expect(states[0], isA<FavoritesSuccess>());
    final successState = states[0] as FavoritesSuccess;
    // Check it is optimistically removed
    expect(successState.favoriteProductIds.contains(101), false);

    // Backend should NOT be called yet (due to 500ms debounce)
    verifyNever(() => mockRepository.toggleFavorite(any()));

    // Wait for the 500ms debounce window to pass
    await Future.delayed(const Duration(milliseconds: 550));

    // Assert: Backend sync completed and repository toggle called exactly once
    verify(() => mockRepository.toggleFavorite(101)).called(1);

    await subscription.cancel();
  });

  test('rapid successive toggle calls on the same item resets debounce and triggers only one backend call', () async {
    when(() => mockRepository.getFavorites()).thenAnswer((_) async => [testFavorite]);
    when(() => mockRepository.toggleFavorite(any())).thenAnswer((_) async {});

    favoritesCubit = createCubit();
    await favoritesCubit.loadFavorites();
    await Future.delayed(Duration.zero);

    favoritesCubit.toggleFavorite(101); // Tap 1
    await Future.delayed(const Duration(milliseconds: 100));
    favoritesCubit.toggleFavorite(101); // Tap 2 (cancels Tap 1)
    await Future.delayed(const Duration(milliseconds: 100));
    favoritesCubit.toggleFavorite(101); // Tap 3 (cancels Tap 2)

    // Wait 300ms (total elapsed: 500ms since Tap 1, but only 300ms since Tap 3)
    await Future.delayed(const Duration(milliseconds: 300));
    verifyNever(() => mockRepository.toggleFavorite(any()));

    // Wait another 250ms to clear the 500ms debounce for Tap 3
    await Future.delayed(const Duration(milliseconds: 250));
    verify(() => mockRepository.toggleFavorite(101)).called(1);
  });
}
