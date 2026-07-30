import 'package:equatable/equatable.dart';

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
