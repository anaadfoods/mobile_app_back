import '../entities/order_entity.dart';

/// Abstract repository interface for the orders feature.
///
/// This lives in the domain layer and must be pure Dart —
/// no Flutter, Dio, GetIt, or other third-party imports.
/// Implementations live in data/repositories/.
abstract class OrdersRepository {
  Future<List<OrderEntity>> getOrders();
  Future<OrderEntity> getOrderById(int orderId);
  Future<OrderCreateResponseEntity> createOrder(CreateOrderParams params);
  Future<Map<String, dynamic>> cancelOrder(int orderId, {String? reason});
  Future<String> downloadInvoice(String orderNumber);
  Future<OrderTrackingEntity?> getOrderTracking(String orderNumber);
  Future<ShippingDetailsEntity?> getUserShippingDetails();
}
