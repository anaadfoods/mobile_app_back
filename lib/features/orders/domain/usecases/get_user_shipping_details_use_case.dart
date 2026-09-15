import '../entities/order_entity.dart';
import '../repositories/orders_repository.dart';

class GetUserShippingDetailsUseCase {
  final OrdersRepository _repository;

  GetUserShippingDetailsUseCase(this._repository);

  Future<ShippingDetailsEntity?> call() {
    return _repository.getUserShippingDetails();
  }
}
