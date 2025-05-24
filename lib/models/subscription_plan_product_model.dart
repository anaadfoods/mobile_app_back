class SubscriptionPlanProduct {
  final int productId;
  final String productName;

  SubscriptionPlanProduct({required this.productId, required this.productName});

  factory SubscriptionPlanProduct.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlanProduct(
      productId: json['product_id'],
      productName: json['product_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'product_id': productId, 'product_name': productName};
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
          (json['products'] as List)
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
