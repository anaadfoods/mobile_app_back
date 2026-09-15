import 'package:grocery_app/models/cart_model.dart';
import '../repositories/cart_repository.dart';

class AddToCartUseCase {
  final CartRepository _repository;

  const AddToCartUseCase(this._repository);

  Future<CartModel> call(int productVariantId, int quantity) =>
      _repository.addToCart(productVariantId, quantity);
}
