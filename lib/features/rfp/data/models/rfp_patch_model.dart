import '../../domain/entities/rfp_patch.dart';
import 'rfp_vegetable_model.dart';

class RfpPatchModel extends RfpPatch {
  const RfpPatchModel({
    required super.id,
    required super.label,
    required super.name,
    required super.vegetables,
    required super.maxExclusions,
    required super.availableWeights,
    required super.startingPrice,
    super.imageUrl,
  });

  factory RfpPatchModel.fromJson(Map<String, dynamic> json) {
    return RfpPatchModel(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? '',
      name: json['name'] as String? ?? '',
      vegetables:
          (json['vegetables'] as List<dynamic>?)
              ?.map(
                (e) => RfpVegetableModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      maxExclusions: json['max_exclusions'] as int? ?? 3,
      availableWeights:
          (json['available_weights'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          const [2.5, 5.0, 7.5],
      startingPrice: (json['starting_price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'name': name,
      'vegetables':
          vegetables
              .map((v) => RfpVegetableModel.fromEntity(v).toJson())
              .toList(),
      'max_exclusions': maxExclusions,
      'available_weights': availableWeights,
      'starting_price': startingPrice,
      'image_url': imageUrl,
    };
  }

  factory RfpPatchModel.fromEntity(RfpPatch entity) {
    return RfpPatchModel(
      id: entity.id,
      label: entity.label,
      name: entity.name,
      vegetables: entity.vegetables,
      maxExclusions: entity.maxExclusions,
      availableWeights: entity.availableWeights,
      startingPrice: entity.startingPrice,
      imageUrl: entity.imageUrl,
    );
  }
}
