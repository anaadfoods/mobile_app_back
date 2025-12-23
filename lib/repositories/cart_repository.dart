import '../models/cart_model.dart';
import '../services/cart_service.dart';

class CartException implements Exception {
  final String message;
  CartException(this.message);
}

class CartRepository {
  final CartService _service = CartService();

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

  /// Parses a cleaner error message from the exception string.
  String _parseError(dynamic e) {
    final text = e.toString();
    // This regex is good for extracting messages from your specific API errors
    final match = RegExp(r'"message"\s*:\s*"([^"]+)"').firstMatch(text);
    return match?.group(1) ?? text.replaceAll('Exception: ', '');
  }
}