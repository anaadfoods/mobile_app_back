import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grocery_app/models/product_model.dart';
import 'package:grocery_app/models/cart_model.dart';
import '../../domain/entities/cart_item_sync_status.dart';
import '../../domain/failures/cart_failure.dart';
import '../../domain/usecases/get_cart_use_case.dart';
import '../../domain/usecases/add_to_cart_use_case.dart';
import '../../domain/usecases/update_cart_item_use_case.dart';
import '../../domain/usecases/remove_from_cart_use_case.dart';
import '../../domain/usecases/clear_cart_use_case.dart';
import 'cart_state.dart';

class CartCubit extends Cubit<CartState> {
  final GetCartUseCase _getCartUseCase;
  final AddToCartUseCase _addToCartUseCase;
  final UpdateCartItemUseCase _updateCartItemUseCase;
  final RemoveFromCartUseCase _removeFromCartUseCase;
  final ClearCartUseCase _clearCartUseCase;

  final Map<int, _CartSyncController> _syncControllers = {};
  CartModel? _serverCart;

  CartCubit({
    required GetCartUseCase getCartUseCase,
    required AddToCartUseCase addToCartUseCase,
    required UpdateCartItemUseCase updateCartItemUseCase,
    required RemoveFromCartUseCase removeFromCartUseCase,
    required ClearCartUseCase clearCartUseCase,
  })  : _getCartUseCase = getCartUseCase,
        _addToCartUseCase = addToCartUseCase,
        _updateCartItemUseCase = updateCartItemUseCase,
        _removeFromCartUseCase = removeFromCartUseCase,
        _clearCartUseCase = clearCartUseCase,
        super(const CartInitial());

  /// Fetches the initial cart from the server.
  Future<void> loadCart() async {
    if (state is CartInitial) {
      emit(const CartLoading());
    }
    try {
      final cart = await _getCartUseCase();
      _serverCart = cart;
      _syncControllersWithCart(cart);
      _emitUpdatedCartState('', '');
    } on CartFailure catch (e) {
      emit(CartError(e.message));
    } catch (e) {
      emit(CartError(e.toString()));
    }
  }

  /// Adds a new item to the cart with an optimistic update.
  Future<void> addItem(Product product, int quantity) async {
    final currentState = state;
    if (currentState is! CartSuccess && currentState is! CartLoading) {
      await loadCart();
    }

    final id = product.id;
    final controller = _getOrCreateController(product, 0);
    controller.updateQuantity(controller.displayedQuantity + quantity);
  }

  /// Updates an item's quantity with an optimistic update.
  Future<void> updateItem(int variantId, int newQuantity) async {
    final currentState = state;
    if (currentState is! CartSuccess) {
      await loadCart();
    }

    final controller = _syncControllers[variantId];
    if (controller != null) {
      controller.updateQuantity(newQuantity);
    } else {
      final latestState = state;
      if (latestState is CartSuccess) {
        final item = latestState.cart.items.cast<CartItem?>().firstWhere(
              (i) => i?.productVariant.id == variantId,
              orElse: () => null,
            );
        if (item != null) {
          final newController = _getOrCreateController(item.productVariant, item.quantity);
          newController.updateQuantity(newQuantity);
        }
      }
    }
  }

  /// Removes an item from the cart with an optimistic update.
  Future<void> removeItem(int variantId) async {
    await updateItem(variantId, 0);
  }

  /// Clears the entire cart on the backend.
  Future<void> clearCart() async {
    final currentState = state;
    emit(const CartLoading());
    // Cancel all sync controllers
    for (final controller in _syncControllers.values) {
      controller.cancel();
    }
    _syncControllers.clear();

    try {
      final updatedCart = await _clearCartUseCase();
      _serverCart = updatedCart;
      emit(CartSuccess(updatedCart, message: 'Cart cleared.', error: ''));
    } on CartFailure catch (e) {
      if (currentState is CartSuccess) {
        _serverCart = currentState.cart;
        _syncControllersWithCart(currentState.cart);
        emit(CartSuccess(currentState.cart, message: e.message, error: ''));
      } else {
        emit(CartError(e.message));
      }
    } catch (e) {
      if (currentState is CartSuccess) {
        _serverCart = currentState.cart;
        _syncControllersWithCart(currentState.cart);
        emit(CartSuccess(currentState.cart, message: e.toString(), error: ''));
      } else {
        emit(CartError(e.toString()));
      }
    }
  }

