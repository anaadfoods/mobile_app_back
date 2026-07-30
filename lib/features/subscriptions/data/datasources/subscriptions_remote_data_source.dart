import 'dart:io';
import 'package:dio/dio.dart' as dio;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:grocery_app/services/api_client.dart';
import 'package:grocery_app/services/api_config.dart';
import 'package:grocery_app/services/api_exception.dart';
import 'package:grocery_app/utils/app_logger.dart';
import 'package:grocery_app/models/subscription_model.dart';
import 'package:grocery_app/models/subscription_plan_model.dart';
import 'package:grocery_app/models/subscription_plan_product_model.dart';
import 'package:grocery_app/models/subscription_invoice_model.dart';
import 'package:grocery_app/models/plan_Search_model.dart';
import 'package:grocery_app/services/plan_search_service.dart';

/// Remote data source for Subscriptions feature.
/// Handles all HTTP calls to the subscription API endpoints.
abstract class SubscriptionsRemoteDataSource {
  Future<List<Subscription>> getSubscriptions();
  Future<Subscription> getSubscriptionDetails(int subscriptionId);
  Future<List<SubscriptionPlan>> getSubscriptionPlans();
  Future<Map<String, dynamic>> createSubscription(Map<String, dynamic> data);
  Future<Map<String, dynamic>> cancelSubscription(int id, {String? reason});
  Future<Map<String, dynamic>> togglePauseSubscription(
    int id,
    DateTime? startDate,
    DateTime? endDate,
  );
  Future<Map<String, dynamic>> repaymentSubscription(int subscriptionId);
  Future<ApiResponse> getSubscriptionInvoices(int subscriptionId);
  Future<SubscriptionPlanProductsResponse> getSubscriptionPlanProducts(
    int planId,
  );
  Future<List<PlanSearchResult>> searchPlansForVariant(int variantId);
}

