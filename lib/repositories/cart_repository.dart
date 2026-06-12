import '../models/cart_model.dart';
import '../services/cart_service.dart';
import 'package:grocery_app/service_locator.dart';

class CartException implements Exception {
  final String message;
  CartException(this.message);
}


class CartRepository {
  final CartService _service;

  CartRepository({CartService? service}) : _service = service ?? getIt<CartService>();

  Future<CartModel> getCart() async {
    try {
      return await _service.getCart();
    } catch (e) {
      throw CartException(_parseError(e));
    }
  }

  Future<CartModel> addToCart(int productVariantId, int quantity) async {
    try {
      return await _service.addToCart(productVariantId, quantity);
    } catch (e) {
      throw CartException(_parseError(e));
    }
  }

  Future<CartModel> updateCartItem(int productVariantId, int quantity) async {
    try {
      // CORRECTED: Pass the product ID, not an abstract cart item ID
      return await _service.updateCartItem(productVariantId, quantity);
    } catch (e) {
      throw CartException(_parseError(e));
    }
  }

  Future<CartModel> removeFromCart(int productVariantId) async {
    try {
      // CORRECTED: No more double fetching.
      // The service method now returns the updated CartModel directly.
      return await _service.removeFromCart(productVariantId);
    } catch (e) {
      throw CartException(_parseError(e));
    }
  }

  Future<CartModel> clearCart() async {
    try {
      // CORRECTED: No more double fetching.
      return await _service.clearCart();
    } catch (e) {
      throw CartException(_parseError(e));
    }
  }

  /// Returns user-friendly error message
  String _parseError(dynamic e) {
    final text = e.toString().toLowerCase();
    
    // Network, timeout, and server issues
    if (text.contains('timeout') ||
        text.contains('timed out') ||
        text.contains('socketexception') ||
        text.contains('connection refused') ||
        text.contains('network is unreachable') ||
        text.contains('clientexception') ||
        text.contains('500') || 
        text.contains('502') || 
        text.contains('503') || 
        text.contains('server error') || 
        text.contains('internal') ||
        text.contains('dioexception')) {
      return "Sorry, we are not available right now. Please try again later.";
    }
    
    // Auth issues
    if (text.contains('401') || text.contains('unauthorized') || text.contains('session')) {
      return "Please log in again to continue.";
    }
    
    // Try to extract API message if available
    final match = RegExp(r'"message"\s*:\s*"([^"]+)"').firstMatch(e.toString());
    if (match != null) {
      return match.group(1)!;
    }
    
    // Generic friendly fallback
    return "Sorry, we are not available right now. Please try again later.";
  }
}