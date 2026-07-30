import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:grocery_app/features/cart/data/datasources/cart_remote_data_source.dart';
import 'package:grocery_app/features/cart/data/repositories/cart_repository_impl.dart';
import 'package:grocery_app/features/cart/domain/failures/cart_failure.dart';
import 'package:grocery_app/models/cart_model.dart';

class MockCartRemoteDataSource extends Mock implements CartRemoteDataSource {}

void main() {
  late MockCartRemoteDataSource mockDataSource;
  late CartRepositoryImpl repository;
  late CartModel dummyCart;

  setUp(() {
    mockDataSource = MockCartRemoteDataSource();
    repository = CartRepositoryImpl(mockDataSource);
    dummyCart = CartModel(
      id: 1,
      items: const [],
      totalPrice: '0.0',
      totalItems: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  });

  test('getCart returns model from remote datasource', () async {
    when(() => mockDataSource.getCart()).thenAnswer((_) async => dummyCart);

    final result = await repository.getCart();

    expect(result, dummyCart);
    verify(() => mockDataSource.getCart()).called(1);
  });

  test('addToCart maps unauthorized response to CartFailureType.unauthorized', () async {
    when(() => mockDataSource.addToCart(101, 2))
        .thenThrow(Exception('DioException [bad response 401]: Unauthorized access token expired'));

    expect(
      () => repository.addToCart(101, 2),
      throwsA(
        isA<CartFailure>()
            .having((f) => f.type, 'type', CartFailureType.unauthorized)
            .having((f) => f.message, 'message', 'Please log in again to continue.'),
      ),
    );
  });

  test('updateCartItem maps timeout response to CartFailureType.network', () async {
    when(() => mockDataSource.updateCartItem(101, 5))
        .thenThrow(Exception('DioException [connection timeout]: request timed out'));

    expect(
      () => repository.updateCartItem(101, 5),
      throwsA(
        isA<CartFailure>()
            .having((f) => f.type, 'type', CartFailureType.network)
            .having((f) => f.message, 'message', 'Sorry, we are not available right now. Please try again later.'),
      ),
    );
  });

  test('removeFromCart maps JSON validation error to CartFailureType.validation', () async {
    when(() => mockDataSource.removeFromCart(101))
        .thenThrow(Exception('Exception: {"status":"error","message":"Out of stock limit"}'));

    expect(
      () => repository.removeFromCart(101),
      throwsA(
        isA<CartFailure>()
            .having((f) => f.type, 'type', CartFailureType.validation)
            .having((f) => f.message, 'message', 'Out of stock limit'),
      ),
    );
  });
}
