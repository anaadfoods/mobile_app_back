import 'package:grocery_app/models/cart_model.dart';
import '../repositories/cart_repository.dart';

class ClearCartUseCase {
  final CartRepository _repository;

  const ClearCartUseCase(this._repository);

  Future<CartModel> call() => _repository.clearCart();
}
