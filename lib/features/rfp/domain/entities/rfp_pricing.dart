/// Pricing breakdown for an RFP subscription.
class RfpPricing {
  final double basePrice;
  final String? discountLabel;
  final double discountAmount;
  final double finalPrice;
  final double bookingAmount;
  final double remainingAmount;
  final double perDelivery;
  final int deliveriesCount;
  final int bookingDeliveries;
  final int remainingDeliveries;
  final double discountPercentage;
  final int planCount;

  const RfpPricing({
    required this.basePrice,
    this.discountLabel,
    required this.discountAmount,
    required this.finalPrice,
    required this.bookingAmount,
    required this.remainingAmount,
    this.perDelivery = 0.0,
    this.deliveriesCount = 12,
    this.bookingDeliveries = 2,
    this.remainingDeliveries = 10,
    this.discountPercentage = 0.0,
    this.planCount = 1,
  });
}
