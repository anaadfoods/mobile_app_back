import 'package:flutter/foundation.dart' show debugPrint;
import 'package:grocery_app/models/plan_Search_model.dart';
import 'package:grocery_app/services/plan_search_service.dart';

import '../models/subscription_invoice_model.dart';
import '../models/subscription_model.dart';
import '../models/subscription_plan_model.dart';
import '../models/subscription_plan_product_model.dart';
import '../models/subscription_request_create_model.dart';
import '../services/token_service.dart';
import '../services/subscription_service.dart';
import 'package:grocery_app/service_locator.dart';


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
  final TokenService _tokenService;

  SubscriptionRepository({SubscriptionService? subscriptionService, TokenService? tokenService})
      : _subscriptionService = subscriptionService ?? getIt<SubscriptionService>(),
        _tokenService = tokenService ?? getIt<TokenService>();

  Future<void> _checkAuth() async {
    if (!await _tokenService.isLoggedIn()) {
      throw SubscriptionException('You must be logged in to manage subscriptions.');
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

  Future<List<Subscription>> getUserSubscriptions() async {
    await _checkAuth();
    try {
      final result = await _subscriptionService.getSubscriptions();
      
      if (result['success'] == true && result['data'] != null) {
        final subscriptions = result['data'] as List<Subscription>;
        
        // Filter out UPI subscriptions that have failed or are still pending payment
        return subscriptions.where((sub) {
          if (sub.paymentMethod.toUpperCase() == 'UPI') {
            final status = sub.paymentStatus.toUpperCase();
            if (status == 'PAYMENT_PENDING' || status == 'PENDING' || status == 'FAILED') {
              return false;
            }
          }
          return true;
        }).toList();
      } else {
        throw SubscriptionException(result['message'] ?? 'Failed to get subscriptions from service.');
      }
    } catch (e, stackTrace) {
      debugPrint('Subscription error: $e');
      debugPrint('Stack: $stackTrace');
      throw SubscriptionException("Sorry, we are not available right now. Please try again later.");
    }
  }
  
  Future<Subscription> getSubscriptionDetails(int subscriptionId) async {
    await _checkAuth();
    return _handleServiceCall(
      () => _subscriptionService.getSubscriptionDetails(subscriptionId),
      (result) => Subscription.fromJson(result['data']),
    );
  }

  Future<SubscriptionCreationResult> createSubscription(SubscriptionCreateRequest request) async {
    await _checkAuth();
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
  }

   Future<PauseSubscriptionResponse> togglePauseSubscription(int subscriptionId, DateTime? pauseStartDate, DateTime? pauseEndDate) async {
    await _checkAuth();
    return _handleServiceCall(
      () => _subscriptionService.togglePauseSubscription(subscriptionId, pauseStartDate, pauseEndDate),
      (result) => PauseSubscriptionResponse.fromJson(result),
    );
  }

  Future<RepaymentResult> repaymentSubscription(int subscriptionId) async {
    await _checkAuth();
    return _handleServiceCall(
      () => _subscriptionService.RepaymentSubscription(subscriptionId),
      (result) => RepaymentResult.fromJson(result),
    );
  }

  Future<void> cancelSubscription(int subscriptionId) async {
    await _checkAuth();
    final result = await _subscriptionService.cancelSubscription(subscriptionId);
    if (result['success'] != true) {
      throw SubscriptionException(result['message'] ?? 'Failed to cancel subscription.');
    }
  }
  
  Future<SubscriptionPlanProductsResponse> getSubscriptionPlanProducts(int planId) async {
     return _handleServiceCall(
        () => _subscriptionService.getSubscriptionPlanProducts(planId),
        (result) => SubscriptionPlanProductsResponse.fromJson(result['data']),
      );
  }
  
  Future<ApiResponse> getSubscriptionInvoices(int subscriptionId) async {
    await _checkAuth();
    return _subscriptionService.getSubscriptionInvoices(subscriptionId);
  }

  Future<List<PlanSearchResult>> searchPlansForVariant(int variantId) async {
    try {
      return await PlanSearchService.fetchPlansForVariant(variantId);
    } catch (e) {
      throw SubscriptionException('Failed to find plans for the selected product.');
    }
  }
}