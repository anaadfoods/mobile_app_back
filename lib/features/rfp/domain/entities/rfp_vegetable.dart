/// A vegetable available in a farm patch.
class RfpVegetable {
  final String id;
  final String name;
  final String description;
  final String? iconName; // Material icon name for display
  final String season;
  final bool isDefaultSelected;
  final String? imageUrl;

  const RfpVegetable({
    required this.id,
    required this.name,
    required this.description,
    this.iconName,
    required this.season,
    this.isDefaultSelected = false,
    this.imageUrl,
  });
}
