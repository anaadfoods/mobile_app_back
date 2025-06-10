class Subscription {
  final int id;
  final int plan;
  final String planName;
  final String startDate;
  final String endDate;
  final String status;
  final String paymentStatus;
  final String paymentMethod;
  final String deliveryAddress;
  final String deliveryCity;
  final String deliveryState;
  final String deliveryPincode;
  final String deliveryPhone;
  final String notes;
  final double subtotal;
  final double deliveryCharges;
  final double totalAmount;
  final double amountPaid;
  final double remainingAmount;
  final String nextDeliveryDate;
  final String? lastPaymentDate;
  final String? nextPaymentDate;
  final int totalDeliveries;
  final int completedDeliveries;
  final double totalWeight;
  final int remainingPauseDays;
  final int remainingPauseTimes;
  final String createdAt;
  final List<SubscriptionItem> items;

  Subscription({
    required this.id,
    required this.plan,
    required this.planName,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.deliveryAddress,
    required this.deliveryCity,
    required this.deliveryState,
    required this.deliveryPincode,
    required this.deliveryPhone,
    required this.notes,
    required this.subtotal,
    required this.deliveryCharges,
    required this.totalAmount,
    required this.amountPaid,
    required this.remainingAmount,
    required this.nextDeliveryDate,
    required this.lastPaymentDate,
    required this.nextPaymentDate,
    required this.totalDeliveries,
    required this.completedDeliveries,
    required this.totalWeight,
    required this.remainingPauseDays,
    required this.remainingPauseTimes,
    required this.createdAt,
    required this.items,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] ?? 0,
      plan: json['plan'] ?? 0,
      planName: json['plan_name'] ?? '',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      status: json['status'] ?? '',
      paymentStatus: json['payment_status'] ?? '',
      paymentMethod: json['payment_method'] ?? '',
      deliveryAddress: json['delivery_address'] ?? '',
      deliveryCity: json['delivery_city'] ?? '',
      deliveryState: json['delivery_state'] ?? '',
      deliveryPincode: json['delivery_pincode'] ?? '',
      deliveryPhone: json['delivery_phone'] ?? '',
      notes: json['notes'] ?? '',
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '0.0') ?? 0.0,
      deliveryCharges:
          double.tryParse(json['delivery_charges']?.toString() ?? '0.0') ?? 0.0,
      totalAmount: double.tryParse(json['total']?.toString() ?? '0.0') ?? 0.0,
      amountPaid:
          double.tryParse(json['amount_paid']?.toString() ?? '0.0') ?? 0.0,
      remainingAmount:
          double.tryParse(json['remaining_amount']?.toString() ?? '0.0') ?? 0.0,
      nextDeliveryDate: json['next_delivery_date'] ?? '',
      lastPaymentDate: json['last_payment_date']?.toString(),
      nextPaymentDate: json['next_payment_date']?.toString(),
      totalDeliveries:
          int.tryParse(json['total_deliveries']?.toString() ?? '0') ?? 0,
      completedDeliveries:
          int.tryParse(json['completed_deliveries']?.toString() ?? '0') ?? 0,
      totalWeight:
          double.tryParse(json['total_weight']?.toString() ?? '0.0') ?? 0.0,
      remainingPauseDays:
          int.tryParse(json['remaining_pause_days']?.toString() ?? '0') ?? 0,
      remainingPauseTimes:
          int.tryParse(json['remaining_pause_times']?.toString() ?? '0') ?? 0,
      createdAt: json['created_at'] ?? '',
      items:
          (json['items'] as List)
              .map((item) => SubscriptionItem.fromJson(item))
              .toList(),
    );
  }
}

class SubscriptionItem {
  final int id;
  final int productVariant;
  final String productName;
  final int quantity;
  final double price;
  final double discountedPrice;
  final double unitWeight;
  final String weightUnit;
  final double totalWeight;

  SubscriptionItem({
    required this.id,
    required this.productVariant,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.discountedPrice,
    required this.unitWeight,
    required this.weightUnit,
    required this.totalWeight,
  });

  factory SubscriptionItem.fromJson(Map<String, dynamic> json) {
    return SubscriptionItem(
      id: json['id'] ?? 0,
      productVariant: json['product_variant'] ?? 0,
      productName: json['product_name'] ?? '',
      quantity: int.tryParse(json['quantity']?.toString() ?? '0') ?? 0,
      price: double.tryParse(json['price']?.toString() ?? '0.0') ?? 0.0,
      discountedPrice:
          double.tryParse(json['discounted_price']?.toString() ?? '0.0') ?? 0.0,
      unitWeight:
          double.parse(json['unit_weight']?.toString() ?? '0.0'),
      weightUnit: json['weight_unit'] ?? '',
      totalWeight:
          double.tryParse(json['total_weight']?.toString() ?? '0.0') ?? 0.0,
    );
  }
}
