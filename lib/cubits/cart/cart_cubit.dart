import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grocery_app/models/product_model.dart'; // Ensure you have this import
import 'package:grocery_app/models/cart_model.dart';
import 'package:grocery_app/repositories/cart_repository.dart';
import 'package:grocery_app/cubits/cart/cart_state.dart';
// Helpful for firstWhereOrNull

class CartCubit extends Cubit<CartState> {
  final CartRepository _repo;

  CartCubit(this._repo) : super(const CartInitial());

  /// Fetches the initial cart from the server.
  Future<void> loadCart() async {
    // Only show full-screen loading on the initial load.
    if (state is CartInitial) {
      emit(const CartLoading());
    }
    try {
      final cart = await _repo.getCart();
      emit(CartSuccess(cart, message: '', error: ''));
    } on CartException catch (e) {
      emit(CartError(e.message));
    }
  }

  /// Adds a new item to the cart with an optimistic update.
  /// ✅ CHANGED: Now accepts the full Product object.
  Future<void> addItem(Product product, int quantity) async {
    await _optimisticUpdate(
      product: product,
      quantityChange: quantity,
      operation: () => _repo.addToCart(product.id, quantity),
      successMessage: '${product.productName} added to cart.',
    );
  }

  /// Updates an item's quantity with an optimistic update.
  Future<void> updateItem(int variantId, int newQuantity) async {
    await _optimisticUpdate(
      variantId: variantId,
      newQuantity: newQuantity,
      operation: () => _repo.updateCartItem(variantId, newQuantity),
      successMessage: 'Cart updated.',
    );
  }

  /// Removes an item from the cart with an optimistic update.
  Future<void> removeItem(int variantId) async {
    await _optimisticUpdate(
      variantId: variantId,
      newQuantity: 0, // Setting quantity to 0 removes the item
      operation: () => _repo.removeFromCart(variantId),
      successMessage: 'Item removed from cart.',
    );
  }

  /// Clears the entire cart. A full load is appropriate here.
  Future<void> clearCart() async {
    final currentState = state;
    emit(const CartLoading()); // Show loader for this major action
    try {
      final updatedCart = await _repo.clearCart();
      emit(CartSuccess(updatedCart, message: 'Cart cleared.', error: ''));
    } on CartException catch (e) {
      // On failure, roll back to the previous state with an error message
      if (currentState is CartSuccess) {
        emit(CartSuccess(currentState.cart, message: e.message, error: ''));
      } else {
        emit(CartError(e.message));
      }
    }
  }

  /// A generic handler for optimistic updates to reduce code duplication.
  Future<void> _optimisticUpdate({
    required Future<CartModel> Function() operation,
    required String successMessage,
    int? variantId,
    Product? product,
    int? quantityChange,
    int? newQuantity,
  }) async {
    final currentState = state;
    if (currentState is! CartSuccess) {
      // If the cart isn't loaded, perform a standard load.
      await loadCart();
      return;
    }

    // 1. Create the optimistic (fake) state immediately
    final optimisticCart = _createOptimisticCart(
      currentState.cart,
      variantId: variantId ?? product?.id,
      product: product,
      quantityChange: quantityChange,
      newQuantity: newQuantity,
    );
    emit(CartSuccess(optimisticCart, message: '', error: '')); // Emit the optimistic state to the UI

    // 2. Perform the actual network call
    try {
      final realCart = await operation();
      // 3. On success, emit the true state from the server
      emit(CartSuccess(realCart, message: successMessage, error: ''));
    } on CartException catch (e) {
      // 4. On failure, roll back to the previous state and show an error
      emit(CartSuccess(currentState.cart, error: e.message));
    }
  }

  /// Creates a temporary local CartModel for the optimistic update.
  CartModel _createOptimisticCart(
    CartModel currentCart, {
    int? variantId,
    Product? product,
    int? quantityChange,
    int? newQuantity,
  }) {
    final items = List<CartItem>.from(currentCart.items);
    final index = items.indexWhere((item) => item.productVariant.id == variantId);

    if (index != -1) {
      // Item exists, update or remove it
      final existingItem = items[index];
      final calculatedQuantity = newQuantity ?? (existingItem.quantity + (quantityChange ?? 0));

      if (calculatedQuantity > 0) {
        items[index] = existingItem.copyWith(quantity: calculatedQuantity);
      } else {
        items.removeAt(index); // Remove if quantity is 0 or less
      }
    } else if (product != null && quantityChange != null && quantityChange > 0) {
      // Item does not exist, ADD IT using the correct product data
      // This creates a temporary CartItem. The ID will be replaced by the server's response.
      items.add(CartItem(
        id: DateTime.now().millisecondsSinceEpoch, // Temporary local ID
        productVariant: product, // ✅ CORRECT: Use the real product data
        quantity: quantityChange,
        totalPrice: (product.finalPrice * quantityChange).toString(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
    }
    
    // Recalculate totals locally for the optimistic view
    final double newTotalPrice = items.fold(0.0, (sum, item) => sum + (item.productVariant.finalPrice * item.quantity));
    final int newTotalItems = items.fold(0, (sum, item) => sum + item.quantity);

    return currentCart.copyWith(
      items: items,
      totalPrice: newTotalPrice.toString(),
      totalItems: newTotalItems,
    );
  }
}