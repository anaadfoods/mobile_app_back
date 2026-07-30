import 'package:grocery_app/models/cart_model.dart';

abstract class CartRepository {
  Future<CartModel> getCart();
  Future<CartModel> addToCart(int productVariantId, int quantity);
  Future<CartModel> updateCartItem(int productVariantId, int quantity);
  Future<CartModel> removeFromCart(int productVariantId);
  Future<CartModel> clearCart();
}
