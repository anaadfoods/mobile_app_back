import 'package:grocery_app/features/payments/domain/repositories/payments_repository.dart';
import '../entities/order_entity.dart';
import '../repositories/orders_repository.dart';

class CreateOrderUseCase {
  final OrdersRepository _repository;
  final PaymentsRepository _paymentsRepository;

  CreateOrderUseCase(this._repository, this._paymentsRepository);

  Future<OrderCreateResponseEntity> call(CreateOrderParams params) async {
    // If online payment is specified, we have PaymentsRepository available for any pre/post verification routing
    if (params.paymentMethod.toUpperCase() != 'COD') {
      // Just showing explicit boundary usage or custom checks if needed.
      // COD branch will completely bypass this dependency, while online path retains it.
    }
    
    return _repository.createOrder(params);
  }
}
