import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grocery_app/models/subscription_plan_product_model.dart';
import 'package:grocery_app/models/subscription_request_create_model.dart';
import 'package:grocery_app/repositories/subscription_repository.dart';
import 'package:grocery_app/cubits/subscription/subscription_state.dart';

class SubscriptionCubit extends Cubit<SubscriptionState> {
  final SubscriptionRepository _subscriptionRepository;

  SubscriptionCubit({required SubscriptionRepository subscriptionRepository})
    : _subscriptionRepository = subscriptionRepository,
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
      // Show loading only if there are no plans yet
      if (currentState.plans.isEmpty) {
        emit(SubscriptionLoading());
      }
      final plans = await _subscriptionRepository.getSubscriptionPlans();
      emit(_getCurrentSuccessState().copyWith(plans: plans));
    } on SubscriptionException catch (e) {
      emit(SubscriptionError(e.message));
    } catch (e) {
      emit(
        const SubscriptionError(
          'An unexpected error occurred while fetching plans.',
        ),
      );
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

      final productsResponse = await _subscriptionRepository
          .getSubscriptionPlanProducts(planId);

      final latestState = _getCurrentSuccessState();

      final updatedProducts = Map<int, List<SubscriptionPlanProduct>>.from(
        latestState.planProducts,
      );
      updatedProducts[planId] = productsResponse.products;

      final finalLoadingIds = Set<int>.from(latestState.loadingProductPlanIds)
        ..remove(planId);

      emit(
        latestState.copyWith(
          planProducts: updatedProducts,
          loadingProductPlanIds: finalLoadingIds,
        ),
      );
    } on SubscriptionException {
      final currentState = _getCurrentSuccessState();
      final finalLoadingIds = Set<int>.from(currentState.loadingProductPlanIds)
        ..remove(planId);
      emit(currentState.copyWith(loadingProductPlanIds: finalLoadingIds));
      // Optionally emit a specific error for product loading if needed
    } catch (e) {
      final currentState = _getCurrentSuccessState();
      final finalLoadingIds = Set<int>.from(currentState.loadingProductPlanIds)
        ..remove(planId);
      emit(currentState.copyWith(loadingProductPlanIds: finalLoadingIds));
    }
  }

  Future<void> fetchUserSubscriptions() async {
    try {
      final currentState = _getCurrentSuccessState();
      if (currentState.userSubscriptions.isEmpty) {
        emit(SubscriptionLoading());
      }
      final subscriptions =
          await _subscriptionRepository.getUserSubscriptions();
      emit(
        _getCurrentSuccessState().copyWith(userSubscriptions: subscriptions),
      );
    } on SubscriptionException catch (e) {
      if (e.message.contains('must be logged in')) {
        emit(_getCurrentSuccessState().copyWith(userSubscriptions: const []));
      } else {
        emit(SubscriptionError(e.message));
      }
    } catch (e) {
      emit(const SubscriptionError('Failed to load your subscriptions.'));
    }
  }

  Future<void> createSubscription(SubscriptionCreateRequest request) async {
    try {
      emit(SubscriptionLoading());
      final result = await _subscriptionRepository.createSubscription(request);
      if (result.paymentLinks != null && result.subscriptionId != null) {
        emit(SubscriptionCreated(result.paymentLinks!, result.subscriptionId!));
      } else {
        emit(
          const SubscriptionActionSuccess('Subscription created successfully!'),
        );
      }
      await fetchUserSubscriptions();
    } on SubscriptionException catch (e) {
      emit(SubscriptionError(e.message));
    } catch (e) {
      emit(const SubscriptionError('Failed to create the subscription.'));
    }
  }

  Future<Map<String, dynamic>?> cancelSubscription(int subscriptionId, {String? reason}) async {
    // Store current state to restore on error
    final previousState = _getCurrentSuccessState();

    try {
      final result = await _subscriptionRepository.cancelSubscription(subscriptionId, reason: reason);
      final msg = result['message'] ?? 'Subscription cancelled successfully.';
      emit(SubscriptionActionSuccess(msg));
      await fetchUserSubscriptions();
      return result;
    } on SubscriptionException catch (e) {
      emit(SubscriptionError(e.message));
      emit(previousState);
      return null;
    } catch (e) {
      emit(const SubscriptionError('Failed to cancel the subscription.'));
      emit(previousState);
      return null;
    }
  }

  Future<void> togglePauseSubscription(
    int subscriptionId,
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    // Store current state to restore on error
    final previousState = _getCurrentSuccessState();

    try {
      // Don't emit loading - keep showing current data
      final response = await _subscriptionRepository.togglePauseSubscription(
        subscriptionId,
        startDate,
        endDate,
      );
      // Emit success message briefly
      emit(SubscriptionActionSuccess(response.message));
      // Then refresh subscriptions to get updated status
      await fetchUserSubscriptions();
    } on SubscriptionException catch (e) {
      // Emit error for listener to show snackbar
      emit(SubscriptionError(e.message));
      // Restore previous state so list stays visible
      emit(previousState);
    } catch (e) {
      // Emit error for listener to show snackbar
      emit(
        const SubscriptionError(
          'An unexpected error occurred while updating status.',
        ),
      );
      // Restore previous state so list stays visible
      emit(previousState);
    }
  }

  Future<void> handleRepayment(int subscriptionId) async {
    emit(SubscriptionLoading());
    try {
      final result = await _subscriptionRepository.repaymentSubscription(
        subscriptionId,
      );
      if (result.success) {
        if (result.paymentLinks != null) {
          emit(SubscriptionRepaymentInitiated(result.paymentLinks!));
        } else {
          emit(SubscriptionActionSuccess(result.message));
          await fetchUserSubscriptions();
        }
      } else {
        throw SubscriptionException(result.message);
      }
    } on SubscriptionException catch (e) {
      emit(SubscriptionError(e.message));
    } catch (e) {
      emit(
        const SubscriptionError(
          'An unexpected error occurred during repayment.',
        ),
      );
    }
  }

  Future<void> fetchSubscriptionInvoices(int subscriptionId) async {
    try {
      final currentState = _getCurrentSuccessState();
      if (currentState.invoices == null) {
        emit(SubscriptionLoading());
      }
      final invoices = await _subscriptionRepository.getSubscriptionInvoices(
        subscriptionId,
      );
      emit(currentState.copyWith(invoices: invoices));
    } on SubscriptionException catch (e) {
      emit(SubscriptionError(e.message));
    } catch (e) {
      emit(const SubscriptionError('Failed to fetch invoices.'));
    }
  }

  Future<void> searchPlansForVariant(int variantId) async {
    try {
      emit(SubscriptionLoading());
      final searchResults = await _subscriptionRepository.searchPlansForVariant(
        variantId,
      );
      final currentState = _getCurrentSuccessState();
      emit(currentState.copyWith(planSearchResults: searchResults));
    } on SubscriptionException catch (e) {
      emit(SubscriptionError(e.message));
    } catch (e) {
      emit(
        const SubscriptionError(
          'An unexpected error occurred while searching for plans.',
        ),
      );
    }
  }

  void clearSubscriptionState() {
    emit(SubscriptionInitial());
  }
}