  /// Clears the local cart state when user logs out
  void clearCartState() {
    for (final controller in _syncControllers.values) {
      controller.cancel();
    }
    _syncControllers.clear();
    _serverCart = null;
    emit(const CartInitial());
  }

  _CartSyncController _getOrCreateController(Product product, int initialQuantity) {
    final id = product.id;
    var controller = _syncControllers[id];
    if (controller == null) {
      controller = _CartSyncController(
        variantId: id,
        product: product,
        confirmedQuantity: initialQuantity,
        performApiCall: (qty) => _executeSyncApiCall(id, qty),
        onStateChanged: (msg, err) => _emitUpdatedCartState(msg, err),
      );
      _syncControllers[id] = controller;
    }
    return controller;
  }

  Future<CartModel> _executeSyncApiCall(int variantId, int qty) async {
    final updatedCart = await _getApiCallForVariant(variantId, qty);
    _serverCart = updatedCart;
    _syncControllersWithCart(updatedCart);
    return updatedCart;
  }

  Future<CartModel> _getApiCallForVariant(int variantId, int qty) {
    if (qty == 0) {
      return _removeFromCartUseCase(variantId);
    } else {
      final existsInServerCart = _serverCart?.items.any((item) => item.productVariant.id == variantId) ?? false;
      if (existsInServerCart) {
        return _updateCartItemUseCase(variantId, qty);
      } else {
        return _addToCartUseCase(variantId, qty);
      }
    }
  }

  void _syncControllersWithCart(CartModel cart) {
    for (final item in cart.items) {
      final id = item.productVariant.id;
      final controller = _syncControllers[id];
      if (controller == null) {
        _syncControllers[id] = _CartSyncController(
          variantId: id,
          product: item.productVariant,
          confirmedQuantity: item.quantity,
          performApiCall: (qty) => _executeSyncApiCall(id, qty),
          onStateChanged: (msg, err) => _emitUpdatedCartState(msg, err),
        );
      } else if (!controller.isSyncing) {
        controller.confirmedQuantity = item.quantity;
        controller.displayedQuantity = item.quantity;
        controller.pendingQuantity = item.quantity;
      }
    }

    final cartVariantIds = cart.items.map((i) => i.productVariant.id).toSet();
    _syncControllers.removeWhere((id, controller) {
      final keep = cartVariantIds.contains(id) || controller.isSyncing;
      if (!keep) {
        controller.cancel();
      }
      return !keep;
    });
  }

