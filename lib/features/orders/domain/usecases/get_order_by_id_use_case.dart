import '../entities/order_entity.dart';
import '../repositories/orders_repository.dart';

class GetOrderByIdUseCase {
  final OrdersRepository _repository;

  GetOrderByIdUseCase(this._repository);

  Future<OrderEntity> call(int orderId) {
    return _repository.getOrderById(orderId);
  }
}
