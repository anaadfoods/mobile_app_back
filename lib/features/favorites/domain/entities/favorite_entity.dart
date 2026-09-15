class FavoriteEntity {
  final int id;
  final int productId;
  final String price;
  final String name;
  final String weight;
  final DateTime createdAt;
  final String image;
  final String productCategory;

  const FavoriteEntity({
    required this.id,
    required this.productId,
    required this.price,
    required this.name,
    required this.weight,
    required this.createdAt,
    required this.image,
    required this.productCategory,
  });
}
