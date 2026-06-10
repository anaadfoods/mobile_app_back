import 'package:dio/dio.dart';
import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:grocery_app/service_locator.dart';

class CategoryService {
  factory CategoryService() => getIt<CategoryService>();
  CategoryService.create();

  static const String categoriesEndpoint = '/api/products/categories/';
  static const String baseProductsEndpoint = '/api/products/';
  static const String varientEndPoint = '/variants/by_category/';
  static const String productsEndpoint = "/api/products/variants/";
  static const String featuredEndPoint = '/api/products/featured/';
  static const String bestsellersEndpoint = '/api/products/bestsellers/';
  static const int timeoutSeconds = 30;

  // Fetches all categories from the server
  static Future<List<Category>> fetchCategories() async {
    try {
      final response = await ApiClient.instance.get(
        categoriesEndpoint,
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
          final products = await fetchAllProducts();
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
    } catch (e) {
      throw Exception('Error loading categories: $e');
    }
  }

  // Tests the server connection before loading data
  static Future<bool> testConnection() async {
    try {
      AppLogger.instance.log('Testing connection to $categoriesEndpoint...');
      final response = await ApiClient.instance.get(
        categoriesEndpoint,
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );

      AppLogger.instance.log('HTTP test response status: ${response.statusCode}');
      AppLogger.instance.log('Response body: ${response.data}');
      return response.statusCode == 200;
    } catch (e) {
      AppLogger.instance.log('Connection test failed with error: $e');
      return false;
    }
  }

  static Future<Product> fetchProductById(int id) async {
    try {
      String varianturl = 'variants/';
      final response = await ApiClient.instance.get(
        '$baseProductsEndpoint$varianturl$id',
        options: Options(
          sendTimeout: const Duration(seconds: timeoutSeconds),
          receiveTimeout: const Duration(seconds: timeoutSeconds),
        ),
      );

      if (response.statusCode == 200) {
        return Product.fromJson(response.data);
      }
      throw Exception('Failed to load product');
    } catch (e) {
      throw Exception('Error loading product: $e');
    }
  }

  // Helper to sort products so isActive = true comes first
  static void _sortProductsByActive(List<Product> products) {
    products.sort((a, b) {
      if (a.isActive && !b.isActive) return -1;
      if (!a.isActive && b.isActive) return 1;
      return 0;
    });
  }

  /// Call API
  Future<List<Product>> searchProducts(String query) async {
    try {
      final response = await ApiClient.instance.get(
        '/api/products/variants/search/',
        queryParameters: {'q': query},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        List<Product> results =
            data.map((item) => Product.fromJson(item)).toList();
        _sortProductsByActive(results);
        return results;
      } else {
        return [];
      }
    } catch (e) {
      throw Exception("Error searching products: $e");
    }
  }

  static Future<List<Product>> fetchProductsByCategory(
    String categoryName,
  ) async {
    try {
      final response = await ApiClient.instance.get(
        productsEndpoint,
        queryParameters: {'category_name': categoryName},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final products = data.map((item) => Product.fromJson(item)).toList();

        // Client-side filtering fallback: Ensure we only return products for the requested category
        final filteredProducts =
            products
                .where(
                  (p) =>
                      p.productCategory.toLowerCase() ==
                      categoryName.toLowerCase(),
                )
                .toList();

        _sortProductsByActive(filteredProducts);
        return filteredProducts;
      } else {
        throw Exception("Failed to load products by category");
      }
    } catch (e) {
      throw Exception("Error loading products by category: $e");
    }
  }

  static Future<List<Product>> fetchSimilarProduct(String categoryName) async {
    try {
      final response = await ApiClient.instance.get(
        '/api/products/variants/search/',
        queryParameters: {'': categoryName},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final results = data.map((item) => Product.fromJson(item)).toList();
        _sortProductsByActive(results);
        return results;
      } else {
        throw Exception("Failed to load products by category");
      }
    } catch (e) {
      throw Exception("Error loading products by category: $e");
    }
  }

  static Future<List<Product>> fetchFeaturedProducts() async {
    try {
      final response = await ApiClient.instance.get(featuredEndPoint);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final results = data.map((item) => Product.fromJson(item)).toList();
        _sortProductsByActive(results);
        return results;
      } else {
        throw Exception('Failed to load featured products');
      }
    } catch (e) {
      throw Exception('Error loading featured products: $e');
    }
  }

  static Future<List<Product>> fetchAllProducts() async {
    try {
      final response = await ApiClient.instance.get(productsEndpoint);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final results = data.map((item) => Product.fromJson(item)).toList();
        _sortProductsByActive(results);
        return results;
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      throw Exception('Error loading products: $e');
    }
  }

  static Future<List<Product>> fetchBestsellerProducts() async {
    try {
      final response = await ApiClient.instance.get(bestsellersEndpoint);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final results = data.map((item) => Product.fromJson(item)).toList();
        _sortProductsByActive(results);
        return results;
      } else {
        throw Exception('Failed to load bestseller products');
      }
    } catch (e) {
      throw Exception('Error loading bestseller products: $e');
    }
  }
}
