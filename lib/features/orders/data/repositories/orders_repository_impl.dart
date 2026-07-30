import 'package:grocery_app/features/products/data/repositories/products_repository_impl.dart';
import 'package:grocery_app/models/order_model.dart';
import 'package:grocery_app/models/order_tracking_model.dart';
import 'package:grocery_app/services/api_client.dart';
import 'package:grocery_app/services/api_exception.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/failures/order_failure.dart';
import '../../domain/repositories/orders_repository.dart';
import '../datasources/orders_remote_data_source.dart';

/// Implementation of [OrdersRepository].
///
/// Delegates to data sources, maps DTOs to domain entities,
/// and translates exceptions to domain failures.
class OrdersRepositoryImpl implements OrdersRepository {
  final OrdersRemoteDataSource _remoteDataSource;

  OrdersRepositoryImpl({required OrdersRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<List<OrderEntity>> getOrders() async {
    try {
      final orders = await _remoteDataSource.getOrders();
      return orders.map((o) => o.toDomain()).toList();
    } catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<OrderEntity> getOrderById(int orderId) async {
    try {
      final order = await _remoteDataSource.getOrderById(orderId);
      return order.toDomain();
    } catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<OrderCreateResponseEntity> createOrder(CreateOrderParams params) async {
    try {
      // Map CreateOrderParams to OrderModel DTO
      final dtoItems = params.items.map((i) => OrderItem(
        productVariantId: i.productVariantId,
        quantity: i.quantity,
      )).toList();

      final orderModel = OrderModel(
        paymentMethod: params.paymentMethod,
        shippingAddress: params.shippingAddress,
        shippingCity: params.shippingCity,
        shippingState: params.shippingState,
        shippingPincode: params.shippingPincode,
        shippingPhone: params.shippingPhone,
        shippingName: params.shippingName,
        items: dtoItems,
        notes: params.notes,
      );

      final response = await _remoteDataSource.createOrder(orderModel);

      if (response is OrderCreateResponse) {
        return OrderCreateResponseEntity(
          success: response.success,
          orderNumber: response.orderNumber,
          checkoutUrl: response.checkoutUrl,
          accessKey: response.accessKey,
          merchantTransactionId: response.merchantTransactionId,
          paymentRequired: response.paymentRequired,
          message: response.message,
          orderId: response.orderId,
        );
      } else if (response is Order) {
        return OrderCreateResponseEntity(
          success: true,
          orderNumber: response.orderNumber,
          order: response.toDomain(),
        );
      } else {
        throw const OrderFailure(
          type: OrderFailureType.unknown,
          message: 'Unexpected order placement response format.',
        );
      }
    } catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<Map<String, dynamic>> cancelOrder(int orderId, {String? reason}) async {
    try {
      return await _remoteDataSource.cancelOrder(orderId, reason: reason);
    } catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<String> downloadInvoice(String orderNumber) async {
    try {
      return await _remoteDataSource.downloadInvoice(orderNumber);
    } catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<OrderTrackingEntity?> getOrderTracking(String orderNumber) async {
    try {
      final tracking = await _remoteDataSource.getOrderTracking(orderNumber);
      return tracking?.toDomain();
    } catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<ShippingDetailsEntity?> getUserShippingDetails() async {
    try {
      final details = await _remoteDataSource.getUserShippingDetails();
      return details?.toDomain();
    } catch (e) {
      throw _mapException(e);
    }
  }

  Exception _mapException(dynamic error) {
    if (error is ApiException) {
      if (error.statusCode == 401) {
        return const OrderFailure(
          type: OrderFailureType.unauthorized,
          message: 'You must be logged in to manage your orders.',
        );
      }
      if (error.statusCode == 404) {
        return const OrderFailure(
          type: OrderFailureType.notFound,
          message: 'The requested order was not found.',
        );
      }
      return OrderFailure(
        type: OrderFailureType.unknown,
        message: error.message,
      );
    }
    final errString = error.toString();
    if (errString.contains('cancellation') || errString.contains('cancel')) {
      return OrderFailure(
        type: OrderFailureType.cancellationRejected,
        message: errString,
      );
    }
    return OrderFailure(
      type: OrderFailureType.unknown,
      message: errString,
    );
  }
}

extension ShippingDetailsMapper on ShippingDetails {
  ShippingDetailsEntity toDomain() {
    return ShippingDetailsEntity(
      address: address,
      name: name,
      city: city ?? '',
      state: state ?? '',
      pincode: pincode ?? '',
      phone: phone ?? '',
    );
  }
}

extension OrderItemMapper on OrderItemResponse {
  OrderItemEntity toDomain() {
    return OrderItemEntity(
      productDetails: productDetails.toDomain(),
      quantity: quantity,
      price: price,
      discount: discount,
      total: total,
    );
  }
}

extension OrderMapper on Order {
  OrderEntity toDomain() {
    return OrderEntity(
      id: id,
      orderNumber: orderNumber,
      status: status,
      paymentStatus: paymentStatus,
      paymentMethod: paymentMethod,
      paymentReference: paymentReference,
      deliveryAddress: deliveryAddress,
      deliveryCity: deliveryCity,
      deliveryState: deliveryState,
      deliveryPincode: deliveryPincode,
      deliveryPhone: deliveryPhone,
      recipientName: recipientName,
      subtotal: subtotal,
      tax: tax,
      deliveryCharges: deliveryCharges,
      discount: discount,
      total: total,
      createdAt: createdAt,
      updatedAt: updatedAt,
      expectedDeliveryDate: expectedDeliveryDate,
      isSubscriptionOrder: isSubscriptionOrder,
      isFirstOrder: isFirstOrder,
      hasReferralReward: hasReferralReward,
      notes: notes,
      items: items.map((item) => item.toDomain()).toList(),
    );
  }
}

extension TrackingEventMapper on TrackingEvent {
  TrackingEventEntity toDomain() {
    return TrackingEventEntity(
      activity: activity,
      location: location,
      timestamp: timestamp,
      status: status,
    );
  }
}

extension OrderTrackingMapper on OrderTracking {
  OrderTrackingEntity toDomain() {
    return OrderTrackingEntity(
      id: id,
      order: order,
      subscription: subscription,
      orderNumber: orderNumber,
      subscriptionNumber: subscriptionNumber,
      orderStatus: orderStatus,
      awbNumber: awbNumber,
      estimatedDelivery: estimatedDelivery,
      pickupScheduledAt: pickupScheduledAt,
      status: status,
      trackingEvents: trackingEvents.map((e) => e.toDomain()).toList(),
    );
  }
}
