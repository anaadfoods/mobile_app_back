import '../repositories/orders_repository.dart';

class CancelOrderUseCase {
  final OrdersRepository _repository;

  CancelOrderUseCase(this._repository);

  Future<Map<String, dynamic>> call(int orderId, {String? reason}) {
    return _repository.cancelOrder(orderId, reason: reason);
  }
}
