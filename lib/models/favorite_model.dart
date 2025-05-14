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
      // Extract the data from the response structure
      final data = json['data'] as Map<String, dynamic>;

      // Get the product data
      final product = data['product'] as Map<String, dynamic>;

      return FavoriteModel(
        id: product['id'] as int,
        name: product['name'] as String,
        weight: product['weight'] as String,
        createdAt: DateTime.parse(data['created_at'] as String),
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
      'data': {
        'id': id,
        'product': {'name': name, 'weight': weight},
        'created_at': createdAt.toIso8601String(),
      },
    };
  }
}
