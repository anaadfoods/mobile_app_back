import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:grocery_app/models/cart_model.dart';
import 'package:grocery_app/services/auth_service.dart';

class CartService {
  static const String baseUrl = 'http://10.0.2.2:8000';
  static const String cartEndpoint = '/api/cart/';
  static const int timeoutSeconds = 30;

  final AuthService _authService = AuthService();

  // Singleton instance
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  // Stream controller for cart state changes
  static final _cartStateController = StreamController<CartModel>.broadcast();
  static Stream<CartModel> get cartStateChanges => _cartStateController.stream;

  // Helper method to get headers

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Get cart items
  Future<CartModel> getCart() async {
    try {
      final isAuthenticated = await _authService.isLoggedIn();
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      final response = await http
          .get(Uri.parse('$baseUrl$cartEndpoint'), headers: await _getHeaders())
          .timeout(Duration(seconds: timeoutSeconds));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // If response is a list, convert it to the expected format
        if (responseData is List) {
          // final cartData = {
          //   'id': DateTime.now().toString(), // Generate a temporary ID
          //   'items': responseData,
          //   'created_at': DateTime.now().toIso8601String(),
          //   'updated_at': DateTime.now().toIso8601String(),
          // };
          final cart = CartModel.fromJson(responseData[0]);
          _cartStateController.add(cart);
          return cart;
        } else if (responseData is Map<String, dynamic>) {
          // If response is already in the correct format
          final cart = CartModel.fromJson(responseData);
          _cartStateController.add(cart);
          return cart;
        } else {
          throw Exception('Invalid response format from server');
        }
      } else if (response.statusCode == 401) {
        // Try to refresh the token
        final refreshed = await _authService.refreshAccessToken();
        if (refreshed) {
          // Retry with new token
          return getCart();
        } else {
          throw Exception('Authentication failed');
        }
      } else {
        throw Exception('Failed to load cart');
      }
    } catch (e) {
      print('Error loading cart: $e'); // Add this for debugging
      throw Exception('Error loading cart: $e');
    }
  }

  // Add item to cart
  Future<CartModel> addToCart(int productId, int quantity) async {
    try {
      final isAuthenticated = await _authService.isLoggedIn();
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      // Get fresh token
      final token = await _authService.getAccessToken();
      if (token == null) {
        throw Exception('Authentication failed');
      }

      final response = await http
          .post(
            Uri.parse('$baseUrl$cartEndpoint'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'product_id': productId, 'quantity': quantity}),
          )
          .timeout(Duration(seconds: timeoutSeconds));

      if (response.statusCode == 401) {
        // Token might be expired, try to refresh
        final refreshed = await _authService.refreshAccessToken();
        if (refreshed) {
          // Retry with new token
          final newToken = await _authService.getAccessToken();
          final retryResponse = await http
              .post(
                Uri.parse('$baseUrl$cartEndpoint'),
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                  'Authorization': 'Bearer $newToken',
                },
                body: jsonEncode({
                  'product_id': productId,
                  'quantity': quantity,
                }),
              )
              .timeout(Duration(seconds: timeoutSeconds));

          if (retryResponse.statusCode == 201) {
            final cartData = CartModel.fromJson(jsonDecode(retryResponse.body));
            _cartStateController.add(cartData);
            return cartData;
          }
        }
        throw Exception('Authentication failed');
      }

      if (response.statusCode == 201) {
        final cartData = CartModel.fromJson(jsonDecode(response.body));
        _cartStateController.add(cartData);
        return cartData;
      } else {
        throw Exception('Failed to add item to cart');
      }
    } catch (e) {
      print('Error adding to cart: $e');
      throw Exception('Error adding item to cart: $e');
    }
  }

  // Update cart item quantity
  Future<CartModel> updateCartItem(int cartItemId, int quantity) async {
    try {
      final isAuthenticated = await _authService.isLoggedIn();
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      final tokenValid = await _authService.refreshAccessToken();
      if (!tokenValid) {
        throw Exception('Authentication failed');
      }

      final response = await http
          .put(
            Uri.parse('$baseUrl$cartEndpoint$cartItemId/'),
            headers: await _getHeaders(),
            body: jsonEncode({'quantity': quantity}),
          )
          .timeout(Duration(seconds: timeoutSeconds));

      if (response.statusCode == 200) {
        final cartData = CartModel.fromJson(jsonDecode(response.body));
        _cartStateController.add(cartData);
        return cartData;
      } else {
        throw Exception('Failed to update cart item');
      }
    } catch (e) {
      throw Exception('Error updating cart item: $e');
    }
  }

  // Remove item from cart
  Future<void> removeFromCart(int cartItemId) async {
    try {
      final isAuthenticated = await _authService.isLoggedIn();
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      final tokenValid = await _authService.refreshAccessToken();
      if (!tokenValid) {
        throw Exception('Authentication failed');
      }
      final String url = 'items/remove/';
      final response = await http
          .post(
            Uri.parse('$baseUrl$cartEndpoint$url'),
            headers: await _getHeaders(),
            body: jsonEncode({'product_varient_id': cartItemId}),
          )
          .timeout(Duration(seconds: timeoutSeconds));

      if (response.statusCode == 204) {
        // Refresh cart after removal
        final updatedCart = await getCart();
        _cartStateController.add(updatedCart);
      } else {
        throw Exception('Failed to remove item from cart');
      }
    } catch (e) {
      throw Exception('Error removing item from cart: $e');
    }
  }

  // Clear cart
  Future<void> clearCart() async {
    try {
      final isAuthenticated = await _authService.isLoggedIn();
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      final tokenValid = await _authService.refreshAccessToken();
      if (!tokenValid) {
        throw Exception('Authentication failed');
      }

      final response = await http
          .delete(
            Uri.parse('$baseUrl$cartEndpoint'),
            headers: await _getHeaders(),
          )
          .timeout(Duration(seconds: timeoutSeconds));

      if (response.statusCode == 204) {
        // Create empty cart model
        final emptyCart = CartModel(
          id: 0,
          items: [],
          totalPrice: '0',
          totalItems: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        _cartStateController.add(emptyCart);
      } else {
        throw Exception('Failed to clear cart');
      }
    } catch (e) {
      throw Exception('Error clearing cart: $e');
    }
  }

  // Dispose of the stream controller
  void dispose() {
    _cartStateController.close();
  }
}
