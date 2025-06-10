class PlanSearchResult {
  final int planId;
  final String planName;
  final double discountedPrice;

  PlanSearchResult({
    required this.planId,
    required this.planName,
    required this.discountedPrice,
  });

  factory PlanSearchResult.fromJson(Map<String, dynamic> json) {
    return PlanSearchResult(
      planId: json['plan_id'],
      planName: json['plan_name'],
      discountedPrice: json['discounted_price'],
    );
  }
}
