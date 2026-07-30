import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:grocery_app/features/favorites/domain/entities/favorite_entity.dart';
import 'package:grocery_app/features/favorites/domain/repositories/favorites_repository.dart';
import 'package:grocery_app/features/favorites/domain/usecases/get_favorites_use_case.dart';
import 'package:grocery_app/features/favorites/domain/usecases/toggle_favorite_use_case.dart';

class MockFavoritesRepository extends Mock implements FavoritesRepository {}

void main() {
  late MockFavoritesRepository mockRepository;
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
  });

  test('GetFavoritesUseCase calls getFavorites on repository', () async {
    when(() => mockRepository.getFavorites()).thenAnswer((_) async => [testFavorite]);
    final useCase = GetFavoritesUseCase(mockRepository);

    final result = await useCase();
    expect(result, [testFavorite]);
    verify(() => mockRepository.getFavorites()).called(1);
  });

  test('ToggleFavoriteUseCase calls toggleFavorite on repository', () async {
    when(() => mockRepository.toggleFavorite(101)).thenAnswer((_) async {});
    final useCase = ToggleFavoriteUseCase(mockRepository);

    await useCase(101);
    verify(() => mockRepository.toggleFavorite(101)).called(1);
  });
}
