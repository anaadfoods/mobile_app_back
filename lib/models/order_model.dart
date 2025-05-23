import 'package:grocery_app/models/shipping_details.dart';

class OrderProduct {
  final int id;
  final String productName;
  final int quantity;
  final String price;
  final String? image;

  OrderProduct({
    required this.id,
    required this.productName,
    required this.quantity,
    required this.price,
    this.image,
  });

  factory OrderProduct.fromJson(Map<String, dynamic> json) {
    return OrderProduct(
      id: json['id'] ?? 0,
      productName: json['product_name'] ?? '',
      quantity: json['quantity'] ?? 0,
      price: json['price']?.toString() ?? '0',
      image: json['image']?.toString(),
    );
  }
}

class Order {
  final int id;
  final String orderNumber;
  final String status;
  final String paymentStatus;
  final DateTime createdAt;
  final String total;
  final int itemsCount;
  final List<OrderProduct> products;
  final ShippingDetails? shippingDetails;

  Order({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.paymentStatus,
    required this.createdAt,
    required this.total,
    required this.itemsCount,
    required this.products,
    required this.shippingDetails,
  });

  bool get canBeCancelled =>
      status != "DELIVERED" &&
      status != "CANCELLED" &&
      paymentStatus == "PENDING";

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? 0,
      orderNumber: json['order_number'] ?? '',
      status: json['status'] ?? '',
      paymentStatus: json['payment_status'] ?? '',
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      total: json['total']?.toString() ?? '0',
      itemsCount: json['items_count'] ?? 0,
      products:
          (json['products'] as List?)
              ?.map((item) => OrderProduct.fromJson(item))
              .toList() ??
          [],
      shippingDetails:
          json['shipping_details'] != null
              ? ShippingDetails.fromJson(json['shipping_details'])
              : null,
    );
  }

  Order copyWith({
    String? orderNumber,
    DateTime? createdAt,
    String? status,
    String? paymentStatus,
    List<OrderProduct>? products,
    String? total,
    ShippingDetails? shippingDetails,
    bool? canBeCancelled,
  }) {
    return Order(
      id: id,
      orderNumber: orderNumber ?? this.orderNumber,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      createdAt: createdAt ?? this.createdAt,
      total: total ?? this.total,
      itemsCount: this.itemsCount,
      products: products ?? this.products,
      shippingDetails: shippingDetails ?? this.shippingDetails,
    );
  }
}

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
  final String name;
  final String address;
  final String city;
  final String state;
  final String pincode;
  final String phone;

  ShippingDetails({
    required this.name,
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
    required this.phone,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'shipping_address': address,
      'shipping_city': city,
      'shipping_state': state,
      'shipping_pincode': pincode,
      'shipping_phone': phone,
    };
  }

  factory ShippingDetails.fromJson(Map<String, dynamic> json) {
    return ShippingDetails(
      name: json['name'] ?? '',
      address: json['shipping_address'] ?? json['address'] ?? '',
      city: json['shipping_city'] ?? json['city'] ?? '',
      state: json['shipping_state'] ?? json['state'] ?? '',
      pincode: json['shipping_pincode'] ?? json['pincode'] ?? '',
      phone: json['shipping_phone'] ?? json['phone'] ?? '',
    );
  }

  bool get isComplete {
    return name.isNotEmpty &&
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
  });

  Map<String, dynamic> toJson() {
    return {
      'payment_method': paymentMethod,
      'shipping_address': shippingAddress,
      'shipping_city': shippingCity,
      'shipping_state': shippingState,
      'shipping_pincode': shippingPincode,
      'shipping_phone': shippingPhone,
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
      shippingAddress: orderData['shipping_address'] ?? '',
      shippingCity: orderData['shipping_city'] ?? '',
      shippingState: orderData['shipping_state'] ?? '',
      shippingPincode: orderData['shipping_pincode'] ?? '',
      shippingPhone: orderData['shipping_phone'] ?? '',
      items:
          (orderData['items'] as List?)
              ?.map((item) => OrderItem.fromJson(item))
              .toList() ??
          [],
      notes: orderData['notes'],
      status: orderData['status'],
    );
  }

  // Factory constructor to create from ShippingDetails
  factory OrderModel.fromShippingDetails({
    required String paymentMethod,
    required ShippingDetails shippingDetails,
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
      items: items,
      notes: notes,
    );
  }
}
