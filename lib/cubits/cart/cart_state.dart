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

class CartItemSyncStatus extends Equatable {
  final int displayedQuantity;
  final int confirmedQuantity;
  final int pendingQuantity;
  final bool isSyncing;
  final bool requestInFlight;
  final String? error;

  const CartItemSyncStatus({
    required this.displayedQuantity,
    required this.confirmedQuantity,
    required this.pendingQuantity,
    required this.isSyncing,
    required this.requestInFlight,
    this.error,
  });

  CartItemSyncStatus copyWith({
    int? displayedQuantity,
    int? confirmedQuantity,
    int? pendingQuantity,
    bool? isSyncing,
    bool? requestInFlight,
    String? error,
  }) {
    return CartItemSyncStatus(
      displayedQuantity: displayedQuantity ?? this.displayedQuantity,
      confirmedQuantity: confirmedQuantity ?? this.confirmedQuantity,
      pendingQuantity: pendingQuantity ?? this.pendingQuantity,
      isSyncing: isSyncing ?? this.isSyncing,
      requestInFlight: requestInFlight ?? this.requestInFlight,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
        displayedQuantity,
        confirmedQuantity,
        pendingQuantity,
        isSyncing,
        requestInFlight,
        error,
      ];
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

  @override
  List<Object?> get props => [cart, message, error, itemStatuses];
}

class CartError extends CartState {
  final String message;

  const CartError(this.message);

  @override
  List<Object?> get props => [message];
}
