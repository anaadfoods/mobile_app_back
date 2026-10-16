import '../../domain/entities/rfp_vegetable.dart';

class RfpVegetableModel extends RfpVegetable {
  const RfpVegetableModel({
    required super.id,
    required super.name,
    required super.description,
    super.iconName,
    required super.season,
    super.isDefaultSelected,
    super.imageUrl,
  });

  factory RfpVegetableModel.fromJson(Map<String, dynamic> json) {
    return RfpVegetableModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      description:
          json['description'] as String? ?? 'Farm-fresh organic harvest',
      iconName: json['icon_name'] as String? ?? 'eco',
      season: json['season'] as String? ?? 'All-season',
      isDefaultSelected: json['is_default_selected'] as bool? ?? false,
      imageUrl: json['image'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon_name': iconName,
      'season': season,
      'is_default_selected': isDefaultSelected,
      'image': imageUrl,
    };
  }

  factory RfpVegetableModel.fromEntity(RfpVegetable entity) {
    return RfpVegetableModel(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      iconName: entity.iconName,
      season: entity.season,
      isDefaultSelected: entity.isDefaultSelected,
      imageUrl: entity.imageUrl,
    );
  }
}
