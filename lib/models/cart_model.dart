import 'package:grocery_app/models/product_image_model.dart';
import 'package:grocery_app/models/product_model.dart';

class CartItem {
  final int id;
  final Product productVariant;
  int quantity;
  final String totalPrice;
  final DateTime createdAt;
  final DateTime updatedAt;

  CartItem({
    required this.id,
    required this.productVariant,
    required this.quantity,
    required this.totalPrice,
    required this.createdAt,
    required this.updatedAt,
  });

  // --- 👇 COPYWITH METHOD ADDED HERE ---
  /// Creates a copy of this CartItem but with the given fields replaced with the new values.
  CartItem copyWith({
    int? id,
    Product? productVariant,
    int? quantity,
    String? totalPrice,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CartItem(
      id: id ?? this.id,
      productVariant: productVariant ?? this.productVariant,
      quantity: quantity ?? this.quantity,
      totalPrice: totalPrice ?? this.totalPrice,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  // --- END OF ADDED METHOD ---

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      productVariant: Product.fromJson(json['product_variant']),
      quantity: json['quantity'],
      totalPrice: json['total_price'].toString(),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_variant': productVariant.toJson(),
      'quantity': quantity,
      'total_price': totalPrice,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class CartModel {
  final int id;
  final List<CartItem> items;
  final String totalPrice;
  int totalItems;
  final DateTime createdAt;
  final DateTime updatedAt;

  CartModel({
    required this.id,
    required this.items,
    required this.totalPrice,
    required this.totalItems,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CartModel.fromJson(Map<String, dynamic> json) {
    // Handle nested response structure
    var data = json;
    if (json.containsKey('status') && json['status'] == 'success') {
      data = json['data'];
      if (data.containsKey('status') && data['status'] == 'success') {
        data = data['data'];
      }
    }

    return CartModel(
      id: data['id'],
      items: (data['items'] as List)
          .map((item) => CartItem.fromJson(item))
          .toList(),
      totalPrice: data['total_price'].toString(),
      totalItems: data['total_items'],
      createdAt: DateTime.parse(data['created_at']),
      updatedAt: DateTime.parse(data['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'items': items.map((item) => item.toJson()).toList(),
      'total_price': totalPrice,
      'total_items': totalItems,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isEmpty => items.isEmpty;
}

class ProductVariant {
  final int id;
  final String sku;
  final String weight;
  final String weightUnit;
  final String price;
  final String discountPercentage;
  final String finalPrice;
  final bool isInStock;
  final bool isActive;
  final String productName;
  final String productDescription;
  final String productCategory;
  final List<ProductImage> productImages;

  ProductVariant({
    required this.id,
    required this.sku,
    required this.weight,
    required this.weightUnit,
    required this.price,
    required this.discountPercentage,
    required this.finalPrice,
    required this.isInStock,
    required this.isActive,
    required this.productName,
    required this.productDescription,
    required this.productCategory,
    required this.productImages,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id'],
      sku: json['sku'],
      weight: json['weight'],
      weightUnit: json['weight_unit'],
      price: json['price'],
      discountPercentage: json['discount_percentage'],
      finalPrice: json['final_price'],
      isInStock: json['is_in_stock'],
      isActive: json['is_active'],
      productName: json['product_name'],
      productDescription: json['product_description'],
      productCategory: json['product_category'],
      productImages: (json['product_images'] as List)
          .map((image) => ProductImage.fromJson(image))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sku': sku,
      'weight': weight,
      'weight_unit': weightUnit,
      'price': price,
      'discount_percentage': discountPercentage,
      'final_price': finalPrice,
      'is_in_stock': isInStock,
      'is_active': isActive,
      'product_name': productName,
      'product_description': productDescription,
      'product_category': productCategory,
      'product_images': productImages.map((image) => image.toJson()).toList(),
    };
  }
}