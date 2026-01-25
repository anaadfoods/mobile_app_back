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

  /// Returns user-friendly error message - no technical jargon!
  String _parseError(dynamic e) {
    final text = e.toString().toLowerCase();
    
    // Network/timeout issues - most common
    if (text.contains('timeout') ||
        text.contains('timed out') ||
        text.contains('socketexception') ||
        text.contains('connection refused') ||
        text.contains('network is unreachable') ||
        text.contains('clientexception')) {
      return "Couldn't connect right now. Check your internet! 📶\n\n🌿 Did you know? Desi cow dung has 300+ beneficial microbes that enrich soil naturally!";
    }
    
    // Server errors
    if (text.contains('500') || text.contains('server error') || text.contains('internal')) {
      return "Our servers need a moment. Try again shortly! ☕\n\n🐄 Fun fact: One desi cow can help fertilize up to 30 acres of farmland per year!";
    }
    
    // Auth issues
    if (text.contains('401') || text.contains('unauthorized') || text.contains('session')) {
      return "Please log in again to continue 🔐\n\n🌾 Natural farming uses zero chemicals - just cow-based inputs and love!";
    }
    
    // Try to extract API message if available
    final match = RegExp(r'"message"\s*:\s*"([^"]+)"').firstMatch(e.toString());
    if (match != null) {
      return match.group(1)!;
    }
    
    // Generic friendly fallback
    return "Something went sideways. Let's try again! 🔄\n\n🌱 Jeevamrutham, made from desi cow dung, boosts soil fertility within 48 hours!";
  }
}