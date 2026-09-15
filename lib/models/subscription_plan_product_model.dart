class SubscriptionPlanProduct {
  final int productId;
  final String productName;
  final double maxWeightLimit;

  SubscriptionPlanProduct({
    required this.productId,
    required this.productName,
    required this.maxWeightLimit,
  });

  factory SubscriptionPlanProduct.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlanProduct(
      productId: json['variant_id'],
      productName: json['variant_name'],
      maxWeightLimit:
          double.tryParse(json['max_weight_limit']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'variant_id': productId,
      'variant_name': productName,
      'max_weight_limit': maxWeightLimit,
    };
  }
}

class SubscriptionPlanProductsResponse {
  final int planId;
  final String planName;
  final List<SubscriptionPlanProduct> products;

  SubscriptionPlanProductsResponse({
    required this.planId,
    required this.planName,
    required this.products,
  });

  factory SubscriptionPlanProductsResponse.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlanProductsResponse(
      planId: json['plan_id'],
      planName: json['plan_name'],
      products:
          (json['variants'] as List)
              .map((product) => SubscriptionPlanProduct.fromJson(product))
              .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'plan_id': planId,
      'plan_name': planName,
      'products': products.map((product) => product.toJson()).toList(),
    };
  }
}
