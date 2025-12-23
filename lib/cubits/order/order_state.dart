import 'package:equatable/equatable.dart';
import '../../models/order_model.dart'; // Your provided model file

abstract class OrderState extends Equatable {
  const OrderState();

  @override
  List<Object?> get props => [];
}

class OrderInitial extends OrderState {}

class OrderLoading extends OrderState {}

/// The main success state holding the user's order data.
/// Correctly uses the `Order` model for both the list and the selected details.
class OrderSuccess extends OrderState {
  final List<Order> orders;
  final Order? selectedOrderDetails; // Corrected from OrderModel to Order

  const OrderSuccess({
    this.orders = const [],
    this.selectedOrderDetails,
  });

  OrderSuccess copyWith({
    List<Order>? orders,
    Order? selectedOrderDetails, // Corrected from OrderModel to Order
  }) {
    return OrderSuccess(
      orders: orders ?? this.orders,
      selectedOrderDetails: selectedOrderDetails ?? this.selectedOrderDetails,
    );
  }

  @override
  List<Object?> get props => [orders, selectedOrderDetails];
}

/// A transient state for when an order is created successfully.
/// This is used by BlocListener to trigger navigation to a payment page or success screen.
class OrderPlacementSuccess extends OrderState {
  final OrderCreateResponse response;
  const OrderPlacementSuccess(this.response);
  @override
  List<Object?> get props => [response];
}

/// A transient state for successful actions like canceling an order or downloading an invoice.
/// This is used by BlocListener to show a confirmation message (e.g., a SnackBar).
class OrderActionSuccess extends OrderState {
  final String message;
  const OrderActionSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

/// State for any error that occurs during order operations.
class OrderError extends OrderState {
  final String message;
  const OrderError(this.message);
  @override
  List<Object?> get props => [message];
}