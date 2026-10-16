/// User's configuration for a selected patch.
class RfpPatchConfig {
  final String patchId;
  final String patchLabel;
  final List<String> excludedVegetableIds;
  final double selectedWeight;
  final String deliveryFrequency; // 'once_a_week', 'twice_a_week'
  final int? planPricingId;
  final List<String>? selectedVegetableIds;
  final List<String>? deliveryDays;

  const RfpPatchConfig({
    required this.patchId,
    required this.patchLabel,
    required this.excludedVegetableIds,
    required this.selectedWeight,
    required this.deliveryFrequency,
    this.planPricingId,
    this.selectedVegetableIds,
    this.deliveryDays,
  });

  int get exclusionCount => excludedVegetableIds.length;

  RfpPatchConfig copyWith({
    String? patchId,
    String? patchLabel,
    List<String>? excludedVegetableIds,
    double? selectedWeight,
    String? deliveryFrequency,
    int? planPricingId,
    List<String>? selectedVegetableIds,
    List<String>? deliveryDays,
  }) {
    return RfpPatchConfig(
      patchId: patchId ?? this.patchId,
      patchLabel: patchLabel ?? this.patchLabel,
      excludedVegetableIds: excludedVegetableIds ?? this.excludedVegetableIds,
      selectedWeight: selectedWeight ?? this.selectedWeight,
      deliveryFrequency: deliveryFrequency ?? this.deliveryFrequency,
      planPricingId: planPricingId ?? this.planPricingId,
      selectedVegetableIds: selectedVegetableIds ?? this.selectedVegetableIds,
      deliveryDays: deliveryDays ?? this.deliveryDays,
    );
  }
}
