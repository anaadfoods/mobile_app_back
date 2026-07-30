import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:grocery_app/services/token_service.dart';

abstract class CartRemoteDataSource {
  Future<CartModel> getCart();
  Future<CartModel> addToCart(int productVariantId, int quantity);
  Future<CartModel> updateCartItem(int productVariantId, int quantity);
  Future<CartModel> removeFromCart(int productVariantId);
  Future<CartModel> clearCart();
}

class CartRemoteDataSourceImpl implements CartRemoteDataSource {
  static const String getCartEndpoint = '/api/cart/details/';
  static const String addCartItemEndpoint = '/api/cart/items/add/';
  static const String updateCartItemEndpoint = '/api/cart/items/update/';
  static const String removeItemEndpoint = '/api/cart/items/remove/';
  static const String clearCartEndpoint = '/api/cart/clear/';

  final TokenService _tokenService;

  CartRemoteDataSourceImpl({TokenService? tokenService})
      : _tokenService = tokenService ?? getIt<TokenService>();

  Future<void> _ensureAuth() async {
    if (!await _tokenService.isLoggedIn()) {
      throw Exception('User not authenticated');
    }
  }

  @override
  Future<CartModel> getCart() async {
    await _ensureAuth();
    final response = await ApiClient.instance.get(getCartEndpoint);
    if (response.statusCode == 200) {
      return CartModel.fromJson(response.data);
    }
    throw Exception('Failed to load cart. Status: ${response.statusCode}');
  }

  @override
  Future<CartModel> addToCart(int productVariantId, int quantity) async {
    await _ensureAuth();
    final response = await ApiClient.instance.post(
      addCartItemEndpoint,
      data: {
        'product_variant_id': productVariantId,
        'quantity': quantity,
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return getCart();
    } else if (response.statusCode == 400) {
      final errorData = response.data;
      final message = errorData['message'] ??
          errorData['error'] ??
          'Item cannot be added. Check stock limits.';
      throw Exception(message);
    }
    throw Exception('Failed to add item. Status: ${response.statusCode}');
  }

  @override
  Future<CartModel> updateCartItem(int productVariantId, int quantity) async {
    await _ensureAuth();
    final response = await ApiClient.instance.post(
      updateCartItemEndpoint,
      data: {
        'product_variant_id': productVariantId,
        'quantity': quantity,
      },
    );

    if (response.statusCode == 200) {
      return getCart();
    } else if (response.statusCode == 400) {
      final errorData = response.data;
      final message = errorData['message'] ??
          errorData['error'] ??
          'Only limited items left in stock';
      throw Exception(message);
    }
    throw Exception('Failed to update item. Status: ${response.statusCode}');
  }

  @override
  Future<CartModel> removeFromCart(int productVariantId) async {
    await _ensureAuth();
    final response = await ApiClient.instance.post(
      removeItemEndpoint,
      data: {'product_variant_id': productVariantId},
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      return getCart();
    }
    throw Exception('Failed to remove item. Status: ${response.statusCode}');
  }

  @override
  Future<CartModel> clearCart() async {
    await _ensureAuth();
    final response = await ApiClient.instance.post(clearCartEndpoint);

    if (response.statusCode == 200 || response.statusCode == 204) {
      return getCart();
    }
    throw Exception('Failed to clear cart. Status: ${response.statusCode}');
  }
}
