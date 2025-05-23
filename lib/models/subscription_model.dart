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
  final String totalAmount;
  final String amountPaid;
  final double remainingAmount;
  final String nextDeliveryDate;
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
    required this.totalAmount,
    required this.amountPaid,
    required this.remainingAmount,
    required this.nextDeliveryDate,
    required this.totalWeight,
    required this.remainingPauseDays,
    required this.remainingPauseTimes,
    required this.createdAt,
    required this.items,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'],
      plan: json['plan'],
      planName: json['plan_name'],
      startDate: json['start_date'],
      endDate: json['end_date'],
      status: json['status'],
      paymentStatus: json['payment_status'],
      paymentMethod: json['payment_method'],
      deliveryAddress: json['delivery_address'],
      deliveryCity: json['delivery_city'],
      deliveryState: json['delivery_state'],
      deliveryPincode: json['delivery_pincode'],
      deliveryPhone: json['delivery_phone'],
      notes: json['notes'] ?? '',
      totalAmount: json['total_amount'],
      amountPaid: json['amount_paid'],
      remainingAmount: (json['remaining_amount'] as num).toDouble(),
      nextDeliveryDate: json['next_delivery_date'],
      totalWeight: (json['total_weight'] as num).toDouble(),
      remainingPauseDays: json['remaining_pause_days'],
      remainingPauseTimes: json['remaining_pause_times'],
      createdAt: json['created_at'],
      items: (json['items'] as List)
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
  final String price;
  final String discountedPrice;
  final String unitWeight;
  final String weightUnit;
  final String totalWeight;

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
      id: json['id'],
      productVariant: json['product_variant'],
      productName: json['product_name'],
      quantity: json['quantity'],
      price: json['price'],
      discountedPrice: json['discounted_price'],
      unitWeight: json['unit_weight'],
      weightUnit: json['weight_unit'],
      totalWeight: json['total_weight'],
    );
  }
}