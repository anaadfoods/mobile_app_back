class SubscriptionCreateRequest {
  final int? plan;
  final String deliveryAddress;
  final String deliveryCity;
  final String deliveryState;
  final String deliveryPincode;
  final String deliveryPhone;
  final String paymentType;
  final String paymentMethod;
  final List<SubscriptionCreateItem> items;

  SubscriptionCreateRequest({
    this.plan,
    required this.deliveryAddress,
    required this.deliveryCity,
    required this.deliveryState,
    required this.deliveryPincode,
    required this.deliveryPhone,
    required this.paymentType,
    required this.paymentMethod,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
    'plan': plan ?? 0,
    'delivery_address': deliveryAddress,
    'delivery_city': deliveryCity,
    'delivery_state': deliveryState,
    'delivery_pincode': deliveryPincode,
    'delivery_phone': deliveryPhone,
    'payment_type': paymentType,
    'payment_method': paymentMethod,
    'items': items.map((e) => e.toJson()).toList(),
  };
}

class SubscriptionCreateItem {
  final int? productVariantId;
  final int? quantity;

  SubscriptionCreateItem({
    required this.productVariantId,
    required this.quantity,
  });

  factory SubscriptionCreateItem.fromJson(Map<String, dynamic> json) {
    return SubscriptionCreateItem(
      productVariantId: json['product_variant_id'] as int?,
      quantity: json['quantity'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'product_variant_id': productVariantId,
    'quantity': quantity,
  };
}
