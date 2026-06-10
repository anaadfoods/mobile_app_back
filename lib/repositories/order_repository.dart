import '../models/order_model.dart';
import '../services/token_service.dart';
import '../services/order_service.dart';
import 'package:grocery_app/service_locator.dart';

class OrderException implements Exception {
  final String message;
  OrderException(this.message);

  @override
  String toString() => message;
}


class OrderRepository {
  final OrderService _orderService;
  final TokenService _tokenService;

  OrderRepository({OrderService? orderService, TokenService? tokenService})
      : _orderService = orderService ?? getIt<OrderService>(),
        _tokenService = tokenService ?? getIt<TokenService>();

  Future<void> _checkAuth() async {
    final isAuthenticated = await _tokenService.isLoggedIn();
    if (!isAuthenticated) {
      throw OrderException('You must be logged in to manage your orders.');
    }
  }

  Future<List<Order>> getOrders() async {
    await _checkAuth();
    final orders = await _orderService.getOrders();

    return orders.where((order) {
      if (order.paymentMethod.toUpperCase() == 'UPI') {
        final status = order.paymentStatus.toUpperCase();
        if (status == 'PAYMENT_PENDING' || status == 'PENDING' || status == 'FAILED') {
          return false;
        }
      }
      return true;
    }).toList();
  }

  Future<Order> getOrderById(int orderId) async {
    await _checkAuth();
    final orderModel = await _orderService.getOrderById(orderId);
    return Order.fromJson(orderModel.toJson());
  }

  Future<OrderCreateResponse> createOrder(OrderModel order) async {
    await _checkAuth();
    final dynamic response = await _orderService.createOrder(order);
    
    if (response is OrderCreateResponse) {
      return response;
    }
    if (response is OrderModel && response.orderNumber != null) {
      return OrderCreateResponse(
        success: true, 
        orderId: response.orderNumber,
        paymentLinks: null
      );
    }
    throw OrderException('Failed to create order due to an unknown response type.');
  }

  Future<void> cancelOrder(int orderId) async {
    await _checkAuth();
    await _orderService.cancelOrder(orderId);
  }

  Future<String> downloadInvoice(String orderNumber) async {
    await _checkAuth();
    return await _orderService.downloadOrderInvoice(orderNumber);
  }
}