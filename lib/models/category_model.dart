import 'package:grocery_app/features/products/domain/entities/category_entity.dart';
import 'package:grocery_app/utils/app_logger.dart';

class Category {
  final int id;
  final String name;
  final String description;
  final String image;
  final bool isActive;
  final int productsCount;

  Category({
    required this.id,
    required this.name,
    required this.description,
    required this.image,
    required this.isActive,
    required this.productsCount,
  });

  factory Category.fromEntity(CategoryEntity entity) {
    return Category(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      image: entity.image,
      isActive: entity.isActive,
      productsCount: entity.productsCount,
    );
  }

  // Factory method to create a Category from JSON
  factory Category.fromJson(Map<String, dynamic> json) {
    try {
      return Category(
        id: json['id'] ?? 0,
        name: json['name'] ?? '',
        description: json['description'] ?? '',
        image: json['image'] ?? '',
        isActive: json['is_active'] ?? true,
        productsCount: json['products_count'] ?? 0,
      );
    } catch (e) {
      AppLogger.instance.log('Error parsing category: $e');
      AppLogger.instance.log('JSON data: $json');
      rethrow;
    }
  }

  // Convert Category to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image': image,
      'is_active': isActive,
      'products_count': productsCount,
    };
  }
}
