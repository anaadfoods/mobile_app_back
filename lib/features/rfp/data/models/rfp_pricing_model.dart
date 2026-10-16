import '../../domain/entities/rfp_pricing.dart';

class RfpPricingModel extends RfpPricing {
  const RfpPricingModel({
    required super.basePrice,
    super.discountLabel,
    required super.discountAmount,
    required super.finalPrice,
    required super.bookingAmount,
    required super.remainingAmount,
    super.perDelivery,
    super.deliveriesCount,
    super.bookingDeliveries,
    super.remainingDeliveries,
    super.discountPercentage,
    super.planCount,
  });

  factory RfpPricingModel.fromJson(Map<String, dynamic> json) {
    double parseD(dynamic val, [double def = 0.0]) {
      if (val == null) return def;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? def;
    }

    int parseI(dynamic val, [int def = 0]) {
      if (val == null) return def;
      if (val is int) return val;
      return int.tryParse(val.toString()) ?? def;
    }

    if (json.containsKey('breakdown') && json['breakdown'] is Map) {
      json = json['breakdown'] as Map<String, dynamic>;
    }

    // Backend calculate/ response format
    if (json.containsKey('pay_now') || json.containsKey('total')) {
      final payNow = parseD(json['pay_now']);
      final payLater = parseD(json['pay_later']);
      final total = parseD(json['total']);
      final discPercent = parseD(json['discount_percentage']);
      final perDrop = parseD(
        json['per_delivery'] ?? json['price_per_delivery'],
      );
      final deliveries = parseI(json['deliveries_count'], 12);
      final bookingDeliv = parseI(json['booking_deliveries'], 2);
      final remainingDeliv = parseI(json['remaining_deliveries'], 10);
      final plans = parseI(json['plan_count'], 1);

      double base = total;
      double discAmount = 0.0;
      if (discPercent > 0 && discPercent < 100) {
        base = total / (1.0 - (discPercent / 100.0));
        discAmount = base - total;
      }

      final label =
          discPercent > 0
              ? 'Bundle Discount (${discPercent.toStringAsFixed(discPercent.truncateToDouble() == discPercent ? 0 : 2)}%)'
              : null;

      return RfpPricingModel(
        basePrice: base,
        discountLabel: label,
        discountAmount: discAmount,
        finalPrice: total,
        bookingAmount: payNow,
        remainingAmount: payLater,
        perDelivery: perDrop,
        deliveriesCount: deliveries,
        bookingDeliveries: bookingDeliv,
        remainingDeliveries: remainingDeliv,
        discountPercentage: discPercent,
        planCount: plans,
      );
    }

    // Legacy / direct format
    return RfpPricingModel(
      basePrice: parseD(json['base_price']),
      discountLabel: json['discount_label'] as String?,
      discountAmount: parseD(json['discount_amount']),
      finalPrice: parseD(json['final_price']),
      bookingAmount: parseD(json['booking_amount']),
      remainingAmount: parseD(json['remaining_amount']),
      perDelivery: parseD(json['per_delivery']),
      deliveriesCount: parseI(json['deliveries_count'], 12),
      bookingDeliveries: parseI(json['booking_deliveries'], 2),
      remainingDeliveries: parseI(json['remaining_deliveries'], 10),
      discountPercentage: parseD(json['discount_percentage']),
      planCount: parseI(json['plan_count'], 1),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'base_price': basePrice,
      'discount_label': discountLabel,
      'discount_amount': discountAmount,
      'final_price': finalPrice,
      'booking_amount': bookingAmount,
      'remaining_amount': remainingAmount,
      'per_delivery': perDelivery,
      'deliveries_count': deliveriesCount,
      'booking_deliveries': bookingDeliveries,
      'remaining_deliveries': remainingDeliveries,
      'discount_percentage': discountPercentage,
      'plan_count': planCount,
    };
  }

  factory RfpPricingModel.fromEntity(RfpPricing entity) {
    return RfpPricingModel(
      basePrice: entity.basePrice,
      discountLabel: entity.discountLabel,
      discountAmount: entity.discountAmount,
      finalPrice: entity.finalPrice,
      bookingAmount: entity.bookingAmount,
      remainingAmount: entity.remainingAmount,
      perDelivery: entity.perDelivery,
      deliveriesCount: entity.deliveriesCount,
      bookingDeliveries: entity.bookingDeliveries,
      remainingDeliveries: entity.remainingDeliveries,
      discountPercentage: entity.discountPercentage,
      planCount: entity.planCount,
    );
  }
}
