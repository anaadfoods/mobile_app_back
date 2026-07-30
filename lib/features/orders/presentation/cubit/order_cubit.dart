import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/failures/order_failure.dart';
import '../../domain/usecases/get_orders_use_case.dart';
import '../../domain/usecases/get_order_by_id_use_case.dart';
import '../../domain/usecases/create_order_use_case.dart';
import '../../domain/usecases/cancel_order_use_case.dart';
import '../../domain/usecases/download_invoice_use_case.dart';
import 'order_state.dart';

class OrderCubit extends Cubit<OrderState> {
  final GetOrdersUseCase _getOrdersUseCase;
  final GetOrderByIdUseCase _getOrderByIdUseCase;
  final CreateOrderUseCase _createOrderUseCase;
  final CancelOrderUseCase _cancelOrderUseCase;
  final DownloadInvoiceUseCase _downloadInvoiceUseCase;

  OrderCubit({
    required GetOrdersUseCase getOrdersUseCase,
    required GetOrderByIdUseCase getOrderByIdUseCase,
    required CreateOrderUseCase createOrderUseCase,
    required CancelOrderUseCase cancelOrderUseCase,
    required DownloadInvoiceUseCase downloadInvoiceUseCase,
  })  : _getOrdersUseCase = getOrdersUseCase,
        _getOrderByIdUseCase = getOrderByIdUseCase,
        _createOrderUseCase = createOrderUseCase,
        _cancelOrderUseCase = cancelOrderUseCase,
        _downloadInvoiceUseCase = downloadInvoiceUseCase,
        super(OrderInitial());

  /// Fetches the user's entire order history.
  Future<void> fetchOrders() async {
    try {
      emit(OrderLoading());
      final orders = await _getOrdersUseCase();
      emit(OrderSuccess(orders: orders));
    } on OrderFailure catch (e) {
      emit(OrderError(e.message));
    } catch (_) {
      emit(const OrderError('An unexpected error occurred while fetching your orders.'));
    }
  }

  /// Clears the orders when user logs out.
  void clearOrders() {
    emit(OrderInitial());
  }

  /// Fetches the details of a single order and updates the state.
  Future<void> fetchOrderDetails(int orderId) async {
    final currentState = state;
    List<OrderEntity> existingOrders = [];
    if (currentState is OrderSuccess) {
      existingOrders = currentState.orders;
    }

    try {
      emit(OrderLoading());
      final orderDetails = await _getOrderByIdUseCase(orderId);
      emit(OrderSuccess(
        orders: existingOrders,
        selectedOrderDetails: orderDetails,
      ));
    } on OrderFailure catch (e) {
      emit(OrderError(e.message));
    } catch (_) {
      emit(const OrderError('Failed to load order details.'));
    }
  }

  /// Fetches the details of a single order using its order number.
  /// Useful when payment gateways only return the reference number.
  Future<void> fetchOrderDetailsByNumber(String orderNumber) async {
    final currentState = state;
    List<OrderEntity> existingOrders = [];
    if (currentState is OrderSuccess) {
      existingOrders = currentState.orders;
    }

    try {
      emit(OrderLoading());
      
      List<OrderEntity> orders = existingOrders;
      if (orders.isEmpty) {
        orders = await _getOrdersUseCase();
      }
      
      final matchingOrder = orders.firstWhere((o) => o.orderNumber == orderNumber);
      final orderDetails = await _getOrderByIdUseCase(matchingOrder.id);
      
      emit(OrderSuccess(
        orders: orders,
        selectedOrderDetails: orderDetails,
      ));
    } on StateError {
      emit(const OrderError('Order not found.'));
    } catch (_) {
      emit(const OrderError('Failed to load order details.'));
    }
  }

  /// Creates a new order using the parameters.
  Future<void> createOrder(CreateOrderParams params) async {
    try {
      emit(OrderLoading());
      final response = await _createOrderUseCase(params);
      emit(OrderPlacementSuccess(response));
      // After placing, refresh the order list in the background
      await fetchOrders();
    } on OrderFailure catch (e) {
      emit(OrderError(e.message));
    } catch (_) {
      emit(const OrderError('An unexpected error occurred while placing your order.'));
    }
  }

  /// Cancels an order and refreshes the order list.
  Future<Map<String, dynamic>?> cancelOrder(int orderId, {String? reason}) async {
    try {
      emit(OrderLoading());
      final result = await _cancelOrderUseCase(orderId, reason: reason);
      final msg = result['message'] ?? 'Your order cancellation request has been submitted.';
      emit(OrderActionSuccess(msg));
      await fetchOrders();
      return result;
    } on OrderFailure catch (e) {
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
      final filePath = await _downloadInvoiceUseCase(orderNumber);
      emit(OrderActionSuccess('Invoice saved to $filePath'));
    } on OrderFailure catch (e) {
      emit(OrderError(e.message));
    } catch (_) {
      emit(const OrderError('Failed to download the invoice.'));
    }
  }
}
