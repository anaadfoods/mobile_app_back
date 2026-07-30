import '../entities/order_entity.dart';
import '../repositories/orders_repository.dart';

class GetOrdersUseCase {
  final OrdersRepository _repository;

  GetOrdersUseCase(this._repository);

  Future<List<OrderEntity>> call() async {
    final orders = await _repository.getOrders();
    
    // Explicitly filter out unpaid UPI orders, replicating legacy order_repository.dart behavior
    return orders.where((order) {
      if (order.paymentMethod.toUpperCase() == 'UPI') {
        final status = order.paymentStatus.toUpperCase();
        if (status == 'PAYMENT_PENDING' ||
            status == 'PENDING' ||
            status == 'FAILED') {
          return false;
        }
      }
      return true;
    }).toList();
  }
}
