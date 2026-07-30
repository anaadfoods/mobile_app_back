import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:grocery_app/features/favorites/data/datasources/favorites_remote_data_source.dart';
import 'package:grocery_app/features/favorites/data/repositories/favorites_repository_impl.dart';
import 'package:grocery_app/features/favorites/domain/failures/favorites_failure.dart';
import 'package:grocery_app/models/favorite_model.dart';
import 'package:grocery_app/services/token_service.dart';

class MockFavoritesRemoteDataSource extends Mock implements FavoritesRemoteDataSource {}
class MockTokenService extends Mock implements TokenService {}

void main() {
  late MockFavoritesRemoteDataSource mockRemoteDataSource;
  late MockTokenService mockTokenService;
  late FavoritesRepositoryImpl repository;
  late FavoriteModel testFavoriteDto;

  setUp(() {
    mockRemoteDataSource = MockFavoritesRemoteDataSource();
    mockTokenService = MockTokenService();
    repository = FavoritesRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      tokenService: mockTokenService,
    );

    testFavoriteDto = FavoriteModel(
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

  test('getFavorites throws unauthorized failure if not logged in', () async {
    when(() => mockTokenService.isLoggedIn()).thenAnswer((_) async => false);

    await expectLater(
      () => repository.getFavorites(),
      throwsA(isA<FavoritesFailure>().having((f) => f.type, 'type', FavoritesFailureType.unauthorized)),
    );
    verifyNever(() => mockRemoteDataSource.fetchFavorites());
  });

  test('getFavorites maps DTOs to entities on success', () async {
    when(() => mockTokenService.isLoggedIn()).thenAnswer((_) async => true);
    when(() => mockRemoteDataSource.fetchFavorites()).thenAnswer((_) async => [testFavoriteDto]);

    final result = await repository.getFavorites();
    expect(result.length, 1);
    expect(result[0].productId, 101);
    expect(result[0].id, 1);
  });

  test('toggleFavorite throws unauthorized failure if not logged in', () async {
    when(() => mockTokenService.isLoggedIn()).thenAnswer((_) async => false);

    await expectLater(
      () => repository.toggleFavorite(101),
      throwsA(isA<FavoritesFailure>().having((f) => f.type, 'type', FavoritesFailureType.unauthorized)),
    );
    verifyNever(() => mockRemoteDataSource.toggleFavorite(any()));
  });

  test('toggleFavorite calls remote datasource and maps network error on exception', () async {
    when(() => mockTokenService.isLoggedIn()).thenAnswer((_) async => true);
    when(() => mockRemoteDataSource.toggleFavorite(101)).thenThrow(Exception('DioException: Timeout'));

    await expectLater(
      () => repository.toggleFavorite(101),
      throwsA(isA<FavoritesFailure>().having((f) => f.type, 'type', FavoritesFailureType.network)),
    );
    verify(() => mockRemoteDataSource.toggleFavorite(101)).called(1);
  });
}
