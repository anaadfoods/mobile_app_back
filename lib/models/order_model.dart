import 'package:grocery_app/models/product_image_model.dart';

class OrderProduct {
  final int id;
  final String productName;
  final int quantity;
  final String price;
  final String? image;
  final String? discount;
  final String? total;
  final ProductDetails? productDetails;

  OrderProduct({
    required this.id,
    required this.productName,
    required this.quantity,
    required this.price,
    this.image,
    this.discount,
    this.total,
    this.productDetails,
  });

  factory OrderProduct.fromJson(Map<String, dynamic> json) {
    final productDetails =
        json['product_details'] != null
            ? ProductDetails.fromJson(json['product_details'])
            : null;

    String? imageUrl;
    if (productDetails != null && productDetails.productImages.isNotEmpty) {
      imageUrl = productDetails.productImages.first.image;
    }

    return OrderProduct(
      id: json['id'] ?? 0,
      productName: productDetails?.productName ?? json['product_name'] ?? '',
      quantity: json['quantity'] ?? 0,
      price: json['price']?.toString() ?? '0',
      image: imageUrl,
      discount: json['discount']?.toString(),
      total: json['total']?.toString(),
      productDetails: productDetails,
    );
  }
}

class ProductDetails {
  final int id;
  final String sku;
  final String weight;
  final String weightUnit;
  final String price;
  final String discountPercentage;
  final String finalPrice;
  final bool isInStock;
  final bool isActive;
  final String productName;
  final String productDescription;
  final String productCategory;
  final List<ProductImage> productImages;

  ProductDetails({
    required this.id,
    required this.sku,
    required this.weight,
    required this.weightUnit,
    required this.price,
    required this.discountPercentage,
    required this.finalPrice,
    required this.isInStock,
    required this.isActive,
    required this.productName,
    required this.productDescription,
    required this.productCategory,
    required this.productImages,
  });

  factory ProductDetails.fromJson(Map<String, dynamic> json) {
    return ProductDetails(
      id: json['id'] ?? 0,
      sku: json['sku'] ?? '',
      weight: json['weight'] ?? '',
      weightUnit: json['weight_unit'] ?? '',
      price: json['price'] ?? '',
      discountPercentage: json['discount_percentage'] ?? '',
      finalPrice: json['final_price'] ?? '',
      isInStock: json['is_in_stock'] ?? false,
      isActive: json['is_active'] ?? false,
      productName: json['product_name'] ?? '',
      productDescription: json['product_description'] ?? '',
      productCategory: json['product_category'] ?? '',
      productImages:
          (json['product_images'] as List?)
              ?.map((img) => ProductImage.fromJson(img))
              .toList() ??
          [],
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
  final String? deliveryCharges;
  final String? expectedDeliveryDate;
  final List<OrderProduct> products;
  final ShippingDetails? shippingDetails;

  Order({
    this.deliveryCharges,
    this.expectedDeliveryDate,
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
      deliveryCharges: json['delivery_charges']?.toString(),
      expectedDeliveryDate: json['expected_delivery_date']?.toString(),
      products:
          (json['items'] as List?)
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
    String? deliveryCharges,
    String? expectedDeliveryDate,
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
      deliveryCharges: deliveryCharges ?? this.deliveryCharges,
      expectedDeliveryDate: expectedDeliveryDate ?? this.expectedDeliveryDate,
      itemsCount: itemsCount,
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
      'delivery_address': shippingAddress,
      'delivery_city': shippingCity,
      'delivery_state': shippingState,
      'delivery_pincode': shippingPincode,
      'delivery_phone': shippingPhone,
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
