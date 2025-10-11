import 'dart:convert';
import 'package:grocery_app/models/product_model.dart';
import 'package:intl/intl.dart';

/// Decodes a JSON string into an [Order] object.
/// Decodes a JSON string into an [Order] object.
Order orderFromJson(String str) => Order.fromJson(json.decode(str));

/// Encodes an [Order] object into a JSON string.
String orderToJson(Order data) => json.encode(data.toJson());

/// A helper function to safely parse date strings from the API,
/// handling multiple possible formats.
DateTime _parseDate(String? dateString) {
  if (dateString == null) {
    return DateTime.now();
  }
  // Try parsing the format "dd/MM/yyyy"
  try {
    return DateFormat('dd/MM/yyyy').parse(dateString);
  } on FormatException {
    // If it fails, try the standard ISO 8601 format
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      // If all parsing fails, return the current date as a fallback
      return DateTime.now();
    }
  }
}

class Order {
  final int id;
  final String orderNumber;
  final String status;
  final String paymentStatus;
  final String paymentMethod;
  final String? paymentReference;
  final String deliveryAddress;
  final String deliveryCity;
  final String deliveryState;
  final String deliveryPincode;
  final String deliveryPhone;
  final double subtotal;
  final double tax;
  final double deliveryCharges;
  final double discount;
  final double total;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime expectedDeliveryDate;
  final bool isSubscriptionOrder;
  final bool isFirstOrder;
  final bool hasReferralReward;
  final String? notes;
  final List<OrderItemResponse> items;

  Order({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.paymentStatus,
    required this.paymentMethod,
    this.paymentReference,
    required this.deliveryAddress,
    required this.deliveryCity,
    required this.deliveryState,
    required this.deliveryPincode,
    required this.deliveryPhone,
    required this.subtotal,
    required this.tax,
    required this.deliveryCharges,
    required this.discount,
    required this.total,
    required this.createdAt,
    required this.updatedAt,
    required this.expectedDeliveryDate,
    required this.isSubscriptionOrder,
    required this.isFirstOrder,
    required this.hasReferralReward,
    this.notes,
    required this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json["id"] ?? 0,
      orderNumber: json["order_number"] ?? '',
      status: json["status"] ?? 'N/A',
      paymentStatus: json["payment_status"] ?? 'N/A',
      paymentMethod: json["payment_method"] ?? 'N/A',
      paymentReference: json["payment_reference"],
      deliveryAddress: json["delivery_address"] ?? '',
      deliveryCity: json["delivery_city"] ?? '',
      deliveryState: json["delivery_state"] ?? '',
      deliveryPincode: json["delivery_pincode"] ?? '',
      deliveryPhone: json["delivery_phone"] ?? '',
      subtotal: double.tryParse(json["subtotal"]?.toString() ?? '0') ?? 0.0,
      tax: double.tryParse(json["tax"]?.toString() ?? '0') ?? 0.0,
      deliveryCharges:
          double.tryParse(json["delivery_charges"]?.toString() ?? '0') ?? 0.0,
      discount: double.tryParse(json["discount"]?.toString() ?? '0') ?? 0.0,
      total: double.tryParse(json["total"]?.toString() ?? '0') ?? 0.0,
      createdAt: _parseDate(json["created_at"]),
      updatedAt: _parseDate(json["updated_at"]),
      expectedDeliveryDate: _parseDate(json["expected_delivery_date"]),
      isSubscriptionOrder: json["is_subscription_order"] ?? false,
      isFirstOrder: json["is_first_order"] ?? false,
      hasReferralReward: json["has_referral_reward"] ?? false,
      notes: json["notes"],
      items: json["items"] == null
          ? [] 
          : List<OrderItemResponse>.from(
              json["items"].map((x) => OrderItemResponse.fromJson(x))),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "order_number": orderNumber,
      "status": status,
      "payment_status": paymentStatus,
      "payment_method": paymentMethod,
      "payment_reference": paymentReference,
      "delivery_address": deliveryAddress,
      "delivery_city": deliveryCity,
      "delivery_state": deliveryState,
      "delivery_pincode": deliveryPincode,
      "delivery_phone": deliveryPhone,
      "subtotal": subtotal.toStringAsFixed(2),
      "tax": tax.toStringAsFixed(2),
      "delivery_charges": deliveryCharges.toStringAsFixed(2),
      "discount": discount.toStringAsFixed(2),
      "total": total.toStringAsFixed(2),
      "created_at": createdAt.toIso8601String(),
      "updated_at": updatedAt.toIso8601String(),
      "expected_delivery_date":
          "${expectedDeliveryDate.year.toString().padLeft(4, '0')}-${expectedDeliveryDate.month.toString().padLeft(2, '0')}-${expectedDeliveryDate.day.toString().padLeft(2, '0')}",
      "is_subscription_order": isSubscriptionOrder,
      "is_first_order": isFirstOrder,
      "has_referral_reward": hasReferralReward,
      "notes": notes,
      "items": List<dynamic>.from(items.map((x) => x.toJson())),
    };
  }

