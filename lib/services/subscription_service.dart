import 'dart:convert';
import 'package:grocery_app/models/subscription_request_create_model.dart';
import 'package:http/http.dart' as http;
import '../models/subscription_model.dart';
import '../models/subscription_plan_model.dart';
import 'api_config.dart';
import 'auth_service.dart';

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
        return {
          'success': true,
          'data': Subscription.fromJson(responseData['data']),
          'message': 'Subscription created successfully',
        };
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

      final url = '${ApiConfig.baseUrl}${ApiConfig.subscriptionsEndpoint}$id/';
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
          'data': Subscription.fromJson(responseData['data']),
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
        body: jsonEncode({
          'pause_start_date': pauseStartDate?.toIso8601String().split('T')[0],
          'pause_end_date': pauseEndDate?.toIso8601String().split('T')[0],
        }),
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
}
