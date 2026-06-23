// lib/models/favorite_model.dart

import 'package:grocery_app/utils/app_logger.dart';
import 'package:grocery_app/models/order_model.dart' show parseFlexibleDate;

class FavoriteModel {
  /// The unique ID of the favorite entry itself.
  final int id;

  /// The unique ID of the associated product.
  final int productId;
  final String price;
  final String name;
  final String weight;
  final DateTime createdAt;

  /// The product image URL. Non-nullable, defaults to an empty string if not provided.
  final String image;
  final String productCategory;

  FavoriteModel({
    required this.id,
    required this.productId,
    required this.price,
    required this.name,
    required this.weight,
    required this.createdAt,
    required this.image,
    required this.productCategory,
  });

  /// A robust factory constructor to parse JSON from the API.
  factory FavoriteModel.fromJson(Map<String, dynamic> json) {
    try {
      // Safely access the nested 'product' map. If it's null, use an empty map as a fallback.
      final product = json['product'] as Map<String, dynamic>? ?? {};

      String imageUrl = '';
      // **FIX 1: SAFELY PARSE THE IMAGE**
      // Check if the 'image' field inside 'product' is not null before accessing it.
      if (product['image'] != null) {
        // Your code implies the URL is nested one level deeper (e.g., image: {image: "url"})
        if (product['image'] is Map<String, dynamic> &&
            product['image']['image'] is String) {
          imageUrl = product['image']['image'];
        }
        // Add a fallback in case the API sometimes just sends a direct string.
        else if (product['image'] is String) {
          imageUrl = product['image'];
        }
      }

      return FavoriteModel(
        // **FIX 2: USE THE CORRECT ID**
        // The favorite's ID comes from the top-level 'id' key.
        id: json['id'] ?? 0,

        // Store the product's ID separately.
        productId: product['id'] ?? 0,
        price: product['price'] ?? "",

        // Use fallback values to prevent crashes if other data is missing.
        name: product['name'] ?? 'Unknown Product',
        weight: product['weight'] ?? '',
        image: imageUrl, // Use the safely parsed image URL.
        createdAt: parseFlexibleDate(json['created_at']?.toString()),
        productCategory: product['product_category'] ?? product['category'] ?? '',
      );
    } catch (e, stack) {
      AppLogger.instance.log('--- Error parsing FavoriteModel ---');
      AppLogger.instance.log('JSON: $json');
      AppLogger.instance.log('Error: $e');
      AppLogger.instance.log('Stack trace: $stack');
      AppLogger.instance.log('------------------------------------');
      // Rethrowing the error helps in debugging during development.
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': {
        'id': productId,
        'name': name,
        'weight': weight,
        'image': image,
        'price': price,
        'product_category': productCategory,
      },
      'created_at': createdAt.toIso8601String(),
    };
  }
}