  Order copyWith({
    int? id,
    String? orderNumber,
    String? status,
    String? paymentStatus,
    String? paymentMethod,
    String? paymentReference,
    String? deliveryAddress,
    String? deliveryCity,
    String? deliveryState,
    String? deliveryPincode,
    String? deliveryPhone,
    double? subtotal,
    double? tax,
    double? deliveryCharges,
    double? discount,
    double? total,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? expectedDeliveryDate,
    bool? isSubscriptionOrder,
    bool? isFirstOrder,
    bool? hasReferralReward,
    String? notes,
    List<OrderItemResponse>? items,
  }) {
    return Order(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentReference: paymentReference ?? this.paymentReference,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryCity: deliveryCity ?? this.deliveryCity,
      deliveryState: deliveryState ?? this.deliveryState,
      deliveryPincode: deliveryPincode ?? this.deliveryPincode,
      deliveryPhone: deliveryPhone ?? this.deliveryPhone,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      deliveryCharges: deliveryCharges ?? this.deliveryCharges,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      expectedDeliveryDate: expectedDeliveryDate ?? this.expectedDeliveryDate,
      isSubscriptionOrder: isSubscriptionOrder ?? this.isSubscriptionOrder,
      isFirstOrder: isFirstOrder ?? this.isFirstOrder,
      hasReferralReward: hasReferralReward ?? this.hasReferralReward,
      notes: notes ?? this.notes,
      items: items ?? this.items,
    );
  }
}


class OrderItemResponse {
  final Product productDetails;
  final int quantity;
  final double price;
  final double discount;
  final double total;

  OrderItemResponse({
    required this.productDetails,
    required this.quantity,
    required this.price,
    required this.discount,
    required this.total,
  });