class SubscriptionsRemoteDataSourceImpl
    implements SubscriptionsRemoteDataSource {
  final ApiClient _apiClient;

  SubscriptionsRemoteDataSourceImpl({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  static const String _endpoint = '/api/subscriptions';

  @override
  Future<List<Subscription>> getSubscriptions() async {
    try {
      final response = await _apiClient.get('$_endpoint/');
      final data = response.data;
      if (data is List) {
        return data
            .map((item) => Subscription.fromJson(
                  Map<String, dynamic>.from(item),
                ))
            .toList();
      }
      if (data is Map && data.containsKey('results')) {
        final list = data['results'] as List;
        return list
            .map((item) => Subscription.fromJson(
                  Map<String, dynamic>.from(item),
                ))
            .toList();
      }
      if (data is Map && data.containsKey('subscriptions')) {
        final subsObj = data['subscriptions'] as Map<String, dynamic>;
        final List<Subscription> allSubs = [];
        for (final entry in subsObj.values) {
          if (entry is List) {
            allSubs.addAll(entry.map((item) => Subscription.fromJson(
                  Map<String, dynamic>.from(item),
                )));
          }
        }
        return allSubs;
      }
      return [];
    } catch (e) {
      AppLogger.instance.log('Error fetching subscriptions: $e');
      if (e is dio.DioException) {
        throw ApiException(
          e.response?.data?['message'] ?? 'Failed to fetch subscriptions',
          e.response?.statusCode ?? 500,
        );
      }
      rethrow;
    }
  }

  @override
  Future<Subscription> getSubscriptionDetails(int subscriptionId) async {
    try {
      final response = await _apiClient.get('$_endpoint/$subscriptionId/');
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return Subscription.fromJson(data);
      }
      throw ApiException('Invalid response format', 500);
    } catch (e) {
      AppLogger.instance.log('Error fetching subscription details: $e');
      if (e is dio.DioException) {
        throw ApiException(
          e.response?.data?['message'] ?? 'Failed to fetch subscription details',
          e.response?.statusCode ?? 500,
        );
      }
      if (e is ApiException) rethrow;
      rethrow;
    }
  }

  @override
  Future<List<SubscriptionPlan>> getSubscriptionPlans() async {
    try {
      final response = await _apiClient.get(
        ApiConfig.subscriptionPlansEndpoint,
      );
      final List<dynamic> data = response.data;
      return data.map((item) => SubscriptionPlan.fromJson(item)).toList();
    } catch (e) {
      AppLogger.instance.log('Error fetching subscription plans: $e');
      if (e is dio.DioException) {
        throw ApiException(
          'Failed to fetch subscription plans',
          e.response?.statusCode ?? 500,
        );
      }
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> createSubscription(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _apiClient.post(
        '$_endpoint/create/',
        data: data,
      );
      final responseData = response.data;

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (responseData is Map &&
            (responseData.containsKey('checkout_url') ||
                responseData.containsKey('access_key') ||
                responseData.containsKey('payment_required')) &&
            (responseData.containsKey('subscription_number') ||
                responseData.containsKey('subscription_id'))) {
          return {
            'success': true,
            'type': 'online_payment',
            'subscription_id': responseData['subscription_id'],
            'subscription_number': responseData['subscription_number'],
            'merchant_transaction_id':
                responseData['merchant_transaction_id'],
            'checkout_url': responseData['checkout_url'],
            'access_key': responseData['access_key'],
            'message': responseData['message'] ??
                'Payment session created successfully',
          };
        } else {
          return {
            'success': true,
            'type': 'cod',
            'subscription_id':
                responseData is Map ? responseData['id'] : null,
            'subscription_number': responseData is Map
                ? responseData['subscription_number']
                : null,
            'data': Subscription.fromJson(
              Map<String, dynamic>.from(responseData),
            ),
            'message': 'Subscription created successfully',
          };
        }
      } else {
        throw ApiException(
          responseData['message'] ?? 'Failed to create subscription',
          response.statusCode ?? 500,
        );
      }
    } catch (e) {
      if (e is dio.DioException) {
        final responseData = e.response?.data;
        final msg = responseData is Map
            ? (responseData['message'] ??
                responseData['detail'] ??
                responseData['plan'] ??
                'Failed to create subscription')
            : (e.message ?? 'Network error');
        throw ApiException(msg.toString(), e.response?.statusCode ?? 500);
      }
      if (e is ApiException) rethrow;
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> cancelSubscription(
    int id, {
    String? reason,
  }) async {
    try {
      final response = await _apiClient.post(
        '$_endpoint/$id/cancel/',
        data: reason != null ? {'reason': reason} : null,
      );
      final responseData = response.data;
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ??
              'Subscription cancelled successfully',
        };
      } else {
        throw ApiException(
          responseData['message'] ?? 'Failed to cancel subscription',
          response.statusCode ?? 500,
        );
      }
    } catch (e) {
      if (e is dio.DioException) {
        throw ApiException(
          e.response?.data?['message'] ?? 'Failed to cancel subscription',
          e.response?.statusCode ?? 500,
        );
      }
      if (e is ApiException) rethrow;
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> togglePauseSubscription(
    int id,
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    try {
      final response = await _apiClient.post(
        '$_endpoint/$id/pause/',
        data: startDate != null && endDate != null
            ? {
                'pause_start_date':
                    startDate.toIso8601String().split('T')[0],
                'pause_end_date': endDate.toIso8601String().split('T')[0],
              }
            : null,
      );
      final responseData = response.data;
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Status updated',
        };
      } else {
        throw ApiException(
          responseData['detail'] ?? 'Failed to pause subscription',
          response.statusCode ?? 500,
        );
      }
    } catch (e) {
      if (e is dio.DioException) {
        throw ApiException(
          e.response?.data?['detail'] ?? 'Failed to toggle pause',
          e.response?.statusCode ?? 500,
        );
      }
      if (e is ApiException) rethrow;
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> repaymentSubscription(
    int subscriptionId,
  ) async {
    try {
      final response = await _apiClient.post(
        '$_endpoint/$subscriptionId/next-installment-payment/',
      );
      final responseData = response.data;

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (responseData is Map &&
            (responseData.containsKey('checkout_url') ||
                responseData.containsKey('access_key') ||
                responseData.containsKey('payment_required')) &&
            (responseData.containsKey('subscription_number') ||
                responseData.containsKey('subscription_id'))) {
          return {
            'success': true,
            'type': 'online_payment',
            'subscription_id': responseData['subscription_id'],
            'subscription_number': responseData['subscription_number'],
            'merchant_transaction_id':
                responseData['merchant_transaction_id'],
            'checkout_url': responseData['checkout_url'],
            'message': responseData['message'] ??
                'Payment session created',
          };
        } else {
          return {
            'success': true,
            'type': 'instant',
            'message': responseData['message'] ??
                'Repayment processed successfully',
          };
        }
      } else {
        throw ApiException(
          responseData['message'] ?? 'Failed to repay subscription',
          response.statusCode ?? 500,
        );
      }
    } catch (e) {
      if (e is dio.DioException) {
        throw ApiException(
          e.response?.data?['message'] ?? 'Repayment failed',
          e.response?.statusCode ?? 500,
        );
      }
      if (e is ApiException) rethrow;
      rethrow;
    }
  }

  @override
  Future<ApiResponse> getSubscriptionInvoices(int subscriptionId) async {
    try {
      final response = await _apiClient.get(
        '/api/invoicing/subscriptions/$subscriptionId/invoices/',
      );
      if (response.statusCode == 200) {
        return ApiResponse.fromJson(response.data);
      } else {
        throw ApiException(
          'Failed to load invoices',
          response.statusCode ?? 500,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch invoices', 500);
    }
  }

  @override
  Future<SubscriptionPlanProductsResponse> getSubscriptionPlanProducts(
    int planId,
  ) async {
    try {
      final response = await _apiClient.get(
        '/api/subscriptions/plans/$planId/products',
      );
      if (response.statusCode == 200) {
        return SubscriptionPlanProductsResponse.fromJson(response.data);
      }
      throw ApiException('Failed to fetch plan products', 500);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch plan products', 500);
    }
  }

  @override
  Future<List<PlanSearchResult>> searchPlansForVariant(int variantId) async {
    return PlanSearchService.fetchPlansForVariant(variantId);
  }
}
