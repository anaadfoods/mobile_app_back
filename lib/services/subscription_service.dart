import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:dio/dio.dart' as dio;

List<Subscription> _parseSubscriptions(dynamic parsedData) {
  if (parsedData is! Map) return [];
  final subscriptionsMap = parsedData['subscriptions'] as Map<String, dynamic>;
  final List<Subscription> allSubscriptions = [];

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
  factory SubscriptionService() => getIt<SubscriptionService>();
  SubscriptionService._internal();
  static SubscriptionService create() => SubscriptionService._internal();

  static const String subscriptionsEndpoint = '/api/subscriptions';

  /// Creates a new subscription with payment initialization
  ///
  /// Authentication: Automatically handled by AuthInterceptor
  /// Adds `Authorization: Bearer {token}` header to request
  ///
  /// Request Model Maps to API JSON:
  /// - plan → plan (int)
  /// - deliveryName → recipient_name (String)
  /// - deliveryAddress → delivery_address (String)
  /// - deliveryCity → delivery_city (String)
  /// - deliveryState → delivery_state (String)
  /// - deliveryPincode → delivery_pincode (String)
  /// - deliveryPhone → delivery_phone (String)
  /// - paymentType → payment_type (PAID_FULL|INSTALLMENT)
  /// - paymentMethod → payment_method (COD|UPI)
  /// - deliveryFee → delivery_fee (double)
  /// - expectedDeliveryDate → expected_delivery_date (ISO date string)
  /// - items[] → items[] (array of {product_variant_id, quantity})
  ///
  /// Endpoint: POST /api/subscriptions/create/
  ///
  /// Response Scenarios:
  /// 1. UPI Payment: Returns payment_links for gateway redirect
  /// 2. COD Payment: Returns full subscription object immediately
  /// 3. Error (401): AuthInterceptor handles token refresh automatically
  /// 4. Error (4xx/5xx): Returns error message and validation errors
  Future<Map<String, dynamic>> createSubscription(
    SubscriptionCreateRequest request,
  ) async {
    try {
      AppLogger.instance.log(
        'Sending subscription request to $subscriptionsEndpoint/create/ with data: ${request.toJson()}',
      );

      final response = await ApiClient.instance.post(
        '$subscriptionsEndpoint/create/',
        data: request.toJson(),
      );
      final responseData = response.data;

      AppLogger.instance.log(
        'Subscription API response status: ${response.statusCode}, data: $responseData',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (responseData is Map &&
            responseData.containsKey('payment_links') &&
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
            'subscription_id': responseData is Map ? responseData['id'] : null,
            'data': Subscription.fromJson(
              Map<String, dynamic>.from(responseData),
            ),
            'message': 'Subscription created successfully',
          };
        }
      } else {
        AppLogger.instance.log(
          'Subscription API error - Status: ${response.statusCode}, Response: $responseData',
        );
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to create subscription',
          'errors': responseData['errors'],
        };
      }
    } catch (e) {
      if (e is dio.DioException) {
        AppLogger.instance.log(
          'DioException in createSubscription - Status: ${e.response?.statusCode}, Error: ${e.message}',
        );
        AppLogger.instance.log('DioException response: ${e.response?.data}');

        if (e.response?.statusCode == 401) {
          return {
            'success': false,
            'message': 'Session expired - please login again',
            'requiresLogin': true,
          };
        }
        final responseData = e.response?.data;
        if (responseData is Map) {
          return {
            'success': false,
            'message':
                responseData['message'] ??
                responseData['detail'] ??
                'Failed to create subscription',
            'errors': responseData['errors'] ?? responseData,
          };
        }
        return {
          'success': false,
          'message': e.message ?? 'Network error creating subscription',
          'error': e.toString(),
        };
      }
      AppLogger.instance.log('Unexpected error in createSubscription: $e');
      return {
        'success': false,
        'message': 'An error occurred while creating the subscription',
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> getSubscriptionsbyId(int id) async {
    try {
      final response = await ApiClient.instance.get(
        '${ApiConfig.subscriptionsEndpoint}/plans/$id/',
      );

      if (response.statusCode != 200) {
        return {
          'success': false,
          'message': 'Failed to fetch subscriptions: ${response.statusCode}',
        };
      }

      final parsedData = response.data;

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
      AppLogger.instance.log('Error fetching subscriptions: $e');
      return {
        'success': false,
        'message': 'An error occurred while fetching subscriptions',
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> getSubscriptions() async {
    try {
      final response = await ApiClient.instance.get(
        ApiConfig.subscriptionsEndpoint,
      );

      if (response.statusCode != 200) {
        final errorBody = response.data;
        return {
          'success': false,
          'message': errorBody['detail'] ?? 'Failed to load subscriptions.',
        };
      }

      final allSubscriptions = _parseSubscriptions(response.data);

      return {'success': true, 'data': allSubscriptions};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getSubscriptionDetails(
    int subscriptionId,
  ) async {
    try {
      final response = await ApiClient.instance.get(
        '$subscriptionsEndpoint/$subscriptionId/',
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        final dataMap =
            responseData is Map && responseData.containsKey('data')
                ? responseData['data']
                : responseData;
        return {
          'success': true,
          'data': Subscription.fromJson(dataMap),
          'message': 'Subscription details fetched successfully',
        };
      } else {
        final responseData = response.data;
        return {
          'success': false,
          'message':
              responseData['message'] ??
              responseData['detail'] ??
              'Failed to fetch subscription details',
        };
      }
    } catch (e) {
      if (e is dio.DioException && e.response?.statusCode == 401) {
        return {
          'success': false,
          'message': 'Session expired',
          'requiresLogin': true,
        };
      }
      return {
        'success': false,
        'message': 'An error occurred while fetching subscription details',
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> cancelSubscription(int subscriptionId) async {
    try {
      final response = await ApiClient.instance.post(
        '$subscriptionsEndpoint/$subscriptionId/cancel/',
      );

      final responseData = response.data;

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Subscription cancelled successfully',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to cancel subscription',
        };
      }
    } catch (e) {
      AppLogger.instance.log('Error cancelling subscription: $e');
      if (e is dio.DioException && e.response?.statusCode == 401) {
        return {
          'success': false,
          'message': 'Session expired',
          'requiresLogin': true,
        };
      }
      return {
        'success': false,
        'message': 'An error occurred while cancelling the subscription',
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> getSubscriptionPlans() async {
    try {
      final response = await ApiClient.instance.get(
        ApiConfig.subscriptionPlansEndpoint,
      );

      if (response.statusCode != 200) {
        return {
          'success': false,
          'message':
              'Failed to fetch subscription plans: ${response.statusCode}',
        };
      }

      final List<dynamic> responseData = response.data;
      final plans =
          responseData.map((item) => SubscriptionPlan.fromJson(item)).toList();

      return {
        'success': true,
        'data': plans,
        'message': 'Subscription plans fetched successfully',
      };
    } catch (e) {
      AppLogger.instance.log('Error fetching subscription plans: $e');
      return {
        'success': false,
        'message': 'An error occurred while fetching subscription plans',
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> subscribeToPlan(int planId) async {
    try {
      final response = await ApiClient.instance.post(
        '$subscriptionsEndpoint/subscribe/',
        data: {'plan_id': planId},
      );

      final responseData = response.data;
      AppLogger.instance.log('Subscribe to plan response: $responseData');

      if (response.statusCode == 201) {
        return {
          'success': true,
          'data': Subscription.fromJson(responseData),
          'message': 'Successfully subscribed to plan',
        };
      } else {
        AppLogger.instance.log(
          'Subscribe to plan error: ${responseData['message']}',
        );
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to subscribe to plan',
          'errors': responseData['errors'],
        };
      }
    } catch (e) {
      AppLogger.instance.log('Error subscribing to plan: $e');
      if (e is dio.DioException && e.response?.statusCode == 401) {
        return {
          'success': false,
          'message': 'Session expired',
          'requiresLogin': true,
        };
      }
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
      final response = await ApiClient.instance.post(
        '$subscriptionsEndpoint/$subscriptionId/pause/',
        data:
            pauseStartDate != null && pauseEndDate != null
                ? {
                  'pause_start_date':
                      pauseStartDate.toIso8601String().split('T')[0],
                  'pause_end_date':
                      pauseEndDate.toIso8601String().split('T')[0],
                }
                : null,
      );

      final responseData = response.data;

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'],
          'pause_start_date': responseData['pause_start_date'],
          'pause_end_date': responseData['pause_end_date'],
          'next_delivery_date': responseData['next_delivery_date'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['detail'] ?? 'Failed to pause subscription',
        };
      }
    } catch (e) {
      AppLogger.instance.log('Error pausing subscription: $e');
      if (e is dio.DioException && e.response?.statusCode == 401) {
        return {
          'success': false,
          'message': 'Session expired',
          'requiresLogin': true,
        };
      }
      return {
        'success': false,
        'message': 'An error occurred while pausing the subscription',
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> getSubscriptionPlanProducts(int planId) async {
    try {
      final response = await ApiClient.instance.get(
        '/api/subscriptions/plans/$planId/products',
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return {
          'success': true,
          'data': SubscriptionPlanProductsResponse.fromJson(data),
        };
      } else {
        AppLogger.instance.log(
          'Failed to fetch plan products. Status: ${response.statusCode}',
        );
        return {'success': false, 'message': 'Failed to fetch plan products'};
      }
    } catch (e) {
      AppLogger.instance.log('Error fetching subscription plan products: $e');
      if (e is dio.DioException && e.response?.statusCode == 401) {
        return {
          'success': false,
          'message': 'Authentication failed',
          'requiresLogin': true,
        };
      }
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
      final response = await ApiClient.instance.get(
        '/api/payments/subscription-status/$subscriptionId/',
      );
      if (response.statusCode == 200) {
        final data = response.data;
        return SubscriptionPaymentStatus.fromJson(data);
      } else {
        return null;
      }
    } catch (e) {
      AppLogger.instance.log('Error fetching subscription payment status: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> RepaymentSubscription(int planId) async {
    try {
      final response = await ApiClient.instance.post(
        '$subscriptionsEndpoint/$planId/next-installment-payment/',
      );

      final responseData = response.data;
      AppLogger.instance.log('Repayment subscription response: $responseData');

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (responseData is Map &&
            responseData.containsKey('payment_links') &&
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
      AppLogger.instance.log('Error repaying subscription: $e');
      return {
        'success': false,
        'message': 'An error occurred while repaying the subscription',
        'error': e.toString(),
      };
    }
  }

  Future<ApiResponse> getSubscriptionInvoices(int subscriptionId) async {
    try {
      final response = await ApiClient.instance.get(
        '/api/invoicing/subscriptions/$subscriptionId/invoices/',
      );

      if (response.statusCode == 200) {
        return ApiResponse.fromJson(response.data);
      } else {
        final errorData = response.data;
        throw Exception(
          errorData['message'] ??
              'Failed to load invoices: Status code ${response.statusCode}',
        );
      }
    } catch (e) {
      AppLogger.instance.log('Error getting subscription invoices: $e');
      throw Exception(
        'An error occurred while fetching your invoices. Please try again.',
      );
    }
  }

  Future<String> downloadInvoice(String s3Url, String displayName) async {
    try {
      final isInternalUrl = s3Url.startsWith(ApiConfig.baseUrl);
      dio.Response<List<int>> pdfResponse;

      if (isInternalUrl) {
        pdfResponse = await ApiClient.instance.get<List<int>>(
          s3Url,
          options: dio.Options(responseType: dio.ResponseType.bytes),
        );
      } else {
        pdfResponse = await dio.Dio().get<List<int>>(
          s3Url,
          options: dio.Options(responseType: dio.ResponseType.bytes),
        );
      }

      if (pdfResponse.statusCode == 200 && pdfResponse.data != null) {
        String? savedPath;

        if (Platform.isAndroid) {
          try {
            await Permission.storage.request();

            final downloadsPath = '/storage/emulated/0/Download';
            final directory = Directory(downloadsPath);

            if (await directory.exists()) {
              final sanitizedDisplayName = displayName.replaceAll(
                RegExp(r'[\\/:*?"<>|]'),
                '_',
              );
              final filePath = '$downloadsPath/$sanitizedDisplayName.pdf';
              final file = File(filePath);

              await file.writeAsBytes(pdfResponse.data!);
              savedPath = filePath;
            }
          } catch (e) {
            AppLogger.instance.log('Could not save to Downloads: $e');
          }
        }

        if (savedPath == null) {
          final dir = await getTemporaryDirectory();
          final sanitizedDisplayName = displayName.replaceAll(
            RegExp(r'[\\/:*?"<>|]'),
            '_',
          );
          final filePath = '${dir.path}/$sanitizedDisplayName.pdf';
          final file = File(filePath);
          await file.writeAsBytes(pdfResponse.data!);
          savedPath = filePath;
        }

        AppLogger.instance.log(
          'Invoice downloaded successfully to: $savedPath',
        );
        await OpenFilex.open(savedPath);
        return savedPath;
      } else {
        throw Exception(
          'Failed to download PDF: ${pdfResponse.statusCode} ${pdfResponse.statusMessage}',
        );
      }
    } catch (e) {
      AppLogger.instance.log('Error downloading invoice: $e');
      throw Exception('Failed to download invoice: $e');
    }
  }
}