  factory OrderItemResponse.fromJson(Map<String, dynamic> json) {
    return OrderItemResponse(
      productDetails: Product.fromJson(json["product_details"]),
      quantity: json["quantity"],
      price: double.tryParse(json["price"] ?? '0') ?? 0.0,
      discount: double.tryParse(json["discount"] ?? '0') ?? 0.0,
      total: double.tryParse(json["total"] ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "product_details": productDetails.toJson(),
      "quantity": quantity,
      "price": price.toStringAsFixed(2),
      "discount": discount.toStringAsFixed(2),
      "total": total.toStringAsFixed(2),
    };
  }
}



// class Order {
//   final int id;
//   final String orderNumber;
//   final String status;
//   final String paymentStatus;
//   final DateTime createdAt;
//   final String total;
//   final int itemsCount;
//   final String? deliveryCharges;
//   final String? expectedDeliveryDate;
//   final List<OrderProduct> products;
//   final ShippingDetails? shippingDetails;

//   Order({
//     this.deliveryCharges,
//     this.expectedDeliveryDate,
//     required this.id,
//     required this.orderNumber,
//     required this.status,
//     required this.paymentStatus,
//     required this.createdAt,
//     required this.total,
//     required this.itemsCount,
//     required this.products,
//     required this.shippingDetails,
//   });

//   bool get canBeCancelled =>
//       status != "DELIVERED" &&
//       status != "CANCELLED" &&
//       paymentStatus == "PENDING";

//   factory Order.fromJson(Map<String, dynamic> json) {
//     return Order(
//       id: json['id'] ?? 0,
//       orderNumber: json['order_number'] ?? '',
//       status: json['status'] ?? '',
//       paymentStatus: json['payment_status'] ?? '',
//       createdAt: DateTime.parse(
//         json['created_at'] ?? DateTime.now().toIso8601String(),
//       ),
//       total: json['total']?.toString() ?? '0',
//       itemsCount: json['items_count'] ?? 0,
//       deliveryCharges: json['delivery_charges']?.toString(),
//       expectedDeliveryDate: json['expected_delivery_date']?.toString(),
//       products:
//           (json['items'] as List?)
//               ?.map((item) => OrderProduct.fromJson(item))
//               .toList() ??
//           [],
//       shippingDetails:
//           json['shipping_details'] != null
//               ? ShippingDetails.fromJson(json['shipping_details'])
//               : null,
//     );
//   }

//   Order copyWith({
//     String? orderNumber,
//     DateTime? createdAt,
//     String? status,
//     String? paymentStatus,
//     List<OrderProduct>? products,
//     String? total,
//     String? deliveryCharges,
//     String? expectedDeliveryDate,
//     ShippingDetails? shippingDetails,
//     bool? canBeCancelled,
//   }) {
//     return Order(
//       id: id,
//       orderNumber: orderNumber ?? this.orderNumber,
//       status: status ?? this.status,
//       paymentStatus: paymentStatus ?? this.paymentStatus,
//       createdAt: createdAt ?? this.createdAt,
//       total: total ?? this.total,
//       deliveryCharges: deliveryCharges ?? this.deliveryCharges,
//       expectedDeliveryDate: expectedDeliveryDate ?? this.expectedDeliveryDate,
//       itemsCount: itemsCount,
//       products: products ?? this.products,
//       shippingDetails: shippingDetails ?? this.shippingDetails,
//     );
//   }
// }

class OrderItem {
  final int productVariantId;
  final int quantity;

  OrderItem({required this.productVariantId, required this.quantity});

  Map<String, dynamic> toJson() {
    return {'product_variant_id': productVariantId, 'quantity': quantity};
  }

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productVariantId: json['product_variant_id'] ?? 0,
      quantity: json['quantity'] ?? 0,
    );
  }
}

class ShippingDetails {

  final String address;
  final String city;
  final String state;
  final String pincode;
  final String phone;

  ShippingDetails({
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
    required this.phone, String? name,
  });

  Map<String, dynamic> toJson() {
    return {
      'delivery_address': address,
      'delivery_city': city,
      'delivery_state': state,
      'delivery_pincode': pincode,
      'delivery_phone': phone,
    };
  }

  factory ShippingDetails.fromJson(Map<String, dynamic> json) {
    return ShippingDetails(
      address: json['delivery_address'] ?? json['address'] ?? '',
      city: json['delivery_city'] ?? json['city'] ?? '',
      state: json['delivery_state'] ?? json['state'] ?? '',
      pincode: json['delivery_pincode'] ?? json['pincode'] ?? '',
      phone: json['delivery_phone'] ?? json['phone'] ?? '',
    );
  }

  bool get isComplete {
    return
        address.isNotEmpty &&
        city.isNotEmpty &&
        state.isNotEmpty &&
        pincode.isNotEmpty &&
        phone.isNotEmpty;
  }
}

