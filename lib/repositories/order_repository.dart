import '../models/order_model.dart'; // Your provided model file
import '../services/auth_service.dart';
import '../services/order_service.dart';

/// A custom exception for handling order-related errors.
class OrderException implements Exception {
  final String message;
  OrderException(this.message);

  @override
  String toString() => message;
}

class OrderRepository {
  final OrderService _orderService;
  final AuthService _authService;

  OrderRepository({OrderService? orderService, AuthService? authService})
      : _orderService = orderService ?? OrderService(),
        _authService = authService ?? AuthService();

  /// A private helper to wrap authenticated API calls and handle token refresh logic.
  Future<T> _makeAuthenticatedRequest<T>(Future<T> Function() apiCall) async {
    try {
      final isAuthenticated = await _authService.isLoggedIn();
      if (!isAuthenticated) {
        throw OrderException('You must be logged in to manage your orders.');
      }
      return await apiCall();
    } on Exception catch (e) {
      if (e.toString().contains('Authentication failed') || e.toString().contains('401')) {
        final refreshed = await _authService.refreshAccessToken();
        if (refreshed) {
          // Retry the original API call once after a successful token refresh
          return await apiCall();
        } else {
          throw OrderException('Your session has expired. Please log in again.');
        }
      }
      // Re-throw other custom exceptions or general errors
      rethrow;
    }
  }

  /// Fetches a list of orders. Correctly returns `List<Order>`.
  Future<List<Order>> getOrders() async {
    // The service method returns List<Order>, which is what we need.
    return _makeAuthenticatedRequest(() => _orderService.getOrders());
  }

  /// Fetches details for a single order. Corrected to return `Order`.
  Future<Order> getOrderById(int orderId) async {
    // NOTE: Your service's getOrderById returns OrderModel. Ideally, it should return the more
    // detailed `Order` object for consistency. If you cannot change the service,
    // you would have to map the `OrderModel` response to an `Order` object here.
    // For this implementation, we assume the service can be corrected to return `Order`.
    // If not, you can cast it like this: `return await _orderService.getOrderById(orderId) as Order;`
    // but that is not safe. Let's assume the service call is consistent.
    final orderModel = await _makeAuthenticatedRequest(() => _orderService.getOrderById(orderId));
    // This is a temporary conversion. Ideally, the API should return the `Order` object directly.
    return Order.fromJson(orderModel.toJson()); // A safe-guard conversion
  }

  /// Creates an order using the `OrderModel` payload.
  /// Correctly returns the `OrderCreateResponse` with payment links.
  Future<OrderCreateResponse> createOrder(OrderModel order) async {
    final dynamic response = await _makeAuthenticatedRequest(() => _orderService.createOrder(order));
    
    // Your service can return different types, so we handle them safely.
    if (response is OrderCreateResponse) {
      return response;
    }
    // Handle cases like Cash on Delivery where only the created order model is returned.
    if (response is OrderModel && response.orderNumber != null) {
      return OrderCreateResponse(
        success: true, 
        orderId: response.orderNumber, // Use order number if available
        paymentLinks: null // No payment links for COD
      );
    }
    throw OrderException('Failed to create order due to an unknown response type.');
  }

  /// Cancels an order. Returns void on success.
  Future<void> cancelOrder(int orderId) async {
    await _makeAuthenticatedRequest(() => _orderService.cancelOrder(orderId));
  }

  /// Downloads an invoice PDF.
  Future<String> downloadInvoice(String orderNumber) async {
    return _makeAuthenticatedRequest(() => _orderService.downloadOrderInvoice(orderNumber));
  }
}