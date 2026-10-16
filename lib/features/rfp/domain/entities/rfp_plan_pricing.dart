/// Pricing option for an RFP plan (variant, weight, frequency, and price per delivery).
class RfpPlanPricing {
  final int id;
  final String variantName; // MINI, SMALL, MEDIUM, LARGE
  final double weightKg;
  final int frequencyPerWeek; // 1 or 2
  final double pricePerDelivery;

  const RfpPlanPricing({
    required this.id,
    required this.variantName,
    required this.weightKg,
    required this.frequencyPerWeek,
    required this.pricePerDelivery,
  });
}
