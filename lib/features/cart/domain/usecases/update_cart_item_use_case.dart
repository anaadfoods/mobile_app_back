import 'package:grocery_app/models/cart_model.dart';
import '../repositories/cart_repository.dart';

class UpdateCartItemUseCase {
  final CartRepository _repository;

  const UpdateCartItemUseCase(this._repository);

  Future<CartModel> call(int productVariantId, int quantity) =>
      _repository.updateCartItem(productVariantId, quantity);
}
