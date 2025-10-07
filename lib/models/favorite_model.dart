// lib/models/favorite_model.dart

class FavoriteModel {
  /// The unique ID of the favorite entry itself.
  final int id;
  
  /// The unique ID of the associated product.
  final int productId;

  final String name;
  final String weight;
  final DateTime createdAt;
  
  /// The product image URL. Non-nullable, defaults to an empty string if not provided.
  final String image;

  FavoriteModel({
    required this.id,
    required this.productId,
    required this.name,
    required this.weight,
    required this.createdAt,
    required this.image,
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
        if (product['image'] is Map<String, dynamic> && product['image']['image'] is String) {
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

        // Use fallback values to prevent crashes if other data is missing.
        name: product['name'] ?? 'Unknown Product',
        weight: product['weight'] ?? '',
        image: imageUrl, // Use the safely parsed image URL.
        createdAt: DateTime.parse(json['created_at'] as String),
      );
    } catch (e, stack) {
      print('--- Error parsing FavoriteModel ---');
      print('JSON: $json');
      print('Error: $e');
      print('Stack trace: $stack');
      print('------------------------------------');
      // Rethrowing the error helps in debugging during development.
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': {'id': productId, 'name': name, 'weight': weight, 'image': image},
      'created_at': createdAt.toIso8601String(),
    };
  }
}