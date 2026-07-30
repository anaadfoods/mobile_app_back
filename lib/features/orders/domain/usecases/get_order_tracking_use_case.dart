import '../entities/order_entity.dart';
import '../repositories/orders_repository.dart';

class GetOrderTrackingUseCase {
  final OrdersRepository _repository;

  GetOrderTrackingUseCase(this._repository);

  Future<OrderTrackingEntity?> call(String orderNumber) {
    return _repository.getOrderTracking(orderNumber);
  }
}
