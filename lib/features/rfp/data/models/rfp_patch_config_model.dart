import '../../domain/entities/rfp_patch_config.dart';

class RfpPatchConfigModel extends RfpPatchConfig {
  const RfpPatchConfigModel({
    required super.patchId,
    required super.patchLabel,
    required super.excludedVegetableIds,
    required super.selectedWeight,
    required super.deliveryFrequency,
  });

  factory RfpPatchConfigModel.fromJson(Map<String, dynamic> json) {
    return RfpPatchConfigModel(
      patchId: json['patch_id'] as String? ?? '',
      patchLabel: json['patch_label'] as String? ?? '',
      excludedVegetableIds:
          (json['excluded_vegetable_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      selectedWeight: (json['selected_weight'] as num?)?.toDouble() ?? 5.0,
      deliveryFrequency: json['delivery_frequency'] as String? ?? 'once_a_week',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patch_id': patchId,
      'patch_label': patchLabel,
      'excluded_vegetable_ids': excludedVegetableIds,
      'selected_weight': selectedWeight,
      'delivery_frequency': deliveryFrequency,
    };
  }

  factory RfpPatchConfigModel.fromEntity(RfpPatchConfig entity) {
    return RfpPatchConfigModel(
      patchId: entity.patchId,
      patchLabel: entity.patchLabel,
      excludedVegetableIds: entity.excludedVegetableIds,
      selectedWeight: entity.selectedWeight,
      deliveryFrequency: entity.deliveryFrequency,
    );
  }
}
