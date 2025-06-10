// class ProductLimit {
//   final int product;
//   final String productName;
//   final double maxWeightLimit;

//   ProductLimit({
//     required this.product,
//     required this.productName,
//     required this.maxWeightLimit,
//   });

//   factory ProductLimit.fromJson(Map<String, dynamic> json) {
//     return ProductLimit(
//       product: json['product'],
//       productName: json['product_name'],
//       maxWeightLimit: double.parse(json['max_weight_limit']),
//     );
//   }
// }

class SubscriptionPlan {
  final int id;
  final String name;
  final int durationMonths;
  final String discountPercentage;
  final double totalDiscountPercentage;
  final String tagline;
  final String description;
  final bool isActive;
  final String activationDate;
  final bool isOneTimeOnly;
  final bool allowsInstallments;
  final int installmentFrequencyMonths;
  final bool isAvailable;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.durationMonths,
    required this.discountPercentage,
    required this.totalDiscountPercentage,
    required this.tagline,
    required this.description,
    required this.isActive,
    required this.activationDate,
    required this.isOneTimeOnly,
    required this.allowsInstallments,
    required this.installmentFrequencyMonths,
    required this.isAvailable,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'],
      name: json['name'],
      durationMonths: json['duration_months'],
      discountPercentage: json['discount_percentage'],
      totalDiscountPercentage: (json['total_discount_percentage'] as num).toDouble(),
      tagline: json['tagline'],
      description: json['description'],
      isActive: json['is_active'],
      activationDate: json['activation_date'],
      isOneTimeOnly: json['is_one_time_only'],
      allowsInstallments: json['allows_installments'],
      installmentFrequencyMonths: json['installment_frequency_months'],
      isAvailable: json['is_available'],
    );
  }
}