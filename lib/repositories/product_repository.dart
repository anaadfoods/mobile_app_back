import 'package:grocery_app/services/product_service.dart';

import '../models/category_model.dart';
import '../models/product_model.dart';

/// A custom exception for handling product/catalog related errors.
class ProductException implements Exception {
  final String message;
  ProductException(this.message);

  @override
  String toString() => message;
}

class ProductRepository {
  // In a real app, you might inject an instance of CategoryService.
  // Since it's static, we can call it directly for now.

  Future<List<Category>> fetchCategories() async {
    try {
      return await CategoryService.fetchCategories();
    } catch (e) {
      throw ProductException(
        _getErrorMessage(e, 'Could not fetch product categories.'),
      );
    }
  }

  Future<List<Product>> fetchFeaturedProducts() async {
    try {
      return await CategoryService.fetchFeaturedProducts();
    } catch (e) {
      throw ProductException(
        _getErrorMessage(e, 'Could not fetch featured products.'),
      );
    }
  }

  Future<List<Product>> fetchBestsellerProducts() async {
    try {
      return await CategoryService.fetchBestsellerProducts();
    } catch (e) {
      throw ProductException(
        _getErrorMessage(e, 'Could not fetch bestseller products.'),
      );
    }
  }

  Future<List<Product>> fetchProductsByCategory(String categoryName) async {
    try {
      return await CategoryService.fetchProductsByCategory(categoryName);
    } catch (e) {
      throw ProductException(
        _getErrorMessage(e, 'Could not fetch products for "$categoryName".'),
      );
    }
  }

  Future<Product> fetchProductById(int id) async {
    try {
      return await CategoryService.fetchProductById(id);
    } catch (e) {
      throw ProductException(
        _getErrorMessage(e, 'Could not fetch product details.'),
      );
    }
  }

  /// Returns user-friendly error message - no technical jargon!
  String _getErrorMessage(dynamic e, String defaultMsg) {
    final s = e.toString().toLowerCase();
    if (s.contains('socketexception') ||
        s.contains('connection refused') ||
        s.contains('network is unreachable') ||
        s.contains('timed out') ||
        s.contains('timeout') ||
        s.contains('clientexception')) {
      // Network issues - friendly message
      return "Couldn't connect right now. Check your internet! 📶\n\n🐄 Did you know? Indian Gir cows produce A2 milk, which is easier to digest!";
    }
    if (s.contains('500') || s.contains('server error') || s.contains('internal')) {
      return "Our servers need a moment. Try again shortly! ☕\n\n🌿 Panchagavya made from 5 cow products can replace chemical fertilizers entirely!";
    }
    if (s.contains('404') || s.contains('not found')) {
      return "Couldn't find what you're looking for 🔍\n\n🌾 Natural farming increases earthworm population by 10x in just one season!";
    }
    // Generic friendly message - hide technical details
    return "Something went sideways. Let's try again! 🔄\n\n🐄 Desi cow urine (Gomutra) is a powerful natural pesticide used for centuries!";
  }
}
