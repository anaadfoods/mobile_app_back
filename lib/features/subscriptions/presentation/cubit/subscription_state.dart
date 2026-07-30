import 'package:equatable/equatable.dart';
import '../../domain/entities/subscription_entity.dart';
import '../../domain/entities/subscription_plan_entity.dart';
import '../../domain/repositories/subscriptions_repository.dart';

abstract class SubscriptionState extends Equatable {
  const SubscriptionState();
  @override
  List<Object?> get props => [];
}

class SubscriptionInitial extends SubscriptionState {}

class SubscriptionLoading extends SubscriptionState {}

class SubscriptionRepaymentInitiated extends SubscriptionState {
  final Map<String, dynamic> paymentData;
  const SubscriptionRepaymentInitiated(this.paymentData);

  @override
  List<Object?> get props => [paymentData];
}

class SubscriptionSuccess extends SubscriptionState {
  final List<SubscriptionPlanEntity> plans;
  final List<SubscriptionEntity> userSubscriptions;
  final SubscriptionEntity? selectedSubscription;
  final SubscriptionInvoiceResponse? invoices;
  final List<PlanSearchResultEntity> planSearchResults;
  final Map<int, List<SubscriptionPlanProductEntity>> planProducts;
  final Set<int> loadingProductPlanIds;

  const SubscriptionSuccess({
    this.plans = const [],
    this.userSubscriptions = const [],
    this.selectedSubscription,
    this.invoices,
    this.planSearchResults = const [],
    this.planProducts = const {},
    this.loadingProductPlanIds = const {},
  });

  SubscriptionSuccess copyWith({
    List<SubscriptionPlanEntity>? plans,
    List<SubscriptionEntity>? userSubscriptions,
    SubscriptionEntity? selectedSubscription,
    SubscriptionInvoiceResponse? invoices,
    List<PlanSearchResultEntity>? planSearchResults,
    Map<int, List<SubscriptionPlanProductEntity>>? planProducts,
    Set<int>? loadingProductPlanIds,
  }) {
    return SubscriptionSuccess(
      plans: plans ?? this.plans,
      userSubscriptions: userSubscriptions ?? this.userSubscriptions,
      selectedSubscription:
          selectedSubscription ?? this.selectedSubscription,
      invoices: invoices ?? this.invoices,
      planSearchResults: planSearchResults ?? this.planSearchResults,
      planProducts: planProducts ?? this.planProducts,
      loadingProductPlanIds:
          loadingProductPlanIds ?? this.loadingProductPlanIds,
    );
  }

  @override
  List<Object?> get props => [
        plans,
        userSubscriptions,
        selectedSubscription,
        invoices,
        planSearchResults,
        planProducts,
        loadingProductPlanIds,
      ];
}

class SubscriptionCreated extends SubscriptionState {
  final Map<String, dynamic> paymentLinks;
  final int subscriptionId;
  const SubscriptionCreated(this.paymentLinks, this.subscriptionId);
  @override
  List<Object?> get props => [paymentLinks, subscriptionId];
}

class SubscriptionActionSuccess extends SubscriptionState {
  final String message;
  const SubscriptionActionSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class SubscriptionError extends SubscriptionState {
  final String message;
  const SubscriptionError(this.message);
  @override
  List<Object?> get props => [message];
}
