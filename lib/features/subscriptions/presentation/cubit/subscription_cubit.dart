import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/subscription_entity.dart';
import '../../domain/entities/subscription_plan_entity.dart';
import '../../domain/failures/subscription_failure.dart';
import '../../domain/repositories/subscriptions_repository.dart';
import '../../domain/usecases/get_user_subscriptions_use_case.dart';
import '../../domain/usecases/get_subscription_details_use_case.dart';
import '../../domain/usecases/get_subscription_plans_use_case.dart';
import '../../domain/usecases/create_subscription_use_case.dart';
import '../../domain/usecases/cancel_subscription_use_case.dart';
import '../../domain/usecases/toggle_pause_subscription_use_case.dart';
import '../../domain/usecases/repayment_subscription_use_case.dart';
import '../../domain/usecases/get_subscription_invoices_use_case.dart';
import '../../domain/usecases/get_subscription_plan_products_use_case.dart';
import '../../domain/usecases/search_plans_for_variant_use_case.dart';
import 'subscription_state.dart';

class SubscriptionCubit extends Cubit<SubscriptionState> {
  final GetUserSubscriptionsUseCase _getUserSubscriptions;
  final GetSubscriptionDetailsUseCase _getSubscriptionDetails;
  final GetSubscriptionPlansUseCase _getSubscriptionPlans;
  final CreateSubscriptionUseCase _createSubscription;
  final CancelSubscriptionUseCase _cancelSubscription;
  final TogglePauseSubscriptionUseCase _togglePause;
  final RepaymentSubscriptionUseCase _repayment;
  final GetSubscriptionInvoicesUseCase _getInvoices;
  final GetSubscriptionPlanProductsUseCase _getPlanProducts;
  final SearchPlansForVariantUseCase _searchPlans;

  SubscriptionCubit({
    required GetUserSubscriptionsUseCase getUserSubscriptions,
    required GetSubscriptionDetailsUseCase getSubscriptionDetails,
    required GetSubscriptionPlansUseCase getSubscriptionPlans,
    required CreateSubscriptionUseCase createSubscription,
    required CancelSubscriptionUseCase cancelSubscription,
    required TogglePauseSubscriptionUseCase togglePause,
    required RepaymentSubscriptionUseCase repayment,
    required GetSubscriptionInvoicesUseCase getInvoices,
    required GetSubscriptionPlanProductsUseCase getPlanProducts,
    required SearchPlansForVariantUseCase searchPlans,
  })  : _getUserSubscriptions = getUserSubscriptions,
        _getSubscriptionDetails = getSubscriptionDetails,
        _getSubscriptionPlans = getSubscriptionPlans,
        _createSubscription = createSubscription,
        _cancelSubscription = cancelSubscription,
        _togglePause = togglePause,
        _repayment = repayment,
        _getInvoices = getInvoices,
        _getPlanProducts = getPlanProducts,
        _searchPlans = searchPlans,
        super(SubscriptionInitial());

  SubscriptionSuccess _getCurrentSuccessState() {
    if (state is SubscriptionSuccess) {
      return state as SubscriptionSuccess;
    }
    return const SubscriptionSuccess();
  }

  Future<void> fetchSubscriptionPlans() async {
    try {
      final currentState = _getCurrentSuccessState();
      if (currentState.plans.isEmpty) emit(SubscriptionLoading());
      final plans = await _getSubscriptionPlans();
      emit(_getCurrentSuccessState().copyWith(plans: plans));
    } on SubscriptionFailure catch (e) {
      emit(SubscriptionError(e.message));
    } catch (e) {
      emit(const SubscriptionError(
        'An unexpected error occurred while fetching plans.',
      ));
    }
  }

  Future<void> fetchProductsForPlan(int planId) async {
    try {
      final currentState = _getCurrentSuccessState();
      if (currentState.planProducts.containsKey(planId) ||
          currentState.loadingProductPlanIds.contains(planId)) {
        return;
      }

      final loadingIds = Set<int>.from(currentState.loadingProductPlanIds)
        ..add(planId);
      emit(currentState.copyWith(loadingProductPlanIds: loadingIds));

      final products = await _getPlanProducts(planId);
      final latestState = _getCurrentSuccessState();

      final updatedProducts =
          Map<int, List<SubscriptionPlanProductEntity>>.from(
        latestState.planProducts,
      );
      updatedProducts[planId] = products;

      final finalLoadingIds =
          Set<int>.from(latestState.loadingProductPlanIds)..remove(planId);

      emit(latestState.copyWith(
        planProducts: updatedProducts,
        loadingProductPlanIds: finalLoadingIds,
      ));
    } catch (_) {
      final currentState = _getCurrentSuccessState();
      final finalLoadingIds =
          Set<int>.from(currentState.loadingProductPlanIds)..remove(planId);
      emit(currentState.copyWith(loadingProductPlanIds: finalLoadingIds));
    }
  }

