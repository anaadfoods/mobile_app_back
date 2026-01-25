import 'package:flutter/foundation.dart' show debugPrint;
import 'package:grocery_app/models/plan_Search_model.dart';
import 'package:grocery_app/services/plan_search_service.dart';

import '../models/subscription_invoice_model.dart';
import '../models/subscription_model.dart';
import '../models/subscription_plan_model.dart';
import '../models/subscription_plan_product_model.dart';
import '../models/subscription_request_create_model.dart';
import '../services/auth_service.dart';
import '../services/subscription_service.dart';

// A custom exception for handling subscription-related errors.
class SubscriptionException implements Exception {
  final String message;
  final Map<String, dynamic>? errors; // To hold validation errors from the backend

  SubscriptionException(this.message, {this.errors});

  @override
  String toString() => message;
}

// A specific model to handle the dual response from createSubscription
class SubscriptionCreationResult {
  final Subscription? subscription;
  final Map<String, dynamic>? paymentLinks;
  final int? subscriptionId;
  final String? merchantTransactionId;

  SubscriptionCreationResult({
    this.subscription,
    this.paymentLinks,
    this.subscriptionId,
    this.merchantTransactionId,
  });
}

class PauseSubscriptionResponse {
  final String message;
  PauseSubscriptionResponse({required this.message});

  factory PauseSubscriptionResponse.fromJson(Map<String, dynamic> json) {
    return PauseSubscriptionResponse(message: json['message'] ?? 'Status updated successfully.');
  }
}

class RepaymentResult {
  final bool success;
  final Map<String, dynamic>? paymentLinks;
  final int? subscriptionId;
  final String message;

  RepaymentResult({
    required this.success,
    this.paymentLinks,
    this.subscriptionId,
    required this.message,
  });

  factory RepaymentResult.fromJson(Map<String, dynamic> json) {
    return RepaymentResult(
      success: json['success'] ?? false,
      paymentLinks: json['payment_links'],
      subscriptionId: json['subscription_id'],
      message: json['message'] ?? 'Repayment processed successfully.',
    );
  }
}



class SubscriptionRepository {
  final SubscriptionService _subscriptionService;
  final AuthService _authService;

  SubscriptionRepository({SubscriptionService? subscriptionService, AuthService? authService})
      : _subscriptionService = subscriptionService ?? SubscriptionService(),
        _authService = authService ?? AuthService();

  // Helper to centralize auth checks and token refresh logic.
  Future<T> _makeAuthenticatedRequest<T>(Future<T> Function() apiCall) async {
    try {
      if (!await _authService.isLoggedIn()) {
        throw SubscriptionException('You must be logged in to manage subscriptions.');
      }
      return await apiCall();
    } on Exception catch (e) {
      if (e.toString().contains('401') || e.toString().contains('Session expired')) {
        final refreshed = await _authService.refreshAccessToken();
        if (refreshed) {
          return await apiCall(); // Retry the request once
        } else {
          throw SubscriptionException('Your session has expired. Please log in again.');
        }
      }
      // Re-throw other exceptions to be caught by the Cubit
      rethrow;
    }
  }

  // A generic wrapper for service calls that return Map<String, dynamic>
  Future<T> _handleServiceCall<T>(
    Future<Map<String, dynamic>> Function() serviceCall,
    T Function(Map<String, dynamic> data) parser,
  ) async {
    final result = await serviceCall();
    if (result['success'] == true) {
      return parser(result);
    } else {
      throw SubscriptionException(result['message'] ?? 'An unknown error occurred.', errors: result['errors']);
    }
  }

  Future<List<SubscriptionPlan>> getSubscriptionPlans() async {
    return _handleServiceCall(
      _subscriptionService.getSubscriptionPlans,
      (result) => (result['data'] as List).map((plan) => SubscriptionPlan.fromJson(plan)).toList(),
    );
  }

// ... inside your SubscriptionRepository class ...

  // Find your existing getUserSubscriptions method and wrap the call in a try-catch.
  Future<List<Subscription>> getUserSubscriptions() async {
    return _makeAuthenticatedRequest<List<Subscription>>(() async {
      try {
        // This is the line that calls your service
        final result = await _subscriptionService.getSubscriptions();
        
        if (result['success'] == true && result['data'] != null) {
          // The error is likely happening inside this line as it tries to parse
          return result['data'] as List<Subscription>;
        } else {
          throw SubscriptionException(result['message'] ?? 'Failed to get subscriptions from service.');
        }
      } catch (e, stackTrace) {
        debugPrint('Subscription error: $e');
        debugPrint('Stack: $stackTrace');
        // User-friendly message - hide technical details
        throw SubscriptionException("Couldn't load subscriptions right now 📶\n\n🌱 Natural farming saves farmers 70% on input costs compared to chemical farming!");
      }
    });
  }
  
  Future<Subscription> getSubscriptionDetails(int subscriptionId) async {
    return _makeAuthenticatedRequest(() async {
      return _handleServiceCall(
        () => _subscriptionService.getSubscriptionDetails(subscriptionId),
        (result) => Subscription.fromJson(result['data']),
      );
    });
  }

  Future<SubscriptionCreationResult> createSubscription(SubscriptionCreateRequest request) async {
    return _makeAuthenticatedRequest(() async {
      return _handleServiceCall(
        () => _subscriptionService.createSubscription(request),
        (result) {
          if (result.containsKey('payment_links')) {
            return SubscriptionCreationResult(
              paymentLinks: result['payment_links'],
              subscriptionId: result['subscription_id'],
              merchantTransactionId: result['merchant_transaction_id'],
            );
          } else {
            return SubscriptionCreationResult(subscription: Subscription.fromJson(result['data']));
          }
        },
      );
    });
  }

   Future<PauseSubscriptionResponse> togglePauseSubscription(int subscriptionId, DateTime? pauseStartDate, DateTime? pauseEndDate) async {
    return _makeAuthenticatedRequest(() async {
      return _handleServiceCall(
        () => _subscriptionService.togglePauseSubscription(subscriptionId, pauseStartDate, pauseEndDate),
        (result) => PauseSubscriptionResponse.fromJson(result),
      );
    });
  }

  Future<RepaymentResult> repaymentSubscription(int subscriptionId) async {
    return _makeAuthenticatedRequest(() async {
      return _handleServiceCall(
        () => _subscriptionService.RepaymentSubscription(subscriptionId),
        (result) => RepaymentResult.fromJson(result),
      );
    });
  }

  Future<void> cancelSubscription(int subscriptionId) async {
    await _makeAuthenticatedRequest(() async {
      final result = await _subscriptionService.cancelSubscription(subscriptionId);
      if (result['success'] != true) {
        throw SubscriptionException(result['message'] ?? 'Failed to cancel subscription.');
      }
    });
  }
  
  Future<SubscriptionPlanProductsResponse> getSubscriptionPlanProducts(int planId) async {
     return _handleServiceCall(
        () => _subscriptionService.getSubscriptionPlanProducts(planId),
        (result) => SubscriptionPlanProductsResponse.fromJson(result['data']),
      );
  }
  
  Future<ApiResponse> getSubscriptionInvoices(int subscriptionId) async {
    return _makeAuthenticatedRequest(() => _subscriptionService.getSubscriptionInvoices(subscriptionId));
  }
  Future<List<PlanSearchResult>> searchPlansForVariant(int variantId) async {
    try {
      // We call the static service method directly.
      return await PlanSearchService.fetchPlansForVariant(variantId);
    } catch (e) {
      // Wrap any potential error in our custom exception type.
      throw SubscriptionException('Failed to find plans for the selected product.');
    }
  }

}