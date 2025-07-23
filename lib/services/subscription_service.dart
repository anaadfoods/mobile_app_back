import 'dart:convert';
import 'package:grocery_app/models/repayment_subscription_model.dart';
import 'package:grocery_app/models/subscription_plan_product_model.dart';
import 'package:grocery_app/models/subscription_request_create_model.dart';
import 'package:http/http.dart' as http;
import '../models/subscription_model.dart';
import '../models/subscription_plan_model.dart';
import 'api_config.dart';
import 'auth_service.dart';
import '../models/payment_status_model.dart';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  static const String subscriptionsEndpoint = '/api/subscriptions';

  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> createSubscription(
    SubscriptionCreateRequest request,
  ) async {
    try {
      final token = await _authService.getAccessToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
          'requiresLogin': true,
        };
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}$subscriptionsEndpoint/create/'),
        headers: ApiConfig.getAuthHeaders(token),
        body: jsonEncode(request.toJson()),
      );

      final responseData = jsonDecode(response.body);
      print('Create subscription response: $responseData');

      if (response.statusCode == 201) {
        // Check if this is a payment response (has payment_links)
        if (responseData.containsKey('payment_links') &&
            responseData.containsKey('subscription_id')) {
          // Return raw response for payment flow
          return {
            'success': true,
            'payment_links': responseData['payment_links'],
            'subscription_id': responseData['subscription_id'],
            'merchant_transaction_id': responseData['merchant_transaction_id'],
            'message':
                responseData['message'] ??
                'Payment session created successfully',
          };
        } else {
          // Return parsed subscription for non-payment flow
          return {
            'success': true,
            'data': Subscription.fromJson(responseData),
            'message': 'Subscription created successfully',
          };
        }
      } else if (response.statusCode == 401) {
        final refreshResult = await _authService.refreshAccessToken();
        if (refreshResult) {
          return createSubscription(request);
        } else {
          return {
            'success': false,
            'message': 'Session expired',
            'requiresLogin': true,
          };
        }
      } else {
        print('Create subscription error: ${responseData['message']}');
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to create subscription',
          'errors': responseData['errors'],
        };
      }
    } catch (e) {
      print('Error creating subscription: $e');
      return {
        'success': false,
        'message': 'An error occurred while creating the subscription',
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> getSubscriptionsbyId(int id) async {
    try {
      final token = await _authService.getAccessToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
          'requiresLogin': true,
        };
      }

      final url =
          '${ApiConfig.baseUrl}${ApiConfig.subscriptionsEndpoint}/plans/$id/';
      print('Fetching subscriptions from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getAuthHeaders(token),
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode != 200) {
        return {
          'success': false,
          'message': 'Failed to fetch subscriptions: ${response.statusCode}',
        };
      }

      final responseData = jsonDecode(response.body);
      print('Parsed response data: $responseData');
      print('Response data type: ${responseData.runtimeType}');

      // Handle direct array response
      if (responseData is List) {
        try {
          final subscriptions =
              responseData.map((item) => Subscription.fromJson(item)).toList();

          return {
            'success': true,
            'data': subscriptions,
            'message': 'Subscriptions fetched successfully',
          };
        } catch (e) {
          print('Error parsing subscriptions: $e');
          return {
            'success': false,
            'message': 'Error parsing subscription data',
            'error': e.toString(),
          };
        }
      } else {
        print('Response is not a list: $responseData');
        return {
          'success': false,
          'message': 'Invalid response format from server',
        };
      }
    } catch (e) {
      print('Error fetching subscriptions: $e');
      return {
        'success': false,
        'message': 'An error occurred while fetching subscriptions',
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> getSubscriptions() async {
    try {
      final token = await _authService.getAccessToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
          'requiresLogin': true,
        };
      }

      final url = '${ApiConfig.baseUrl}${ApiConfig.subscriptionsEndpoint}';
      print('Fetching subscriptions from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getAuthHeaders(token),
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode != 200) {
        return {
          'success': false,
          'message': 'Failed to fetch subscriptions: ${response.statusCode}',
        };
      }

      final responseData = jsonDecode(response.body);
      print('Parsed response data: $responseData');
      print('Response data type: ${responseData.runtimeType}');

      if (responseData is Map && responseData.containsKey('subscriptions')) {
        try {
          // Extract all subscriptions from the nested structure
          final allSubscriptions = <Subscription>[];
          final subscriptionsMap =
              responseData['subscriptions'] as Map<String, dynamic>;

          subscriptionsMap.forEach((status, subscriptions) {
            if (subscriptions is List) {
              allSubscriptions.addAll(
                subscriptions
                    .map((item) => Subscription.fromJson(item))
                    .toList(),
              );
            }
          });

          return {
            'success': true,
            'data': allSubscriptions,
            'message': 'Subscriptions fetched successfully',
          };
        } catch (e) {
          print('Error parsing subscriptions: $e');
          return {
            'success': false,
            'message': 'Error parsing subscription data',
            'error': e.toString(),
          };
        }
      } else {
        print('Response is not in expected format: $responseData');
        return {
          'success': false,
          'message': 'Invalid response format from server',
        };
      }
    } catch (e) {
      print('Error fetching subscriptions: $e');
      return {
        'success': false,
        'message': 'An error occurred while fetching subscriptions',
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> getSubscriptionDetails(
    int subscriptionId,
  ) async {
    try {
      final token = await _authService.getAccessToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
          'requiresLogin': true,
        };
      }

      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}$subscriptionsEndpoint/$subscriptionId/',
        ),
        headers: ApiConfig.getAuthHeaders(token),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': Subscription.fromJson(responseData['data']),
          'message': 'Subscription details fetched successfully',
        };
      } else if (response.statusCode == 401) {
        final refreshResult = await _authService.refreshAccessToken();
        if (refreshResult) {
          return getSubscriptionDetails(subscriptionId);
        } else {
          return {
            'success': false,
            'message': 'Session expired',
            'requiresLogin': true,
          };
        }
      } else {
        return {
          'success': false,
          'message':
              responseData['message'] ?? 'Failed to fetch subscription details',
        };
      }
    } catch (e) {
      print('Error fetching subscription details: $e');
      return {
        'success': false,
        'message': 'An error occurred while fetching subscription details',
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> cancelSubscription(int subscriptionId) async {
    try {
      final token = await _authService.getAccessToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
          'requiresLogin': true,
        };
      }

      final response = await http.post(
        Uri.parse(
          '${ApiConfig.baseUrl}$subscriptionsEndpoint/$subscriptionId/cancel/',
        ),
        headers: ApiConfig.getAuthHeaders(token),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Subscription cancelled successfully',
        };
      } else if (response.statusCode == 401) {
        final refreshResult = await _authService.refreshAccessToken();
        if (refreshResult) {
          return cancelSubscription(subscriptionId);
        } else {
          return {
            'success': false,
            'message': 'Session expired',
            'requiresLogin': true,
          };
        }
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to cancel subscription',
        };
      }
    } catch (e) {
      print('Error cancelling subscription: $e');
      return {
        'success': false,
        'message': 'An error occurred while cancelling the subscription',
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> getSubscriptionPlans() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.subscriptionPlansEndpoint}'),
        headers: ApiConfig.getBaseHeaders(),
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode != 200) {
        return {
          'success': false,
          'message':
              'Failed to fetch subscription plans: ${response.statusCode}',
        };
      }

      final responseData = jsonDecode(response.body);
      print('Parsed response data: $responseData');
      print('Response data type: ${responseData.runtimeType}');

      // Handle direct array response
      if (responseData is List) {
        try {
          final plans =
              responseData
                  .map((item) => SubscriptionPlan.fromJson(item))
                  .toList();

          return {
            'success': true,
            'data': plans,
            'message': 'Subscription plans fetched successfully',
          };
        } catch (e) {
          print('Error parsing subscription plans: $e');
          return {
            'success': false,
            'message': 'Error parsing subscription plans data',
            'error': e.toString(),
          };
        }
      } else {
        print('Response is not a list: $responseData');
        return {
          'success': false,
          'message': 'Invalid response format from server',
        };
      }
    } catch (e) {
      print('Error fetching subscription plans: $e');
      return {
        'success': false,
        'message': 'An error occurred while fetching subscription plans',
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> subscribeToPlan(int planId) async {
    try {
      final token = await _authService.getAccessToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
          'requiresLogin': true,
        };
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}$subscriptionsEndpoint/subscribe/'),
        headers: ApiConfig.getAuthHeaders(token),
        body: jsonEncode({'plan_id': planId}),
      );

      final responseData = jsonDecode(response.body);
      print('Subscribe to plan response: $responseData');

      if (response.statusCode == 201) {
        return {
          'success': true,
          'data': Subscription.fromJson(responseData),
          'message': 'Successfully subscribed to plan',
        };
      } else if (response.statusCode == 401) {
        final refreshResult = await _authService.refreshAccessToken();
        if (refreshResult) {
          return subscribeToPlan(planId);
        } else {
          return {
            'success': false,
            'message': 'Session expired',
            'requiresLogin': true,
          };
        }
      } else {
        print('Subscribe to plan error: ${responseData['message']}');
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to subscribe to plan',
          'errors': responseData['errors'],
        };
      }
    } catch (e) {
      print('Error subscribing to plan: $e');
      return {
        'success': false,
        'message': 'An error occurred while subscribing to plan',
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> togglePauseSubscription(
    int subscriptionId,
    DateTime? pauseStartDate,
    DateTime? pauseEndDate,
  ) async {
    try {
      final token = await _authService.getAccessToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
          'requiresLogin': true,
        };
      }

      final response = await http.post(
        Uri.parse(
          '${ApiConfig.baseUrl}$subscriptionsEndpoint/$subscriptionId/pause/',
        ),
        headers: ApiConfig.getAuthHeaders(token),
        body:
            pauseStartDate != null && pauseEndDate != null
                ? jsonEncode({
                  'pause_start_date':
                      pauseStartDate.toIso8601String().split('T')[0],
                  'pause_end_date':
                      pauseEndDate.toIso8601String().split('T')[0],
                })
                : null,
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'],
          'pause_start_date': responseData['pause_start_date'],
          'pause_end_date': responseData['pause_end_date'],
          'next_delivery_date': responseData['next_delivery_date'],
        };
      } else if (response.statusCode == 401) {
        final refreshResult = await _authService.refreshAccessToken();
        if (refreshResult) {
          return togglePauseSubscription(
            subscriptionId,
            pauseStartDate,
            pauseEndDate,
          );
        } else {
          return {
            'success': false,
            'message': 'Session expired',
            'requiresLogin': true,
          };
        }
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to pause subscription',
        };
      }
    } catch (e) {
      print('Error pausing subscription: $e');
      return {
        'success': false,
        'message': 'An error occurred while pausing the subscription',
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> getSubscriptionPlanProducts(int planId) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/subscriptions/plans/$planId/products',
        ),
        headers: ApiConfig.getBaseHeaders(),
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Parsed response data: $data');
        return {
          'success': true,
          'data': SubscriptionPlanProductsResponse.fromJson(data),
        };
      } else if (response.statusCode == 401) {
        // Handle token refresh
        final refreshResult = await _authService.refreshAccessToken();
        if (refreshResult) {
          // Retry the request with new token
          return getSubscriptionPlanProducts(planId);
        }
        return {
          'success': false,
          'message': 'Authentication failed',
          'requiresLogin': true,
        };
      } else {
        print('Failed to fetch plan products. Status: ${response.statusCode}');
        return {'success': false, 'message': 'Failed to fetch plan products'};
      }
    } catch (e) {
      print('Error fetching subscription plan products: $e');
      return {
        'success': false,
        'message': 'An error occurred while fetching plan products',
      };
    }
  }

  Future<SubscriptionPaymentStatus?> fetchSubscriptionPaymentStatus(
    int subscriptionId,
  ) async {
    try {
      final token = await _authService.getAccessToken();
      if (token == null) return null;
      final url =
          '${ApiConfig.baseUrl}/api/payments/subscription-status/$subscriptionId/';
      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getAuthHeaders(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return SubscriptionPaymentStatus.fromJson(data);
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching subscription payment status: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> RepaymentSubscription(int planId) async {
    try {
      final token = await _authService.getAccessToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
          'requiresLogin': true,
        };
      }

      final response = await http.post(
        Uri.parse(
          '${ApiConfig.baseUrl}$subscriptionsEndpoint/$planId/next-installment-payment/',
        ),
        headers: ApiConfig.getAuthHeaders(token),
      );

      final responseData = jsonDecode(response.body);
      print('Repayment subscription response: $responseData');

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Check if this is a payment response (has payment_links)
        if (responseData.containsKey('payment_links') &&
            responseData.containsKey('subscription_id')) {
          // Return raw response for payment flow
          return {
            'success': true,
            'payment_links': responseData['payment_links'],
            'subscription_id': responseData['subscription_id'],
            'merchant_transaction_id': responseData['merchant_transaction_id'],
            'message':
                responseData['message'] ??
                'Payment session created successfully',
          };
        } else {
          // Return parsed response for non-payment flow
          return {
            'success': true,
            'data': responseData,
            'message':
                responseData['message'] ?? 'Repayment processed successfully',
          };
        }
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to repay subscription',
          'errors': responseData['errors'],
        };
      }
    } catch (e) {
      print('Error repaying subscription: $e');
      return {
        'success': false,
        'message': 'An error occurred while repaying the subscription',
        'error': e.toString(),
      };
    }
  }
}
