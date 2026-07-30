import 'package:grocery_app/features/products/domain/entities/product_entity.dart';

class ShippingDetailsEntity {
  final String address;
  final String name;
  final String city;
  final String state;
  final String pincode;
  final String phone;

  const ShippingDetailsEntity({
    required this.address,
    required this.name,
    required this.city,
    required this.state,
    required this.pincode,
    required this.phone,
  });

  bool get isComplete =>
      address.isNotEmpty &&
      city.isNotEmpty &&
      state.isNotEmpty &&
      pincode.isNotEmpty &&
      phone.isNotEmpty;
}

class OrderItemEntity {
  final ProductEntity productDetails;
  final int quantity;
  final double price;
  final double discount;
  final double total;

  const OrderItemEntity({
    required this.productDetails,
    required this.quantity,
    required this.price,
    required this.discount,
    required this.total,
  });
}

class OrderEntity {
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
  final String recipientName;
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
  final List<OrderItemEntity> items;

  const OrderEntity({
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
    required this.recipientName,
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
}

class OrderCreateResponseEntity {
  final bool success;
  final String? orderNumber;
  final String? checkoutUrl;
  final String? accessKey;
  final String? merchantTransactionId;
  final bool paymentRequired;
  final String? message;
  final OrderEntity? order;
  final int? orderId;

  const OrderCreateResponseEntity({
    required this.success,
    this.orderNumber,
    this.checkoutUrl,
    this.accessKey,
    this.merchantTransactionId,
    this.paymentRequired = false,
    this.message,
    this.order,
    this.orderId,
  });
}

class TrackingEventEntity {
  final String activity;
  final String location;
  final DateTime timestamp;
  final String status;

  const TrackingEventEntity({
    required this.activity,
    required this.location,
    required this.timestamp,
    required this.status,
  });
}

class OrderTrackingEntity {
  final int id;
  final int order;
  final int? subscription;
  final String orderNumber;
  final String? subscriptionNumber;
  final String orderStatus;
  final String? awbNumber;
  final DateTime? estimatedDelivery;
  final DateTime? pickupScheduledAt;
  final String status;
  final List<TrackingEventEntity> trackingEvents;

  const OrderTrackingEntity({
    required this.id,
    required this.order,
    this.subscription,
    required this.orderNumber,
    this.subscriptionNumber,
    required this.orderStatus,
    this.awbNumber,
    this.estimatedDelivery,
    this.pickupScheduledAt,
    required this.status,
    required this.trackingEvents,
  });
}

class CreateOrderParams {
  final String paymentMethod;
  final String shippingAddress;
  final String shippingCity;
  final String shippingState;
  final String shippingPincode;
  final String shippingPhone;
  final String shippingName;
  final List<CreateOrderItemParams> items;
  final String? notes;

  const CreateOrderParams({
    required this.paymentMethod,
    required this.shippingAddress,
    required this.shippingCity,
    required this.shippingState,
    required this.shippingPincode,
    required this.shippingPhone,
    required this.shippingName,
    required this.items,
    this.notes,
  });
}

class CreateOrderItemParams {
  final int productVariantId;
  final int quantity;

  const CreateOrderItemParams({
    required this.productVariantId,
    required this.quantity,
  });
}
