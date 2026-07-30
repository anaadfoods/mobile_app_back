/// Domain entity for a subscription plan.
/// Pure Dart — no Flutter or third-party imports.
class SubscriptionPlanEntity {
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

  const SubscriptionPlanEntity({
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
}