  void _emitUpdatedCartState([String? message, String? error]) {
    if (_serverCart == null && state is CartSuccess) {
      _serverCart = (state as CartSuccess).cart;
    }
    final baseCart = _serverCart;
    if (baseCart == null) return;

    final List<CartItem> updatedItems = [];
    final Map<int, CartItemSyncStatus> statuses = {};

    // First process items from the base cart
    for (final item in baseCart.items) {
      final controller = _syncControllers[item.productVariant.id];
      if (controller != null) {
        if (controller.displayedQuantity > 0) {
          updatedItems.add(item.copyWith(
            quantity: controller.displayedQuantity,
            totalPrice: (item.productVariant.finalPrice * controller.displayedQuantity).toString(),
          ));
        }
        statuses[item.productVariant.id] = CartItemSyncStatus(
          displayedQuantity: controller.displayedQuantity,
          confirmedQuantity: controller.confirmedQuantity,
          pendingQuantity: controller.pendingQuantity,
          isSyncing: controller.isSyncing,
          requestInFlight: controller.requestInFlight,
          error: controller.error,
        );
      } else {
        updatedItems.add(item);
      }
    }

    // Handle items not yet in base cart but are optimistically added or have active controllers
    _syncControllers.forEach((variantId, controller) {
      final existsInBase = baseCart.items.any((item) => item.productVariant.id == variantId);
      if (!existsInBase) {
        if (controller.displayedQuantity > 0 && controller.product != null) {
          updatedItems.add(
            CartItem(
              id: DateTime.now().millisecondsSinceEpoch,
              productVariant: controller.product!,
              quantity: controller.displayedQuantity,
              totalPrice: (controller.product!.finalPrice * controller.displayedQuantity).toString(),
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
        }
        if (controller.displayedQuantity > 0 || controller.isSyncing || controller.error != null) {
          statuses[variantId] = CartItemSyncStatus(
            displayedQuantity: controller.displayedQuantity,
            confirmedQuantity: controller.confirmedQuantity,
            pendingQuantity: controller.pendingQuantity,
            isSyncing: controller.isSyncing,
            requestInFlight: controller.requestInFlight,
            error: controller.error,
          );
        }
      }
    });

    final double newTotalPrice = updatedItems.fold(
      0.0,
      (sum, item) => sum + (item.productVariant.finalPrice * item.quantity),
    );
    final int newTotalItems = updatedItems.fold(0, (sum, item) => sum + item.quantity);

    final finalCart = baseCart.copyWith(
      items: updatedItems,
      totalPrice: newTotalPrice.toString(),
      totalItems: newTotalItems,
    );

    emit(CartSuccess(
      finalCart,
      message: message,
      error: error,
      itemStatuses: statuses,
    ));
  }

  @override
  Future<void> close() {
    for (final controller in _syncControllers.values) {
      controller.cancel();
    }
    return super.close();
  }
}

class _CartSyncController {
  final int variantId;
  final Product? product;
  final Future<CartModel> Function(int quantity) performApiCall;
  final void Function(String? message, String? error) onStateChanged;

  int displayedQuantity;
  int confirmedQuantity;
  int pendingQuantity;
  bool isSyncing = false;
  bool requestInFlight = false;
  String? error;

  int _lastSentVersion = 0;
  int _lastCompletedVersion = 0;
  Timer? _debounceTimer;

  _CartSyncController({
    required this.variantId,
    this.product,
    required this.confirmedQuantity,
    required this.performApiCall,
    required this.onStateChanged,
  })  : displayedQuantity = confirmedQuantity,
        pendingQuantity = confirmedQuantity;

  void updateQuantity(int newQuantity) {
    displayedQuantity = newQuantity;
    pendingQuantity = newQuantity;
    error = null;
    isSyncing = true;
    onStateChanged(null, null);

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _triggerSync();
    });
  }

  Future<void> _triggerSync() async {
    if (requestInFlight) return;

    if (pendingQuantity == confirmedQuantity) {
      isSyncing = false;
      onStateChanged(null, null);
      return;
    }

    requestInFlight = true;
    error = null;
    onStateChanged(null, null);

    final int version = ++_lastSentVersion;
    final int quantityToSync = pendingQuantity;

    try {
      await performApiCall(quantityToSync);

      if (version < _lastCompletedVersion) return;
      _lastCompletedVersion = version;

      confirmedQuantity = quantityToSync;
      requestInFlight = false;

      if (pendingQuantity != confirmedQuantity) {
        _triggerSync();
      } else {
        isSyncing = false;
        onStateChanged(quantityToSync == 0 ? 'Item removed from cart.' : 'Cart updated.', null);
      }
    } catch (e) {
      if (version < _lastCompletedVersion) return;
      _lastCompletedVersion = version;

      requestInFlight = false;
      if (e is CartFailure) {
        error = e.message;
      } else {
        error = "Sorry, we are not available right now. Please try again later.";
      }

      if (pendingQuantity == quantityToSync) {
        displayedQuantity = confirmedQuantity;
        pendingQuantity = confirmedQuantity;
        isSyncing = false;
      } else {
        _triggerSync();
      }
      onStateChanged(null, error);
    }
  }

  void cancel() {
    _debounceTimer?.cancel();
  }
}
