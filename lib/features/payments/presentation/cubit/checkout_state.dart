import 'package:equatable/equatable.dart';
import 'package:grocery_app/models/order_model.dart' hide ShippingDetails;
import 'package:grocery_app/models/shipping_details.dart';
import 'package:grocery_app/models/subscription_plan_model.dart';

abstract class CheckoutState extends Equatable {
  const CheckoutState();

  @override
  List<Object?> get props => [];
}

class CheckoutInitial extends CheckoutState {}

class CheckoutLoading extends CheckoutState {}

class CheckoutLoaded extends CheckoutState {
  final ShippingDetails? shippingDetails;
  final List<SubscriptionPlan> planDescriptions;
  final SubscriptionPlan? subscription;
  final int pendingRewardsCount;
  final String selectedPaymentMethod; // COD or UPI
  final String selectedPaymentType; // FULL, PAID_FULL or INSTALLMENT
  final bool useExistingAddress;
  final String? error;
  final bool isSubmitting;

  const CheckoutLoaded({
    this.shippingDetails,
    this.planDescriptions = const [],
    this.subscription,
    this.pendingRewardsCount = 0,
    this.selectedPaymentMethod = 'COD',
    this.selectedPaymentType = 'FULL',
    this.useExistingAddress = true,
    this.error,
    this.isSubmitting = false,
  });

  CheckoutLoaded copyWith({
    ShippingDetails? Function()? shippingDetails,
    List<SubscriptionPlan>? planDescriptions,
    SubscriptionPlan? Function()? subscription,
    int? pendingRewardsCount,
    String? selectedPaymentMethod,
    String? selectedPaymentType,
    bool? useExistingAddress,
    String? Function()? error,
    bool? isSubmitting,
  }) {
    return CheckoutLoaded(
      shippingDetails:
          shippingDetails != null ? shippingDetails() : this.shippingDetails,
      planDescriptions: planDescriptions ?? this.planDescriptions,
      subscription: subscription != null ? subscription() : this.subscription,
      pendingRewardsCount: pendingRewardsCount ?? this.pendingRewardsCount,
      selectedPaymentMethod:
          selectedPaymentMethod ?? this.selectedPaymentMethod,
      selectedPaymentType: selectedPaymentType ?? this.selectedPaymentType,
      useExistingAddress: useExistingAddress ?? this.useExistingAddress,
      error: error != null ? error() : this.error,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }

  @override
  List<Object?> get props => [
        shippingDetails,
        planDescriptions,
        subscription,
        pendingRewardsCount,
        selectedPaymentMethod,
        selectedPaymentType,
        useExistingAddress,
        error,
        isSubmitting,
      ];
}

class CheckoutSuccess extends CheckoutState {
  final Map<String, dynamic> result;
  final bool isSubscription;

  const CheckoutSuccess({required this.result, required this.isSubscription});

  @override
  List<Object?> get props => [result, isSubscription];
}

class CheckoutFailure extends CheckoutState {
  final String errorMessage;

  const CheckoutFailure(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}
