class ProductImageEntity {
  final String image;
  final String altText;

  const ProductImageEntity({
    required this.image,
    required this.altText,
  });
}

class ProductEntity {
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
  final List<ProductImageEntity> productImages;
  final String? cropCycleId;

  const ProductEntity({
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
    this.cropCycleId,
  });
}
