import 'package:dio/dio.dart';
import 'package:grocery_app/models/category_model.dart';
import 'package:grocery_app/models/product_model.dart';
import 'package:grocery_app/services/api_client.dart';

abstract class ProductsRemoteDataSource {
  Future<List<Category>> fetchCategories();
  Future<List<Product>> fetchFeaturedProducts();
  Future<List<Product>> fetchBestsellerProducts();
  Future<List<Product>> fetchProductsByCategory(String categoryName);
  Future<Product> fetchProductById(int id);
  Future<List<Product>> searchProducts(String query);
}

class ProductsRemoteDataSourceImpl implements ProductsRemoteDataSource {
  final ApiClient _apiClient;
  static const int timeoutSeconds = 30;

  const ProductsRemoteDataSourceImpl(this._apiClient);

  @override
  Future<List<Category>> fetchCategories() async {
    final response = await _apiClient.get(
      '/api/products/categories/',
      options: Options(
        sendTimeout: const Duration(seconds: timeoutSeconds),
        receiveTimeout: const Duration(seconds: timeoutSeconds),
      ),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = response.data;
      List<Category> categories = data.map((item) => Category.fromJson(item)).toList();

      // Fallback: Calculate true active products locally to ensure UI counts exactly match catalog items
      try {
        final products = await _fetchAllProducts();
        final categoryCounts = <String, int>{};
        for (var p in products) {
          if (p.isActive) {
            final catName = p.productCategory.toLowerCase();
            categoryCounts[catName] = (categoryCounts[catName] ?? 0) + 1;
          }
        }
        categories = categories.map((c) => Category(
          id: c.id,
          name: c.name,
          description: c.description,
          image: c.image,
          isActive: c.isActive,
          productsCount: categoryCounts[c.name.toLowerCase()] ?? 0,
        )).toList();
      } catch (_) {
        // If fetching all products fails, degrade gracefully to backend counts
      }

      return categories;
    } else {
      throw Exception('Failed to load categories');
    }
  }

  @override
  Future<List<Product>> fetchFeaturedProducts() async {
    final response = await _apiClient.get('/api/products/featured/');
    if (response.statusCode == 200) {
      final List<dynamic> data = response.data;
      return data.map((item) => Product.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load featured products');
    }
  }

  @override
  Future<List<Product>> fetchBestsellerProducts() async {
    final response = await _apiClient.get('/api/products/bestsellers/');
    if (response.statusCode == 200) {
      final List<dynamic> data = response.data;
      return data.map((item) => Product.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load bestseller products');
    }
  }

  @override
  Future<List<Product>> fetchProductsByCategory(String categoryName) async {
    final response = await _apiClient.get(
      '/api/products/variants/',
      queryParameters: {'category_name': categoryName},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = response.data;
      final products = data.map((item) => Product.fromJson(item)).toList();

      // Client-side filtering fallback: Ensure we only return products for the requested category
      return products
          .where(
            (p) => p.productCategory.toLowerCase() == categoryName.toLowerCase(),
          )
          .toList();
    } else {
      throw Exception('Failed to load products by category');
    }
  }

  @override
  Future<Product> fetchProductById(int id) async {
    final response = await _apiClient.get('/api/products/variants/$id');
    if (response.statusCode == 200) {
      return Product.fromJson(response.data);
    } else {
      throw Exception('Failed to load product');
    }
  }

  @override
  Future<List<Product>> searchProducts(String query) async {
    final response = await _apiClient.get(
      '/api/products/variants/search/',
      queryParameters: {'q': query},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = response.data;
      return data.map((item) => Product.fromJson(item)).toList();
    } else {
      return [];
    }
  }

  Future<List<Product>> _fetchAllProducts() async {
    final response = await _apiClient.get('/api/products/variants/');
    if (response.statusCode == 200) {
      final List<dynamic> data = response.data;
      return data.map((item) => Product.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load products');
    }
  }
}