class OrderModel {
  final String? orderNumber;
  final String? total;
  final String paymentMethod;
  final String shippingAddress;
  final String shippingCity;
  final String shippingState;
  final String shippingPincode;
  final String shippingPhone;
  final double deliveryFee;
  final String expectedDeliveryDate;
  final List<OrderItem> items;
  final String? notes;
  final String? status;

  OrderModel({
    this.orderNumber,
    this.total,
    required this.paymentMethod,
    required this.shippingAddress,
    required this.shippingCity,
    required this.shippingState,
    required this.shippingPincode,
    required this.shippingPhone,
    required this.items,
    this.notes,
    this.status, 
    required this.expectedDeliveryDate, // Use 'this.'
  required this.deliveryFee,
  });


  Map<String, dynamic> toJson() {
    return {
      'payment_method': paymentMethod,
      'delivery_address': shippingAddress,
      'delivery_city': shippingCity,
      'delivery_state': shippingState,
      'delivery_pincode': shippingPincode,
      'delivery_phone': shippingPhone,
      'delivery_fee': deliveryFee,
      'expected_delivery_date': expectedDeliveryDate,
      'items': items.map((item) => item.toJson()).toList(),
      'notes': notes,
    };
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    // Handle nested order data
    final orderData = json['order'] ?? json;

    return OrderModel(
      orderNumber: orderData['order_number'],
      total: orderData['total']?.toString(),
      paymentMethod: orderData['payment_method'] ?? 'COD',
      shippingAddress: orderData['delivery_address'] ?? '',
      shippingCity: orderData['delivery_city'] ?? '',
      shippingState: orderData['delivery_state'] ?? '',
      shippingPincode: orderData['delivery_pincode'] ?? '',
      shippingPhone: orderData['delivery_phone'] ?? '',
      items:
          (orderData['items'] as List?)
              ?.map((item) => OrderItem.fromJson(item))
              .toList() ??
          [],
      notes: orderData['notes'],
      status: orderData['status'], expectedDeliveryDate: orderData['expected_delivery_date'], 
    deliveryFee: double.tryParse(orderData['delivery_charges']?.toString() ?? '0.0') ?? 0.0,
    );
  }

  // Factory constructor to create from ShippingDetails
  factory OrderModel.fromShippingDetails({
    required String paymentMethod,
    required ShippingDetails shippingDetails,
    required String expectedDeliveryDate,
    required double deliveryFee,
    required List<OrderItem> items,
    String? notes,
  }) {
    return OrderModel(
      paymentMethod: paymentMethod,
      shippingAddress: shippingDetails.address,
      shippingCity: shippingDetails.city,
      shippingState: shippingDetails.state,
      shippingPincode: shippingDetails.pincode,
      shippingPhone: shippingDetails.phone,
      expectedDeliveryDate: expectedDeliveryDate,
      deliveryFee: deliveryFee,
      items: items,
      notes: notes,
    );
  }
  
 
}

class PaymentLinks {
  final String web;
  final String? expiry;

  PaymentLinks({required this.web, this.expiry});

  factory PaymentLinks.fromJson(Map<String, dynamic> json) {
    return PaymentLinks(
      web: json['web'] as String,
      expiry: json['expiry'] as String?,
    );
  }
}

class OrderCreateResponse {
  final bool success;
  final PaymentLinks? paymentLinks;
  final String? orderId;
  final String? merchantTransactionId;
  final String? message;

  OrderCreateResponse({
    required this.success,
    this.paymentLinks,
    this.orderId,
    this.merchantTransactionId,
    this.message,
  });

  factory OrderCreateResponse.fromJson(Map<String, dynamic> json) {
    return OrderCreateResponse(
      success: json['success'] ?? false,
      paymentLinks:
          json['payment_links'] != null
              ? PaymentLinks.fromJson(json['payment_links'])
              : null,
      orderId: json['order_id']?.toString(),
      merchantTransactionId: json['merchant_transaction_id']?.toString(),
      message: json['message']?.toString(),
    );
  }
}
