import 'package:grocery_app/common_widgets/global_import.dart';

import 'package:http/http.dart' as http;

class CategoryService {
  // static const String baseUrl = 'http://192.168.1.40:8000';
  // static const String baseUrl = 'http://192.168.19.81:8000';
  static final String baseUrl = ApiConfig.baseUrl;

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
      final response = await http
          .get(Uri.parse('$baseUrl$categoriesEndpoint'))
          .timeout(Duration(seconds: timeoutSeconds));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => Category.fromJson(item)).toList();
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
      print('Testing connection to $baseUrl$categoriesEndpoint...');
      final response = await http
          .get(Uri.parse('$baseUrl$categoriesEndpoint'))
          .timeout(Duration(seconds: 5));

      print('HTTP test response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      print('Connection test failed with error: $e');
      return false;
    }
  }

  static Future<Product> fetchProductById(int id) async {
    try {
      String varianturl = 'variants/';
      final response = await http
          .get(Uri.parse('$baseUrl$baseProductsEndpoint$varianturl$id'))
          .timeout(Duration(seconds: timeoutSeconds));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Product.fromJson(data);
      }
      throw Exception('Failed to load product');
    } catch (e) {
      throw Exception('Error loading product: $e');
    }
  }

  /// Call API
  Future<List<Product>> searchProducts(String query) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/api/products/variants/search/?q=$query',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        List<Product> results =
            data.map((item) => Product.fromJson(item)).toList();
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
      final String url =
          "$baseUrl$productsEndpoint?category_name=$categoryName";
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final products = data.map((item) => Product.fromJson(item)).toList();

        // Client-side filtering fallback: Ensure we only return products for the requested category
        return products
            .where(
              (p) =>
                  p.productCategory.toLowerCase() == categoryName.toLowerCase(),
            )
            .toList();
      } else {
        throw Exception("Failed to load products by category");
      }
    } catch (e) {
      throw Exception("Error loading products by category: $e");
    }
  }

  static Future<List<Product>> fetchSimilarProduct(String categoryName) async {
    try {
      final String url =
          "$baseUrl/api/products/variants/search/?=$categoryName";
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => Product.fromJson(item)).toList();
      } else {
        throw Exception("Failed to load products by category");
      }
    } catch (e) {
      throw Exception("Error loading products by category: $e");
    }
  }

  static Future<List<Product>> fetchFeaturedProducts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl$featuredEndPoint'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => Product.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load featured products');
      }
    } catch (e) {
      throw Exception('Error loading featured products: $e');
    }
  }

  static Future<List<Product>> fetchAllProducts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl$productsEndpoint'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => Product.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      throw Exception('Error loading products: $e');
    }
  }

  static Future<List<Product>> fetchBestsellerProducts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$bestsellersEndpoint'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => Product.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load bestseller products');
      }
    } catch (e) {
      throw Exception('Error loading bestseller products: $e');
    }
  }
}
