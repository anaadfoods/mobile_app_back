import 'package:grocery_app/models/cart_model.dart';
import '../repositories/cart_repository.dart';

class RemoveFromCartUseCase {
  final CartRepository _repository;

  const RemoveFromCartUseCase(this._repository);

  Future<CartModel> call(int productVariantId) =>
      _repository.removeFromCart(productVariantId);
}
