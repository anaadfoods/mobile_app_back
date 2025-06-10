import 'dart:convert';
import 'dart:async';
import 'api_config.dart';
import 'package:http/http.dart' as http;
import 'package:grocery_app/models/cart_model.dart';
import 'package:grocery_app/services/auth_service.dart';

class CartService {
  static final String baseUrl = ApiConfig.baseUrl;
  static const String getcartEndpoint = '/api/cart/details/';
  static const String cartEndpoint = '/api/cart/';

  static const String addCartItemEndpoint = '/api/cart/items/add/';
  static const String updateCartItemEndpoint = '/api/cart/items/update/';
  static const String clearCartItemEndpoint = 'clear/';
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
          .get(
            Uri.parse('$baseUrl$getcartEndpoint'),
            headers: await _getHeaders(),
          )
          .timeout(Duration(seconds: timeoutSeconds));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final cart = CartModel.fromJson(responseData);
        _cartStateController.add(cart);
        return cart;
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
      print('Error loading cart: $e');
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

      print('Adding to cart - Product ID: $productId, Quantity: $quantity');

      final headers = await _getHeaders();
      final body = {'product_variant_id': productId, 'quantity': quantity};

      final response = await http
          .post(
            Uri.parse('$baseUrl$addCartItemEndpoint'),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(Duration(seconds: timeoutSeconds));

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      // Handle both 200 and 201 as success
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);

        // Check if we need to get the updated cart
        if (responseData['status'] == 'success' &&
            !responseData.containsKey('items')) {
          // If the response doesn't contain the full cart, fetch it
          return await getCart();
        }

        final cart = CartModel.fromJson(responseData);
        _cartStateController.add(cart);
        return cart;
      } else if (response.statusCode == 401) {
        // Try to refresh the token
        final refreshed = await _authService.refreshAccessToken();
        if (refreshed) {
          // Retry with new token
          return addToCart(productId, quantity);
        } else {
          throw Exception('Authentication failed');
        }
      } else {
        final responseBody = response.body;
        try {
          final errorData = jsonDecode(responseBody);
          throw Exception(
            'Failed to add item to cart: ${errorData['message'] ?? responseBody}',
          );
        } catch (_) {
          throw Exception('Failed to add item to cart: $responseBody');
        }
      }
    } catch (e) {
      print('Error adding to cart: $e');
      if (e is TimeoutException) {
        throw Exception('Request timed out while adding item to cart');
      } else if (e is http.ClientException) {
        throw Exception(
          'Network error while adding item to cart: ${e.message}',
        );
      }
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

      final response = await http
          .post(
            Uri.parse('$baseUrl$updateCartItemEndpoint'),
            headers: await _getHeaders(),
            body: jsonEncode({
              'product_variant_id': cartItemId,
              'quantity': quantity,
            }),
          )
          .timeout(Duration(seconds: timeoutSeconds));

      if (response.statusCode == 200) {
        // Don't try to parse the response as CartModel, just fetch the latest cart
        return await getCart();
      } else if (response.statusCode == 401) {
        final refreshed = await _authService.refreshAccessToken();
        if (refreshed) {
          return updateCartItem(cartItemId, quantity);
        } else {
          throw Exception('Authentication failed');
        }
      } else {
        throw Exception('Failed to update cart item');
      }
    } catch (e) {
      throw Exception('Error updating cart item: $e');
    }
  }

  // Remove item from cart
  Future<void> removeFromCart(int cartItemId) async {
    const String removeItemEndpoint = 'items/remove/';
    try {
      final isAuthenticated = await _authService.isLoggedIn();
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      print('Removing item from cart - Item ID: $cartItemId');

      final headers = await _getHeaders();
      final body = {'product_variant_id': cartItemId};

      print('Request Body: $body');

      final response = await http
          .post(
            Uri.parse('$baseUrl$cartEndpoint$removeItemEndpoint'),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(Duration(seconds: timeoutSeconds));

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      // Handle both 200 and 204 as success
      if (response.statusCode == 200 || response.statusCode == 204) {
        try {
          if (response.body.isNotEmpty) {
            final responseData = jsonDecode(response.body);
            if (responseData['status'] == 'success') {
              // If we have cart data in the response, use it
              if (responseData.containsKey('data') &&
                  responseData['data'] != null) {
                final cart = CartModel.fromJson(responseData);
                _cartStateController.add(cart);
                return;
              }
            }
          }
          // If no cart data in response, fetch the updated cart
          final updatedCart = await getCart();
          _cartStateController.add(updatedCart);
        } catch (e) {
          print('Error parsing response: $e');
          // Still try to get the updated cart even if parsing fails
          final updatedCart = await getCart();
          _cartStateController.add(updatedCart);
        }
      } else if (response.statusCode == 401) {
        // Try to refresh the token
        final refreshed = await _authService.refreshAccessToken();
        if (refreshed) {
          // Retry with new token
          return removeFromCart(cartItemId);
        } else {
          throw Exception('Authentication failed');
        }
      } else {
        final responseBody = response.body;
        try {
          final errorData = jsonDecode(responseBody);
          throw Exception(
            'Failed to remove item from cart: ${errorData['message'] ?? responseBody}',
          );
        } catch (_) {
          throw Exception('Failed to remove item from cart: $responseBody');
        }
      }
    } catch (e) {
      print('Error removing item from cart: $e');
      if (e is TimeoutException) {
        throw Exception('Request timed out while removing item from cart');
      } else if (e is http.ClientException) {
        throw Exception(
          'Network error while removing item from cart: ${e.message}',
        );
      }
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

      final response = await http
          .post(
            Uri.parse('$baseUrl$cartEndpoint$clearCartItemEndpoint'),
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
      } else if (response.statusCode == 401) {
        // Try to refresh the token
        final refreshed = await _authService.refreshAccessToken();
        if (refreshed) {
          // Retry with new token
          return clearCart();
        } else {
          throw Exception('Authentication failed');
        }
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
