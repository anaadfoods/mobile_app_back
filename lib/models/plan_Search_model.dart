class PlanSearchResult {
  final int planId;
  final String planName;
  final double discountedPrice;
  final double discountPercentage;

  PlanSearchResult( {required this.discountedPrice,required this.discountPercentage,required this.planId, required this.planName});

  factory PlanSearchResult.fromJson(Map<String, dynamic> json) {
    return PlanSearchResult(
      planId: json['plan_id'],
      planName: json['plan_name'],
       discountedPrice: json['discounted_price']?.toDouble() ?? 0.0,
        discountPercentage: json['discount_percentage']?.toDouble() ?? 0.0,
    );
  }
}