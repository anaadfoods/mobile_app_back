/// Request model for creating a subscription
///
/// Field Mapping to API:
/// - plan → plan (int: subscription plan ID)
/// - deliveryName → recipient_name (String: customer name)
/// - deliveryAddress → delivery_address (String: full address)
/// - deliveryCity → delivery_city (String: city name)
/// - deliveryState → delivery_state (String: state name)
/// - deliveryPincode → delivery_pincode (String: postal code)
/// - deliveryPhone → delivery_phone (String: contact number)
/// - paymentType → payment_type (String: PAID_FULL or INSTALLMENT)
/// - paymentMethod → payment_method (String: COD or UPI)
/// - deliveryFee → delivery_fee (double: delivery charges)
/// - expectedDeliveryDate → expected_delivery_date (String: ISO date)
/// - items → items (List: products in subscription)
///
/// Example Request:
/// ```json
/// {
///   "plan": 4,
///   "recipient_name": "Hemant",
///   "delivery_address": "Village Bhurri",
///   "delivery_city": "Sonipat",
///   "delivery_state": "Haryana",
///   "delivery_pincode": "131101",
///   "delivery_phone": "7027277570",
///   "payment_type": "PAID_FULL",
///   "payment_method": "COD",
///   "delivery_fee": 127.00,
///   "expected_delivery_date": "2025-10-15",
///   "items": [
///     {
///       "product_variant_id": 6,
///       "quantity": 1
///     }
///   ]
/// }
/// ```
class SubscriptionCreateRequest {
  final int? plan;
  final String deliveryName;
  final String deliveryAddress;
  final String deliveryCity;
  final String deliveryState;
  final String deliveryPincode;
  final String deliveryPhone;
  final String paymentType;
  final String paymentMethod;
  final double deliveryFee;
  final String expectedDeliveryDate;
  final List<SubscriptionCreateItem> items;

  SubscriptionCreateRequest({
    this.plan,
    this.deliveryName = '',
    required this.deliveryAddress,
    required this.deliveryCity,
    required this.deliveryState,
    required this.deliveryPincode,
    required this.deliveryPhone,
    required this.paymentType,
    required this.paymentMethod,
    required this.items,
    required this.deliveryFee,
    required this.expectedDeliveryDate,
  });

  Map<String, dynamic> toJson() => {
    'plan': plan ?? 0,
    'recipient_name': deliveryName,
    'delivery_address': deliveryAddress,
    'delivery_city': deliveryCity,
    'delivery_state': deliveryState,
    'delivery_pincode': deliveryPincode,
    'delivery_phone': deliveryPhone,
    'payment_type': paymentType,
    'payment_method': paymentMethod,
    'delivery_fee': deliveryFee,
    'expected_delivery_date': expectedDeliveryDate,
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
