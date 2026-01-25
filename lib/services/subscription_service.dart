import 'package:grocery_app/common_widgets/global_import.dart';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

// Top-level function for background JSON parsing
Map<String, dynamic> _parseJson(String jsonString) {
  return jsonDecode(jsonString) as Map<String, dynamic>;
}

// Top-level function for background JSON list parsing
List<dynamic> _parseJsonList(String jsonString) {
  return jsonDecode(jsonString) as List<dynamic>;
}

List<Subscription> _parseSubscriptions(String responseBody) {
  final parsed = json.decode(responseBody);
  final subscriptionsMap = parsed['subscriptions'] as Map<String, dynamic>;
  final List<Subscription> allSubscriptions = [];

  // Iterate over all status lists (ACTIVE, PAUSED, etc.) and combine them
  subscriptionsMap.forEach((status, list) {
    if (list is List) {
      allSubscriptions.addAll(
        list.map<Subscription>((item) => Subscription.fromJson(item)),
      );
    }
  });

  return allSubscriptions;
}

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

      final responseData = await compute(_parseJson, response.body);

      if (response.statusCode == 201) {
        if (responseData.containsKey('payment_links') &&
            responseData.containsKey('subscription_id')) {
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
        print(responseData['errors']);
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to create subscription',
          'errors': responseData['errors'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred while creating the subscription',
        'error': e.toString(),
      };
    }
  }

  // NOTE: Based on your code, this function seems to fetch subscription *plans*, not subscriptions.
  // The logic is preserved as-is.
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

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getAuthHeaders(token),
      );

      print('Response status code: ${response.statusCode}');

      if (response.statusCode != 200) {
        return {
          'success': false,
          'message': 'Failed to fetch subscriptions: ${response.statusCode}',
        };
      }

      // The compute function handles both list and map responses by parsing first.
      final dynamic parsedData = await compute(jsonDecode, response.body);

      if (parsedData is List) {
        final subscriptions =
            parsedData.map((item) => Subscription.fromJson(item)).toList();
        return {
          'success': true,
          'data': subscriptions,
          'message': 'Subscriptions fetched successfully',
        };
      } else {
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
        return {'success': false, 'message': 'User not authenticated.'};
      }

      final url = '${ApiConfig.baseUrl}${ApiConfig.subscriptionsEndpoint}';
      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getAuthHeaders(token),
      );

      print('--- SUBSCRIPTION RESPONSE ---');
      print('Status Code: ${response.statusCode}');
      // print('Response Body: ${response.body}'); // You can keep this for debugging

      if (response.statusCode != 200) {
        final errorBody = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorBody['detail'] ?? 'Failed to load subscriptions.',
        };
      }

      // Use the compute function to parse the complex JSON in the background
      final List<Subscription> allSubscriptions = await compute(
        _parseSubscriptions,
        response.body,
      );

      return {
        'success': true,
        'data':
            allSubscriptions, // Return the combined list under the 'data' key
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
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

      final responseData = await compute(_parseJson, response.body);

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

      final responseData = await compute(_parseJson, response.body);

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

      if (response.statusCode != 200) {
        return {
          'success': false,
          'message':
              'Failed to fetch subscription plans: ${response.statusCode}',
        };
      }

      final responseData = await compute(_parseJsonList, response.body);

      final plans =
          responseData.map((item) => SubscriptionPlan.fromJson(item)).toList();

      return {
        'success': true,
        'data': plans,
        'message': 'Subscription plans fetched successfully',
      };
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

      final responseData = await compute(_parseJson, response.body);
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

      final responseData = await compute(_parseJson, response.body);

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
          'message': responseData['detail'] ?? 'Failed to pause subscription',
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

      if (response.statusCode == 200) {
        final data = await compute(_parseJson, response.body);
        return {
          'success': true,
          'data': SubscriptionPlanProductsResponse.fromJson(data),
        };
      } else if (response.statusCode == 401) {
        final refreshResult = await _authService.refreshAccessToken();
        if (refreshResult) {
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
        final data = await compute(_parseJson, response.body);
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

      final responseData = await compute(_parseJson, response.body);
      print('Repayment subscription response: $responseData');

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (responseData.containsKey('payment_links') &&
            responseData.containsKey('subscription_id')) {
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

  Future<ApiResponse> getSubscriptionInvoices(int subscriptionId) async {
    try {
      ApiResponse parseApiResponse(String responseBody) {
        return apiResponseFromJson(responseBody);
      }

      final token = await _authService.getAccessToken();
      if (token == null) {
        throw Exception('Authentication token is missing');
      }

      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/odoo/subscriptions/$subscriptionId/invoices/',
        ),
        headers: ApiConfig.getAuthHeaders(token),
      );

      if (response.statusCode == 200) {
        print(response.statusCode);
        // Use compute to parse the JSON and create the model in a background isolate.
        return await compute(parseApiResponse, response.body);
      } else {
        // For errors, parse the generic JSON to get the message.
        final errorData = await compute(_parseJson, response.body);
        throw Exception(
          errorData['message'] ??
              'Failed to load invoices: Status code ${response.statusCode}',
        );
      }
    } catch (e) {
      // Log the original error for debugging, but throw a more user-friendly message.
      print('Error getting subscription invoices: $e');
      throw Exception(
        'An error occurred while fetching your invoices. Please try again.',
      );
    }
  }

  // File I/O should be handled carefully. It can still block the main thread.
  Future<String> downloadInvoice(String s3Url, String displayName) async {
    try {
      // Check if the URL is internal (starts with our API base URL)
      // If it is, we need to attach the auth token.
      final isInternalUrl = s3Url.startsWith(ApiConfig.baseUrl);
      Map<String, String>? headers;

      if (isInternalUrl) {
        final token = await _authService.getAccessToken();
        if (token != null) {
          headers = ApiConfig.getAuthHeaders(token);
        }
      }

      print('Downloading invoice from: $s3Url');
      print('Is internal URL: $isInternalUrl');

      // Download the PDF
      final pdfResponse = await http.get(Uri.parse(s3Url), headers: headers);

      if (pdfResponse.statusCode == 200) {
        String? savedPath;
        bool savedToDownloads = false;

        // Try to save to Downloads first (Android < 10 or with permissions)
        if (Platform.isAndroid) {
          try {
            // Request storage permission
            // ignore: unused_local_variable
            var status = await Permission.storage.request();

            final downloadsPath = '/storage/emulated/0/Download';
            final directory = Directory(downloadsPath);

            if (await directory.exists()) {
              final sanitizedDisplayName = displayName.replaceAll(
                RegExp(r'[\\/:*?"<>|]'),
                '_',
              );
              final filePath = '$downloadsPath/$sanitizedDisplayName.pdf';
              final file = File(filePath);

              await file.writeAsBytes(pdfResponse.bodyBytes);
              savedPath = filePath;
              savedToDownloads = true;
            }
          } catch (e) {
            print('Could not save to Downloads: $e');
            // Continue to fallback
          }
        }

        // Fallback to Application Documents or Temp directory
        if (savedPath == null) {
          final dir = await getTemporaryDirectory();
          final sanitizedDisplayName = displayName.replaceAll(
            RegExp(r'[\\/:*?"<>|]'),
            '_',
          );
          final filePath = '${dir.path}/$sanitizedDisplayName.pdf';
          final file = File(filePath);
          await file.writeAsBytes(pdfResponse.bodyBytes);
          savedPath = filePath;
        }

        print('Invoice downloaded successfully to: $savedPath');
        await OpenFilex.open(savedPath);
        return savedPath;
      } else {
        throw Exception(
          'Failed to download PDF: ${pdfResponse.statusCode} ${pdfResponse.reasonPhrase}',
        );
      }
    } catch (e) {
      print('Error downloading invoice: $e');
      throw Exception('Failed to download invoice: $e');
    }
  }
}
