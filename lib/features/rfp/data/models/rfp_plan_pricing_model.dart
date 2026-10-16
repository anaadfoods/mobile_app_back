import '../../domain/entities/rfp_plan_pricing.dart';

class RfpPlanPricingModel extends RfpPlanPricing {
  const RfpPlanPricingModel({
    required super.id,
    required super.variantName,
    required super.weightKg,
    required super.frequencyPerWeek,
    required super.pricePerDelivery,
  });

  factory RfpPlanPricingModel.fromJson(Map<String, dynamic> json) {
    return RfpPlanPricingModel(
      id:
          json['id'] is int
              ? json['id'] as int
              : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      variantName: json['variant_name'] as String? ?? 'SMALL',
      weightKg:
          (json['weight_kg'] is num)
              ? (json['weight_kg'] as num).toDouble()
              : double.tryParse(json['weight_kg']?.toString() ?? '2.50') ?? 2.5,
      frequencyPerWeek:
          json['frequency_per_week'] is int
              ? json['frequency_per_week'] as int
              : int.tryParse(json['frequency_per_week']?.toString() ?? '1') ??
                  1,
      pricePerDelivery:
          (json['price_per_delivery'] is num)
              ? (json['price_per_delivery'] as num).toDouble()
              : double.tryParse(
                    json['price_per_delivery']?.toString() ?? '0.0',
                  ) ??
                  0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'variant_name': variantName,
      'weight_kg': weightKg.toStringAsFixed(2),
      'frequency_per_week': frequencyPerWeek,
      'price_per_delivery': pricePerDelivery.toStringAsFixed(2),
    };
  }

  factory RfpPlanPricingModel.fromEntity(RfpPlanPricing entity) {
    return RfpPlanPricingModel(
      id: entity.id,
      variantName: entity.variantName,
      weightKg: entity.weightKg,
      frequencyPerWeek: entity.frequencyPerWeek,
      pricePerDelivery: entity.pricePerDelivery,
    );
  }
}
