import 'package:equatable/equatable.dart';
import '../../models/cart_model.dart';

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
  final CartModel cart;
  final String? message;
  final String? error;

  const CartSuccess(this.cart, {this.message, this.error});

  @override
  List<Object?> get props => [cart, message, error];
}

class CartError extends CartState {
  final String message;

  const CartError(this.message);

  @override
  List<Object?> get props => [message];
}
