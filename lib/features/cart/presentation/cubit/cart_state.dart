import 'package:equatable/equatable.dart';
import 'package:grocery_app/models/cart_model.dart';
import '../../domain/entities/cart_item_sync_status.dart';

abstract class CartState extends Equatable {
  const CartState();

  CartModel? get cart => null;

  @override
  List<Object?> get props => [cart];
}

class CartInitial extends CartState {
  const CartInitial();
}

class CartLoading extends CartState {
  const CartLoading();
}

class CartSuccess extends CartState {
  @override
  final CartModel cart;
  final String? message;
  final String? error;
  final Map<int, CartItemSyncStatus> itemStatuses;

  const CartSuccess(
    this.cart, {
    this.message,
    this.error,
    this.itemStatuses = const {},
  });

  CartSuccess copyWith({
    CartModel? cart,
    String? message,
    String? error,
    Map<int, CartItemSyncStatus>? itemStatuses,
  }) {
    return CartSuccess(
      cart ?? this.cart,
      message: message,
      error: error,
      itemStatuses: itemStatuses ?? this.itemStatuses,
    );
  }

  @override
  List<Object?> get props => [cart, message, error, itemStatuses];
}

class CartError extends CartState {
  final String message;

  const CartError(this.message);

  @override
  List<Object?> get props => [message];
}
