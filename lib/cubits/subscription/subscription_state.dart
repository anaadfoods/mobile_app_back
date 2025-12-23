import 'package:equatable/equatable.dart';
import 'package:grocery_app/models/plan_Search_model.dart';
import '../../models/subscription_invoice_model.dart';
import '../../models/subscription_model.dart';
import '../../models/subscription_plan_model.dart';
import '../../models/subscription_plan_product_model.dart';

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
  final List<SubscriptionPlan> plans;
  final List<Subscription> userSubscriptions;
  final Subscription? selectedSubscription;
  final ApiResponse? invoices;
  final List<PlanSearchResult> planSearchResults;

  // ++ FIX: Added missing properties to store products and their loading state ++
  final Map<int, List<SubscriptionPlanProduct>> planProducts;
  final Set<int> loadingProductPlanIds;

  const SubscriptionSuccess({
    this.plans = const [],
    this.userSubscriptions = const [],
    this.selectedSubscription,
    this.invoices,
    this.planSearchResults = const [],
    // ++ FIX: Initialize new properties ++
    this.planProducts = const {},
    this.loadingProductPlanIds = const {},
  });

  SubscriptionSuccess copyWith({
    List<SubscriptionPlan>? plans,
    List<Subscription>? userSubscriptions,
    Subscription? selectedSubscription,
    ApiResponse? invoices,
    List<PlanSearchResult>? planSearchResults,
    // ++ FIX: Add new properties to copyWith ++
    Map<int, List<SubscriptionPlanProduct>>? planProducts,
    Set<int>? loadingProductPlanIds,
  }) {
    return SubscriptionSuccess(
      plans: plans ?? this.plans,
      userSubscriptions: userSubscriptions ?? this.userSubscriptions,
      selectedSubscription: selectedSubscription ?? this.selectedSubscription,
      invoices: invoices ?? this.invoices,
      planSearchResults: planSearchResults ?? this.planSearchResults,
      // ++ FIX: Assign new properties in copyWith ++
      planProducts: planProducts ?? this.planProducts,
      loadingProductPlanIds: loadingProductPlanIds ?? this.loadingProductPlanIds,
    );
  }

  @override
  List<Object?> get props => [
        plans,
        userSubscriptions,
        selectedSubscription,
        invoices,
        planSearchResults,
        // ++ FIX: Add new properties to props for comparison ++
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