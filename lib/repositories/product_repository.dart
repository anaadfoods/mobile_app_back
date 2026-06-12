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

  /// Returns user-friendly error message
  String _getErrorMessage(dynamic e, String defaultMsg) {
    final s = e.toString().toLowerCase();
    
    if (s.contains('socketexception') ||
        s.contains('connection refused') ||
        s.contains('network is unreachable') ||
        s.contains('timed out') ||
        s.contains('timeout') ||
        s.contains('clientexception') ||
        s.contains('500') || 
        s.contains('502') || 
        s.contains('503') || 
        s.contains('server error') || 
        s.contains('internal') ||
        s.contains('dioexception')) {
      return "Sorry, we are not available right now. Please try again later.";
    }
    
    if (s.contains('404') || s.contains('not found')) {
      return "Couldn't find what you're looking for.";
    }
    
    // Try to extract API message if available
    final match = RegExp(r'"message"\s*:\s*"([^"]+)"').firstMatch(e.toString());
    if (match != null) {
      return match.group(1)!;
    }
    
    // Generic friendly message
    return "Sorry, we are not available right now. Please try again later.";
  }
}
