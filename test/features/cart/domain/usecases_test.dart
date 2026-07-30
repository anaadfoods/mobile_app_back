import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:grocery_app/features/cart/domain/repositories/cart_repository.dart';
import 'package:grocery_app/features/cart/domain/usecases/get_cart_use_case.dart';
import 'package:grocery_app/features/cart/domain/usecases/add_to_cart_use_case.dart';
import 'package:grocery_app/features/cart/domain/usecases/update_cart_item_use_case.dart';
import 'package:grocery_app/features/cart/domain/usecases/remove_from_cart_use_case.dart';
import 'package:grocery_app/features/cart/domain/usecases/clear_cart_use_case.dart';
import 'package:grocery_app/models/cart_model.dart';

class MockCartRepository extends Mock implements CartRepository {}

void main() {
  late MockCartRepository mockRepository;
  late CartModel dummyCart;

  setUp(() {
    mockRepository = MockCartRepository();
    dummyCart = CartModel(
      id: 1,
      items: const [],
      totalPrice: '0.0',
      totalItems: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  });

  test('GetCartUseCase calls getCart on repository', () async {
    when(() => mockRepository.getCart()).thenAnswer((_) async => dummyCart);
    final useCase = GetCartUseCase(mockRepository);

    final result = await useCase();

    expect(result, dummyCart);
    verify(() => mockRepository.getCart()).called(1);
  });

  test('AddToCartUseCase calls addToCart on repository', () async {
    when(() => mockRepository.addToCart(101, 3)).thenAnswer((_) async => dummyCart);
    final useCase = AddToCartUseCase(mockRepository);

    final result = await useCase(101, 3);

    expect(result, dummyCart);
    verify(() => mockRepository.addToCart(101, 3)).called(1);
  });

  test('UpdateCartItemUseCase calls updateCartItem on repository', () async {
    when(() => mockRepository.updateCartItem(101, 5)).thenAnswer((_) async => dummyCart);
    final useCase = UpdateCartItemUseCase(mockRepository);

    final result = await useCase(101, 5);

    expect(result, dummyCart);
    verify(() => mockRepository.updateCartItem(101, 5)).called(1);
  });

  test('RemoveFromCartUseCase calls removeFromCart on repository', () async {
    when(() => mockRepository.removeFromCart(101)).thenAnswer((_) async => dummyCart);
    final useCase = RemoveFromCartUseCase(mockRepository);

    final result = await useCase(101);

    expect(result, dummyCart);
    verify(() => mockRepository.removeFromCart(101)).called(1);
  });

  test('ClearCartUseCase calls clearCart on repository', () async {
    when(() => mockRepository.clearCart()).thenAnswer((_) async => dummyCart);
    final useCase = ClearCartUseCase(mockRepository);

    final result = await useCase();

    expect(result, dummyCart);
    verify(() => mockRepository.clearCart()).called(1);
  });
}
