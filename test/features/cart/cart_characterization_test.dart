import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:grocery_app/features/cart/domain/entities/cart_item_sync_status.dart';
import 'package:grocery_app/features/cart/domain/failures/cart_failure.dart';
import 'package:grocery_app/features/cart/domain/repositories/cart_repository.dart';
import 'package:grocery_app/features/cart/domain/usecases/get_cart_use_case.dart';
import 'package:grocery_app/features/cart/domain/usecases/add_to_cart_use_case.dart';
import 'package:grocery_app/features/cart/domain/usecases/update_cart_item_use_case.dart';
import 'package:grocery_app/features/cart/domain/usecases/remove_from_cart_use_case.dart';
import 'package:grocery_app/features/cart/domain/usecases/clear_cart_use_case.dart';
import 'package:grocery_app/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:grocery_app/features/cart/presentation/cubit/cart_state.dart';
import 'package:grocery_app/models/cart_model.dart';
import 'package:grocery_app/models/product_model.dart';

class MockCartRepository extends Mock implements CartRepository {}

void main() {
  late MockCartRepository mockRepository;
  late CartCubit cartCubit;
  late Product testProduct;
  late CartModel initialCart;

  CartCubit createCubit() {
    return CartCubit(
      getCartUseCase: GetCartUseCase(mockRepository),
      addToCartUseCase: AddToCartUseCase(mockRepository),
      updateCartItemUseCase: UpdateCartItemUseCase(mockRepository),
      removeFromCartUseCase: RemoveFromCartUseCase(mockRepository),
      clearCartUseCase: ClearCartUseCase(mockRepository),
    );
  }

  setUp(() {
    mockRepository = MockCartRepository();
    testProduct = Product(
      id: 101,
      sku: 'TEST-SKU',
      weight: '1',
      weightUnit: 'kg',
      price: 100.0,
      discountPercentage: 0.0,
      finalPrice: 100.0,
      isInStock: true,
      isActive: true,
      productName: 'Test Product',
      productDescription: 'Description',
      productCategory: 'Category',
      productImages: const [],
    );

    initialCart = CartModel(
      id: 1,
      items: [],
      totalPrice: '0.0',
      totalItems: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Default mock response for getCart
    when(() => mockRepository.getCart()).thenAnswer((_) async => initialCart);
  });

  tearDown(() {
    cartCubit.close();
  });

  test('loadCart emits CartLoading then CartSuccess', () async {
    cartCubit = createCubit();
    final states = <CartState>[];
    final subscription = cartCubit.stream.listen(states.add);

    await cartCubit.loadCart();
    await Future.delayed(Duration.zero);

    expect(states.length, 2);
    expect(states[0], isA<CartLoading>());
    expect(states[1], isA<CartSuccess>());
    expect((states[1] as CartSuccess).cart.items.isEmpty, true);

    await subscription.cancel();
  });

  test('addItem immediately performs optimistic update and debounces sync API call', () async {
    // Return cart with the item added when backend is finally called
    final updatedCart = CartModel(
      id: 1,
      items: [
        CartItem(
          id: 12,
          productVariant: testProduct,
          quantity: 2,
          totalPrice: '200.0',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ],
      totalPrice: '200.0',
      totalItems: 2,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    when(() => mockRepository.addToCart(101, 2)).thenAnswer((_) async => updatedCart);

    cartCubit = createCubit();
    await cartCubit.loadCart();

    final states = <CartState>[];
    final subscription = cartCubit.stream.listen(states.add);

    // Perform the optimistic update add item
    await cartCubit.addItem(testProduct, 2);

    // Verify immediate optimistic success state (before debounce timer triggers API call)
    expect(states.isNotEmpty, true);
    final optimisticState = states.last as CartSuccess;
    expect(optimisticState.cart.totalItems, 2);
    expect(optimisticState.cart.totalPrice, '200.0');
    expect(optimisticState.itemStatuses[101]?.displayedQuantity, 2);
    expect(optimisticState.itemStatuses[101]?.isSyncing, true);
    expect(optimisticState.itemStatuses[101]?.requestInFlight, false);

    // Wait for the 300ms debounce timer + network sync call to complete
    await Future.delayed(const Duration(milliseconds: 400));

    // Verify repository call happened once
    verify(() => mockRepository.addToCart(101, 2)).called(1);

    // Verify final state matches the updated cart from server, with syncing = false
    final finalState = cartCubit.state as CartSuccess;
    expect(finalState.cart.totalItems, 2);
    expect(finalState.itemStatuses[101]?.isSyncing, false);
    expect(finalState.itemStatuses[101]?.requestInFlight, false);

    await subscription.cancel();
  });

  test('rapid quantity changes reset debounce timer and execute only the latest quantity sync', () async {
    final finalSyncCart = CartModel(
      id: 1,
      items: [
        CartItem(
          id: 12,
          productVariant: testProduct,
          quantity: 5,
          totalPrice: '500.0',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ],
      totalPrice: '500.0',
      totalItems: 5,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    when(() => mockRepository.addToCart(101, 5)).thenAnswer((_) async => finalSyncCart);

    cartCubit = createCubit();
    await cartCubit.loadCart();

    // Trigger rapid updates: quantity 2 -> 3 -> 5
    await cartCubit.addItem(testProduct, 2);
    await cartCubit.updateItem(101, 3);
    await cartCubit.updateItem(101, 5);

    // Verify optimistic value is immediately 5
    final optimisticState = cartCubit.state as CartSuccess;
    expect(optimisticState.cart.totalItems, 5);
    expect(optimisticState.itemStatuses[101]?.displayedQuantity, 5);
    expect(optimisticState.itemStatuses[101]?.isSyncing, true);

    // Wait a brief period (< 300ms) and confirm no API call is made yet
    await Future.delayed(const Duration(milliseconds: 150));
    verifyNever(() => mockRepository.addToCart(any(), any()));

    // Wait for the remainder of debounce + API sync to resolve
    await Future.delayed(const Duration(milliseconds: 250));

    // Confirm only the final quantity was sent to the repository
    verify(() => mockRepository.addToCart(101, 5)).called(1);
    verifyNever(() => mockRepository.addToCart(101, 2));
    verifyNever(() => mockRepository.updateCartItem(101, any()));

    final finalState = cartCubit.state as CartSuccess;
    expect(finalState.cart.totalItems, 5);
    expect(finalState.itemStatuses[101]?.isSyncing, false);
  });
}
