import 'package:grocery_app/models/cart_model.dart';
import '../repositories/cart_repository.dart';

class GetCartUseCase {
  final CartRepository _repository;

  const GetCartUseCase(this._repository);

  Future<CartModel> call() => _repository.getCart();
}
