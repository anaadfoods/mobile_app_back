import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grocery_app/models/order_model.dart';
import 'package:grocery_app/repositories/order_repository.dart';
import 'package:grocery_app/cubits/order/order_state.dart';

class OrderCubit extends Cubit<OrderState> {
  final OrderRepository _orderRepository;

  OrderCubit({required OrderRepository orderRepository})
      : _orderRepository = orderRepository,
        super(OrderInitial());

  /// Fetches the user's entire order history.
  Future<void> fetchOrders() async {
    try {
      emit(OrderLoading());
      final orders = await _orderRepository.getOrders();
      emit(OrderSuccess(orders: orders));
    } on OrderException catch (e) {
      emit(OrderError(e.message));
    } catch (_) {
      emit(const OrderError('An unexpected error occurred while fetching your orders.'));
    }
  }

  /// Clears the orders when user logs out
  void clearOrders() {
    emit(OrderInitial());
  }

  /// Fetches the details of a single order and updates the state.
  Future<void> fetchOrderDetails(int orderId) async {
    final currentState = state;
    List<Order> existingOrders = [];
    if (currentState is OrderSuccess) {
      existingOrders = currentState.orders;
    }
    
    try {
      emit(OrderLoading());
      final orderDetails = await _orderRepository.getOrderById(orderId);
      emit(OrderSuccess(orders: existingOrders, selectedOrderDetails: orderDetails));
    } on OrderException catch (e) {
      emit(OrderError(e.message));
    } catch (_) {
      emit(const OrderError('Failed to load order details.'));
    }
  }

  /// Creates a new order using the `OrderModel` payload.
  Future<void> createOrder(OrderModel order) async {
    try {
      emit(OrderLoading());
      final response = await _orderRepository.createOrder(order);
      emit(OrderPlacementSuccess(response));
      // After placing, refresh the order list in the background
      await fetchOrders();
    } on OrderException catch (e) {
      emit(OrderError(e.message));
    } catch (_) {
      emit(const OrderError('An unexpected error occurred while placing your order.'));
    }
  }

  /// Cancels an order and refreshes the order list.
  Future<Map<String, dynamic>?> cancelOrder(int orderId, {String? reason}) async {
    try {
      emit(OrderLoading());
      final result = await _orderRepository.cancelOrder(orderId, reason: reason);
      final msg = result['message'] ?? 'Your order cancellation request has been submitted.';
      emit(OrderActionSuccess(msg));
      await fetchOrders();
      return result;
    } on OrderException catch (e) {
      emit(OrderError(e.message));
      return null;
    } catch (_) {
      emit(const OrderError('Failed to cancel the order.'));
      return null;
    }
  }

  /// Downloads an invoice. Emits a transient state on success.
  Future<void> downloadInvoice(String orderNumber) async {
    try {
      // The UI can show a local loading indicator instead of a full-screen one.
      final filePath = await _orderRepository.downloadInvoice(orderNumber);
      emit(OrderActionSuccess('Invoice saved to $filePath'));
    } on OrderException catch (e) {
      emit(OrderError(e.message));
    } catch (_) {
      emit(const OrderError('Failed to download the invoice.'));
    }
  }
}