  Future<void> fetchUserSubscriptions() async {
    try {
      final currentState = _getCurrentSuccessState();
      if (currentState.userSubscriptions.isEmpty) emit(SubscriptionLoading());
      final subscriptions = await _getUserSubscriptions();
      emit(
        _getCurrentSuccessState()
            .copyWith(userSubscriptions: subscriptions),
      );
    } on SubscriptionFailure catch (e) {
      if (e.message.contains('must be logged in')) {
        emit(_getCurrentSuccessState()
            .copyWith(userSubscriptions: const []));
      } else {
        emit(SubscriptionError(e.message));
      }
    } catch (e) {
      emit(const SubscriptionError('Failed to load your subscriptions.'));
    }
  }

  Future<void> createSubscription(Map<String, dynamic> requestData) async {
    try {
      emit(SubscriptionLoading());
      final result = await _createSubscription(requestData);
      if (result.requiresOnlinePayment && result.subscriptionId != null) {
        emit(SubscriptionCreated(
          result.paymentLinks ?? {},
          result.subscriptionId!,
        ));
      } else {
        emit(const SubscriptionActionSuccess(
          'Subscription created successfully!',
        ));
      }
      await fetchUserSubscriptions();
    } on SubscriptionFailure catch (e) {
      emit(SubscriptionError(e.message));
    } catch (e) {
      emit(const SubscriptionError('Failed to create the subscription.'));
    }
  }

  Future<Map<String, dynamic>?> cancelSubscription(
    int subscriptionId, {
    String? reason,
  }) async {
    final previousState = _getCurrentSuccessState();
    try {
      final result =
          await _cancelSubscription(subscriptionId, reason: reason);
      final msg =
          result['message'] ?? 'Subscription cancelled successfully.';
      emit(SubscriptionActionSuccess(msg));
      await fetchUserSubscriptions();
      return result;
    } on SubscriptionFailure catch (e) {
      emit(SubscriptionError(e.message));
      emit(previousState);
      return null;
    } catch (e) {
      emit(const SubscriptionError(
        'Failed to cancel the subscription.',
      ));
      emit(previousState);
      return null;
    }
  }

  Future<void> togglePauseSubscription(
    int subscriptionId,
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    final previousState = _getCurrentSuccessState();
    try {
      final response =
          await _togglePause(subscriptionId, startDate, endDate);
      emit(SubscriptionActionSuccess(response.message));
      await fetchUserSubscriptions();
    } on SubscriptionFailure catch (e) {
      emit(SubscriptionError(e.message));
      emit(previousState);
    } catch (e) {
      emit(const SubscriptionError(
        'An unexpected error occurred while updating status.',
      ));
      emit(previousState);
    }
  }

  Future<void> handleRepayment(int subscriptionId) async {
    emit(SubscriptionLoading());
    try {
      final result = await _repayment(subscriptionId);
      if (result.success) {
        if (result.requiresOnlinePayment) {
          emit(SubscriptionRepaymentInitiated(result.paymentLinks ?? {}));
        } else {
          emit(SubscriptionActionSuccess(result.message));
          await fetchUserSubscriptions();
        }
      } else {
        emit(SubscriptionError(result.message));
      }
    } on SubscriptionFailure catch (e) {
      emit(SubscriptionError(e.message));
    } catch (e) {
      emit(const SubscriptionError(
        'An unexpected error occurred during repayment.',
      ));
    }
  }

  Future<void> fetchSubscriptionInvoices(int subscriptionId) async {
    try {
      final currentState = _getCurrentSuccessState();
      if (currentState.invoices == null) emit(SubscriptionLoading());
      final invoices = await _getInvoices(subscriptionId);
      emit(currentState.copyWith(invoices: invoices));
    } on SubscriptionFailure catch (e) {
      emit(SubscriptionError(e.message));
    } catch (e) {
      emit(const SubscriptionError('Failed to fetch invoices.'));
    }
  }

  Future<void> searchPlansForVariant(int variantId) async {
    try {
      final currentState = _getCurrentSuccessState();
      // Don't emit SubscriptionLoading() — it wipes userSubscriptions and other data
      final searchResults = await _searchPlans(variantId);
      emit(_getCurrentSuccessState().copyWith(planSearchResults: searchResults));
    } on SubscriptionFailure catch (e) {
      emit(SubscriptionError(e.message));
    } catch (e) {
      emit(const SubscriptionError(
        'An unexpected error occurred while searching for plans.',
      ));
    }
  }

  Future<void> fetchSubscriptionDetails(int subscriptionId) async {
    try {
      final currentState = _getCurrentSuccessState();
      // Don't emit SubscriptionLoading() — it wipes userSubscriptions and other data.
      // The screen handles its own local loading flag.
      final details = await _getSubscriptionDetails(subscriptionId);
      emit(_getCurrentSuccessState().copyWith(selectedSubscription: details));
    } on SubscriptionFailure catch (e) {
      emit(SubscriptionError(e.message));
    } catch (e) {
      emit(const SubscriptionError('Failed to load subscription details.'));
    }
  }

  void clearSubscriptionState() {
    emit(SubscriptionInitial());
  }
}
