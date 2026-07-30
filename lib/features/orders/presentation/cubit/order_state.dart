import 'package:equatable/equatable.dart';
import '../../domain/entities/order_entity.dart';

abstract class OrderState extends Equatable {
  const OrderState();

  @override
  List<Object?> get props => [];
}

class OrderInitial extends OrderState {}

class OrderLoading extends OrderState {}

class OrderSuccess extends OrderState {
  final List<OrderEntity> orders;
  final OrderEntity? selectedOrderDetails;

  const OrderSuccess({
    this.orders = const [],
    this.selectedOrderDetails,
  });

  OrderSuccess copyWith({
    List<OrderEntity>? orders,
    OrderEntity? selectedOrderDetails,
  }) {
    return OrderSuccess(
      orders: orders ?? this.orders,
      selectedOrderDetails: selectedOrderDetails ?? this.selectedOrderDetails,
    );
  }

  @override
  List<Object?> get props => [orders, selectedOrderDetails];
}

class OrderPlacementSuccess extends OrderState {
  final OrderCreateResponseEntity response;
  const OrderPlacementSuccess(this.response);

  @override
  List<Object?> get props => [response];
}

class OrderActionSuccess extends OrderState {
  final String message;
  const OrderActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class OrderError extends OrderState {
  final String message;
  const OrderError(this.message);

  @override
  List<Object?> get props => [message];
}
