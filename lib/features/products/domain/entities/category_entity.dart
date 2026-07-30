class CategoryEntity {
  final int id;
  final String name;
  final String description;
  final String image;
  final bool isActive;
  final int productsCount;

  const CategoryEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.image,
    required this.isActive,
    required this.productsCount,
  });
}
