import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:http/http.dart' as http;

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

  final AuthService _authService = AuthService();

  // Singleton instance
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  // The last successfully fetched cart, for synchronous access.
  static CartModel? lastKnownCart;

  // Stream controller for broadcasting cart state changes to listeners.
  static final _cartStateController = StreamController<CartModel>.broadcast();
  static Stream<CartModel> get cartStateChanges => _cartStateController.stream;

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Fetches the user's cart from the server.
  /// This is the SINGLE SOURCE OF TRUTH for the cart state.
  Future<CartModel> getCart() async {
    try {
      if (!await _authService.isLoggedIn()) {
        throw Exception('User not authenticated');
      }

      final response = await http
          .get(
            Uri.parse('$baseUrl$getcartEndpoint'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: timeoutSeconds));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final cart = CartModel.fromJson(responseData);

        // --- KEY ---
        // ALWAYS update both the stream and the cache here.
        _cartStateController.add(cart);
        lastKnownCart = cart;

        return cart;
      } else if (response.statusCode == 401) {
        if (await _authService.refreshAccessToken()) {
          return getCart(); // Retry
        } else {
          throw Exception('Authentication failed');
        }
      } else {
        throw Exception('Failed to load cart. Status: ${response.statusCode}');
      }
    } catch (e) {
      log('Error loading cart: $e');
      rethrow; // Re-throw the original error to be handled by the UI
    }
  }

  /// Adds an item to the cart and then fetches the updated cart state.
  Future<CartModel> addToCart(int productId, int quantity) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl$addCartItemEndpoint'),
            headers: await _getHeaders(),
            body: jsonEncode({
              'product_variant_id': productId,
              'quantity': quantity,
            }),
          )
          .timeout(const Duration(seconds: timeoutSeconds));

      // On ANY success (200 or 201), fetch the latest cart state.
      if (response.statusCode == 200 || response.statusCode == 201) {
        return await getCart(); // CORRECT: Guarantees state is updated
      } else if (response.statusCode == 401) {
        if (await _authService.refreshAccessToken()) {
          return addToCart(productId, quantity); // Retry
        } else {
          throw Exception('Authentication failed');
        }
      } else if (response.statusCode == 400) {
        try {
          final errorData = jsonDecode(response.body);
          final message =
              errorData['message'] ??
              errorData['error'] ??
              'Item cannot be added. Check stock limits.';
          throw Exception(message);
        } catch (_) {
          throw Exception('Item cannot be added. Check stock limits.');
        }
      } else {
        throw Exception('Failed to add item. Status: ${response.statusCode}');
      }
    } catch (e) {
      log('Error adding to cart: $e');
      rethrow;
    }
  }

  /// Updates an item's quantity and then fetches the updated cart state.
  Future<CartModel> updateCartItem(int productId, int quantity) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl$updateCartItemEndpoint'),
            headers: await _getHeaders(),
            body: jsonEncode({
              'product_variant_id': productId,
              'quantity': quantity,
            }),
          )
          .timeout(const Duration(seconds: timeoutSeconds));

      if (response.statusCode == 200) {
        return await getCart(); // CORRECT: Guarantees state is updated
      } else if (response.statusCode == 401) {
        if (await _authService.refreshAccessToken()) {
          return updateCartItem(productId, quantity); // Retry
        } else {
          throw Exception('Authentication failed');
        }
      } else if (response.statusCode == 400) {
        // Try to parse specific error message from server
        try {
          final errorData = jsonDecode(response.body);
          final message =
              errorData['message'] ??
              errorData['error'] ??
              'Only limited items left in stock';
          throw Exception(message);
        } catch (_) {
          throw Exception('Only limited items left in stock');
        }
      } else {
        throw Exception(
          'Failed to update item. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      log('Error updating cart item: $e');
      rethrow;
    }
  }

  /// Removes an item from the cart and then fetches the updated cart state.
  Future<CartModel> removeFromCart(int productId) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl$cartEndpoint$removeItemEndpoint'),
            headers: await _getHeaders(),
            body: jsonEncode({'product_variant_id': productId}),
          )
          .timeout(const Duration(seconds: timeoutSeconds));

      // On ANY success (200 or 204 No Content), fetch the latest cart state.
      if (response.statusCode == 200 || response.statusCode == 204) {
        return await getCart(); // CORRECT: Guarantees state is updated
      } else if (response.statusCode == 401) {
        if (await _authService.refreshAccessToken()) {
          return removeFromCart(productId); // Retry
        } else {
          throw Exception('Authentication failed');
        }
      } else {
        throw Exception(
          'Failed to remove item. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      log('Error removing item from cart: $e');
      rethrow;
    }
  }

  /// Clears all items from the cart and then fetches the (now empty) cart state.
  Future<CartModel> clearCart() async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl$cartEndpoint$clearCartItemEndpoint'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: timeoutSeconds));

      if (response.statusCode == 200 || response.statusCode == 204) {
        return await getCart(); // CORRECT: Guarantees state is updated with empty cart
      } else if (response.statusCode == 401) {
        if (await _authService.refreshAccessToken()) {
          return clearCart(); // Retry
        } else {
          throw Exception('Authentication failed');
        }
      } else {
        throw Exception('Failed to clear cart. Status: ${response.statusCode}');
      }
    } catch (e) {
      log('Error clearing cart: $e');
      rethrow;
    }
  }

  // Dispose of the stream controller when the app is terminated.
  void dispose() {
    _cartStateController.close();
  }
}
