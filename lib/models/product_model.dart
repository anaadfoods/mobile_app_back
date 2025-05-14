class ProductImage {
  final String image;
  final String altText;

  ProductImage({required this.image, required this.altText});

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      image: json['image'] ?? '',
      altText: json['alt_text'] ?? '',
    );
  }
}

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
    required this.productName,
    required this.productDescription,
    required this.productCategory,
    required this.productImages,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      sku: json['sku'] ?? '',
      weight: json['weight'] ?? '',
      weightUnit: json['weight_unit'] ?? '',
      price: double.tryParse(json['price'] ?? '0') ?? 0,
      discountPercentage:
          double.tryParse(json['discount_percentage'] ?? '0') ?? 0,
      finalPrice: double.tryParse(json['final_price'] ?? '0') ?? 0,
      isInStock: json['is_in_stock'] ?? false,
      isActive: json['is_active'] ?? false,
      productName: json['product_name'] ?? '',
      productDescription: json['product_description'] ?? '',
      productCategory: json['product_category'] ?? '',
      productImages:
          (json['product_images'] as List<dynamic>?)
              ?.map((img) => ProductImage.fromJson(img))
              .toList() ??
          [],
    );
  }
}
