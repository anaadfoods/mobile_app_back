import 'package:grocery_app/models/cart_model.dart';
import 'package:grocery_app/models/product_image_model.dart';

class Product {
  final int id;
  final String sku;
  final String weight;
  final String weightUnit;
  final double price;
  final double discountPercentage;
  final double finalPrice;
  final bool isInStock;
  final bool isActive;
  final bool tag;
  final String productName;
  final String productDescription;
  final String productCategory;
  final List<ProductImage> productImages;

  Product({
    required this.id,
    required this.sku,
    required this.weight,
    required this.weightUnit,
    required this.price,
    required this.discountPercentage,
    required this.finalPrice,
    required this.isInStock,
    required this.isActive,
    required this.tag,
    required this.productName,
    required this.productDescription,
    required this.productCategory,
    required this.productImages,
  });

  // Convert Product to ProductVariant
  ProductVariant toProductVariant() {
    return ProductVariant(
      id: id,
      sku: sku,
      weight: weight,
      weightUnit: weightUnit,
      price: price.toString(),
      discountPercentage: discountPercentage.toString(),
      finalPrice: finalPrice.toString(),
      isInStock: isInStock,
      isActive: isActive,
      tag: tag,
      productName: productName,
      productDescription: productDescription,
      productCategory: productCategory,
      productImages: productImages,
    );
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      sku: json['sku'] ?? '',
      weight: json['weight'] ?? '',
      weightUnit: json['weight_unit'] ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      discountPercentage:
          double.tryParse(json['discount_percentage']?.toString() ?? '0') ?? 0,
      finalPrice: double.tryParse(json['final_price']?.toString() ?? '0') ?? 0,
      isInStock: json['is_in_stock'] ?? false,
      isActive: json['is_active'] ?? false,
      tag: json['tag'] ?? true,
      productName: json['product_name'] ?? '',
      productDescription: json['product_description'] ?? '',
      productCategory: json['product_category'] ?? '',
      productImages: (json['product_images'] as List<dynamic>?)
              ?.map((img) => ProductImage.fromJson(img))
              .toList() ??
          [],
    );
  }

  /// Converts the [Product] instance into a JSON map.
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
      'tag': tag,
      'product_name': productName,
      'product_description': productDescription,
      'product_category': productCategory,
      // This maps each ProductImage in the list to its JSON representation
      'product_images': productImages.map((image) => image.toJson()).toList(),
    };
  }
}
