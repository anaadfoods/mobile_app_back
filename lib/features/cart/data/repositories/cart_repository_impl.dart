import 'package:grocery_app/models/cart_model.dart';
import '../../domain/failures/cart_failure.dart';
import '../../domain/repositories/cart_repository.dart';
import '../datasources/cart_remote_data_source.dart';

class CartRepositoryImpl implements CartRepository {
  final CartRemoteDataSource _remoteDataSource;

  CartRepositoryImpl(this._remoteDataSource);

  @override
  Future<CartModel> getCart() => _wrapException(() => _remoteDataSource.getCart());

  @override
  Future<CartModel> addToCart(int productVariantId, int quantity) =>
      _wrapException(() => _remoteDataSource.addToCart(productVariantId, quantity));

  @override
  Future<CartModel> updateCartItem(int productVariantId, int quantity) =>
      _wrapException(() => _remoteDataSource.updateCartItem(productVariantId, quantity));

  @override
  Future<CartModel> removeFromCart(int productVariantId) =>
      _wrapException(() => _remoteDataSource.removeFromCart(productVariantId));

  @override
  Future<CartModel> clearCart() =>
      _wrapException(() => _remoteDataSource.clearCart());

  Future<T> _wrapException<T>(Future<T> Function() call) async {
    try {
      return await call();
    } catch (e) {
      throw _parseException(e);
    }
  }

  CartFailure _parseException(dynamic e) {
    final text = e.toString().toLowerCase();

    // Check auth errors
    if (text.contains('401') || text.contains('unauthorized') || text.contains('session')) {
      return const CartFailure(
        type: CartFailureType.unauthorized,
        message: 'Please log in again to continue.',
      );
    }

    // Check network errors
    if (text.contains('timeout') ||
        text.contains('timed out') ||
        text.contains('socketexception') ||
        text.contains('connection refused') ||
        text.contains('network is unreachable') ||
        text.contains('clientexception') ||
        text.contains('500') ||
        text.contains('502') ||
        text.contains('503') ||
        text.contains('server error') ||
        text.contains('internal') ||
        text.contains('dioexception')) {
      return const CartFailure(
        type: CartFailureType.network,
        message: 'Sorry, we are not available right now. Please try again later.',
      );
    }

    // Try to extract validation message
    final match = RegExp(r'"message"\s*:\s*"([^"]+)"').firstMatch(e.toString());
    if (match != null) {
      return CartFailure(
        type: CartFailureType.validation,
        message: match.group(1)!,
      );
    }

    // Extract basic exception message if it doesn't match above patterns
    final exceptionMsg = e.toString().replaceFirst('Exception: ', '');
    return CartFailure(
      type: CartFailureType.unknown,
      message: exceptionMsg.isNotEmpty
          ? exceptionMsg
          : 'Sorry, we are not available right now. Please try again later.',
    );
  }
}
