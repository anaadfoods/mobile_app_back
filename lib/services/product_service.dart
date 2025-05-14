import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:grocery_app/models/category_model.dart';
import 'package:grocery_app/models/product_model.dart';

class CategoryService {
  // static const String baseUrl = 'http://192.168.19.81:8000'; 

   static const String baseUrl = 'http://10.0.2.2:8000';

  static const String categoriesEndpoint = '/api/products/categories/';

  static const String baseProductsEndpoint= '/api/products/';
  static const String varientEndPoint = '/variants/by_category/';
  static  const String productsEndpoint = "/api/products/variants/by_category/";

  static const String featuredEndPoint = '/api/products/featured/';

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
static Future<List<Product>> fetchProductsByCategory(String categoryName) async {
  try{
    // final response = await http.get(Uri.parse('$baseUrl$productsEndpoint$varientEndPoint?by_category=$categoryName'));
    final String url = "$baseUrl$productsEndpoint?category_name=$categoryName";
    final response = await http.get(Uri.parse(url));
if(response.statusCode == 200){
  final List<dynamic> data = json.decode(response.body);
  return data.map((item)=> Product.fromJson((item))).toList();
}else{
  throw Exception("Failed to load products by category");
}
  
  }catch(e){
    throw Exception("Error loading products by category");
  }
}

  

  static Future<List<Product>> fetchFeaturedProducts() async {
    try {
      final response = await http.get(

        Uri.parse('$baseUrl$featuredEndPoint'),
      );

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
}
