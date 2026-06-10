import 'package:grocery_app/common_widgets/global_import.dart';

import 'package:grocery_app/service_locator.dart';

class CartService {
  static final String baseUrl = ApiConfig.baseUrl;
  static const String getcartEndpoint = '/api/cart/details/';
  static const String cartEndpoint = '/api/cart/';
  static const String addCartItemEndpoint = '/api/cart/items/add/';
  static const String updateCartItemEndpoint = '/api/cart/items/update/';
  static const String removeItemEndpoint =
      'items/remove/'; // Relative to cartEndpoint
  static const String clearCartItemEndpoint =
      'clear/'; // Relative to cartEndpoint
  static const int timeoutSeconds = 60;

  final TokenService _tokenService = getIt<TokenService>();

  // Singleton instance
  static final CartService _instance = CartService._internal();
  factory CartService() => getIt<CartService>();
  CartService._internal();
  static CartService create() => CartService._internal();

  // The last successfully fetched cart, for synchronous access.
  static CartModel? lastKnownCart;

  // Stream controller for broadcasting cart state changes to listeners.
  static final _cartStateController = StreamController<CartModel>.broadcast();
  static Stream<CartModel> get cartStateChanges => _cartStateController.stream;

  /// Fetches the user's cart from the server.
  /// This is the SINGLE SOURCE OF TRUTH for the cart state.
  Future<CartModel> getCart() async {
    try {
      if (!await _tokenService.isLoggedIn()) {
        throw Exception('User not authenticated');
      }

      final response = await ApiClient.instance.get(getcartEndpoint);

      if (response.statusCode == 200) {
        final responseData = response.data;
        final cart = CartModel.fromJson(responseData);

        _cartStateController.add(cart);
        lastKnownCart = cart;

        return cart;
      } else {
        throw Exception('Failed to load cart. Status: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.instance.log('Error loading cart: $e');
      rethrow;
    }
  }

  /// Adds an item to the cart and then fetches the updated cart state.
  Future<CartModel> addToCart(int productId, int quantity) async {
    try {
      final response = await ApiClient.instance.post(
        addCartItemEndpoint,
        data: {
          'product_variant_id': productId,
          'quantity': quantity,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return await getCart();
      } else if (response.statusCode == 400) {
        final errorData = response.data;
        final message =
            errorData['message'] ??
            errorData['error'] ??
            'Item cannot be added. Check stock limits.';
        throw Exception(message);
      } else {
        throw Exception('Failed to add item. Status: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.instance.log('Error adding to cart: $e');
      rethrow;
    }
  }

  /// Updates an item's quantity and then fetches the updated cart state.
  Future<CartModel> updateCartItem(int productId, int quantity) async {
    try {
      final response = await ApiClient.instance.post(
        updateCartItemEndpoint,
        data: {
          'product_variant_id': productId,
          'quantity': quantity,
        },
      );

      if (response.statusCode == 200) {
        return await getCart();
      } else if (response.statusCode == 400) {
        final errorData = response.data;
        final message =
            errorData['message'] ??
            errorData['error'] ??
            'Only limited items left in stock';
        throw Exception(message);
      } else {
        throw Exception(
          'Failed to update item. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      AppLogger.instance.log('Error updating cart item: $e');
      rethrow;
    }
  }

  /// Removes an item from the cart and then fetches the updated cart state.
  Future<CartModel> removeFromCart(int productId) async {
    try {
      final response = await ApiClient.instance.post(
        '$cartEndpoint$removeItemEndpoint',
        data: {'product_variant_id': productId},
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return await getCart();
      } else {
        throw Exception(
          'Failed to remove item. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      AppLogger.instance.log('Error removing item from cart: $e');
      rethrow;
    }
  }

  /// Clears all items from the cart and then fetches the (now empty) cart state.
  Future<CartModel> clearCart() async {
    try {
      final response = await ApiClient.instance.post(
        '$cartEndpoint$clearCartItemEndpoint',
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return await getCart();
      } else {
        throw Exception('Failed to clear cart. Status: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.instance.log('Error clearing cart: $e');
      rethrow;
    }
  }

  // Dispose of the stream controller when the app is terminated.
  void dispose() {
    _cartStateController.close();
  }
}
