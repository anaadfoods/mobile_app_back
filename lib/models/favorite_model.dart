// lib/models/favorite_model.dart

class FavoriteModel {
  final int id;
  final String name;
  final String weight;
  final DateTime createdAt;

  FavoriteModel({
    required this.id,
    required this.name,
    required this.weight,
    required this.createdAt,
  });

  factory FavoriteModel.fromJson(Map<String, dynamic> json) {
    try {
      // Get the product data from the response
      final product = json['product'] as Map<String, dynamic>;

      return FavoriteModel(
        id: product['id'] as int,
        name: product['name'] as String,
        weight: product['weight'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
    } catch (e, stack) {
      print('Error parsing favorite model from JSON: $json');
      print('Error: $e');
      print('Stack trace: $stack');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': {'id': id, 'name': name, 'weight': weight},
      'created_at': createdAt.toIso8601String(),
    };
  }
}
