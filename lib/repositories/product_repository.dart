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
      // Re-throw with a custom, user-friendly exception type
      throw ProductException('Could not fetch product categories. Please check your connection.');
    }
  }

  Future<List<Product>> fetchFeaturedProducts() async {
    try {
      return await CategoryService.fetchFeaturedProducts();
    } catch (e) {
      throw ProductException('Could not fetch featured products.');
    }
  }

  Future<List<Product>> fetchBestsellerProducts() async {
    try {
      return await CategoryService.fetchBestsellerProducts();
    } catch (e) {
      throw ProductException('Could not fetch bestseller products.');
    }
  }

  Future<List<Product>> fetchProductsByCategory(String categoryName) async {
    try {
      return await CategoryService.fetchProductsByCategory(categoryName);
    } catch (e) {
      throw ProductException('Could not fetch products for "$categoryName".');
    }
  }

  Future<Product> fetchProductById(int id) async {
    try {
      return await CategoryService.fetchProductById(id);
    } catch (e) {
      throw ProductException('Could not fetch product details.');
    }
  }
}