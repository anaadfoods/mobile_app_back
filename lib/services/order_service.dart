import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:grocery_app/models/order_tracking_model.dart';
import 'package:grocery_app/services/payment_client.dart';
import 'package:dio/dio.dart' as dio;

class OrderService {
  final String baseUrl = ApiConfig.baseUrl;

  static const String createOrderEndpoint = '/api/orders/create/';
  static const String getorders = '/api/orders/';
  static const String userDetailsEndpoint = '/api/user/details/';
  static const int timeoutSeconds = 30;

  factory OrderService() => getIt<OrderService>();

  OrderService._internal();
  static OrderService create() => OrderService._internal();

  // Get user's shipping details if they exist
  Future<ShippingDetails?> getUserShippingDetails() async {
    try {
      final response = await ApiClient.instance.get(userDetailsEndpoint);

      if (response.statusCode == 200) {
        final data = response.data;
        return ShippingDetails(
          address: data['shipping_address'] ?? '',
          city: data['shipping_city'] ?? '',
          state: data['shipping_state'] ?? '',
          pincode: data['shipping_pincode'] ?? '',
          phone: data['shipping_phone'] ?? '',
        );
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to load shipping details');
      }
    } catch (e) {
      AppLogger.instance.log('Error loading shipping details: $e');
      return null;
    }
  }

  // Create a new order
  Future<dynamic> createOrder(OrderModel order) async {
    try {
      AppLogger.instance.log(
        'Creating order with data: ${jsonEncode(order.toJson())}',
      );

      // Validate shipping details
      if (order.shippingAddress.isEmpty ||
          order.shippingCity.isEmpty ||
          order.shippingState.isEmpty ||
          order.shippingPincode.isEmpty ||
          order.shippingPhone.isEmpty) {
        throw Exception('Incomplete shipping details');
      }

      final response = await ApiClient.instance.post(
        createOrderEndpoint,
        data: order.toJson(),
      );

      AppLogger.instance.log('Order creation response: ${response.statusCode}');
      AppLogger.instance.log('Response body: ${response.data}');

      if (response.statusCode == 201) {
        final data = response.data;
        AppLogger.instance.log('Order created successfully: $data');
        // Online payment: backend returns checkout fields in the create response
        if (data is Map &&
            (data.containsKey('checkout_url') ||
             data.containsKey('access_key') ||
             data.containsKey('payment_required'))) {
          return OrderCreateResponse.fromJson(Map<String, dynamic>.from(data));
        }
        return Order.fromJson(data);
      } else {
        final errorData = response.data;
        AppLogger.instance.log('Server error response: $errorData');
        throw errorData;
      }
    } catch (e) {
      AppLogger.instance.log('Order creation error: $e');
      if (e is dio.DioException) {
        final data = e.response?.data;
        if (data is Map<String, dynamic>) {
          throw data;
        }
        throw Exception('Network error while creating order: ${e.message}');
      }
      rethrow;
    }
  }

  Future<List<Order>> getOrders() async {
    try {
      final response = await ApiClient.instance.get(getorders);

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return data.map((json) => Order.fromJson(json)).toList();
        } else if (data is Map && data['data'] is List) {
          return (data['data'] as List)
              .map((json) => Order.fromJson(json))
              .toList();
        } else {
          throw Exception('Unexpected response format');
        }
      } else {
        throw Exception('Failed to fetch orders: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Failed to fetch orders: $e');
    }
  }

  Future<Order> getOrderById(int orderId) async {
    try {
      final response = await ApiClient.instance.get('/api/orders/$orderId/');
      if (response.statusCode == 200) {
        final data = response.data;
        final orderData =
            data is Map && data.containsKey('data') ? data['data'] : data;
        return Order.fromJson(orderData);
      } else {
        throw Exception(
          'Failed to fetch order (Status: ${response.statusCode})',
        );
      }
    } catch (e) {
      if (e is dio.DioException) {
        final data = e.response?.data;
        if (data is Map) {
          throw Exception(
            data['message'] ??
                data['detail'] ??
                'Failed to fetch order details',
          );
        }
      }
      throw Exception('Failed to fetch order: $e');
    }
  }

  /// Fetches order tracking/shipment data for the given order number.
  /// Returns OrderTracking with AWB, estimated delivery, and tracking events.
  Future<OrderTracking?> getOrderTracking(String orderNumber) async {
    try {
      final response = await ApiClient.instance.get(
        ApiConfig.orderTrackingEndpoint(orderNumber),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return OrderTracking.fromJson(data);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        AppLogger.instance.log(
          'Failed to fetch tracking: ${response.statusCode}',
        );
        return null;
      }
    } catch (e) {
      AppLogger.instance.log('Error fetching order tracking: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> cancelOrder(int orderId, {String? reason}) async {
    try {
      final response = await ApiClient.instance.post(
        '${ApiConfig.ordersEndpoint}$orderId/cancel-request/',
        data: reason != null ? {'reason': reason} : null,
      );

      AppLogger.instance.log('Cancel order response: ${response.statusCode}');
      AppLogger.instance.log('Cancel order body: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;
        final isSuccess = responseData['status'] == 'success' ||
            responseData['refund_initiated'] == true ||
            responseData['message'] != null;
        if (isSuccess) {
          await getOrders();
          return {
            'success': true,
            'message': responseData['message'] ?? 'Order cancelled successfully',
            'refund_initiated': responseData['refund_initiated'] ?? false,
            'order_number': responseData['order_number'],
            'current_status': responseData['current_status'],
            'raw_data': responseData,
          };
        }
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to cancel order',
        };
      } else {
        final responseData = response.data;
        final message = responseData['message'] ?? 'Failed to cancel order';
        throw ApiException(message, response.statusCode ?? 500);
      }
    } catch (e) {
      AppLogger.instance.log('Error cancelling order: $e');
      if (e is ApiException) rethrow;
      if (e is dio.DioException) {
        final responseData = e.response?.data;
        if (responseData is Map) {
          final message = responseData['message'] ?? 'Failed to cancel order';
          throw ApiException(message, e.response?.statusCode ?? 500);
        }
      }
      throw ApiException('Failed to cancel order: $e');
    }
  }



  /// Posts the order_id to the Juspay response handler using secure payment client.
  /// Uses HTTPS with certificate pinning for financial endpoint protection.
  /// Returns the HTTP response.
  Future<dio.Response> postOrderId(String orderId) async {
    final Map<String, String> body = {'order_id': orderId};

    try {
      // Use PaymentClient which has certificate pinning enabled
      final response = await PaymentClient.instance.post(
        '/handleJuspayResponse',
        data: body,
        options: dio.Options(
          contentType: dio.Headers.formUrlEncodedContentType,
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );
      AppLogger.instance.log("postOrderId response: ${response.statusCode}");
      return response;
    } catch (e) {
      AppLogger.instance.log('Failed to post order_id: $e');
      throw Exception('Failed to post order_id to secure payment endpoint: $e');
    }
  }

  Future<String> downloadOrderInvoice(String orderNumber) async {
    try {
      final response = await ApiClient.instance.get(
        '/api/invoicing/orders/$orderNumber/invoice/',
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true && data['invoice'] != null) {
          final invoiceData = data['invoice'];
          final s3Url = invoiceData['s3_url'];
          final displayName =
              invoiceData['display_name'] ?? 'Invoice-$orderNumber';

          // Download the PDF from S3 (using vanilla Dio without auth headers)
          final pdfResponse = await dio.Dio().get<List<int>>(
            s3Url,
            options: dio.Options(responseType: dio.ResponseType.bytes),
          );

          if (pdfResponse.statusCode == 200 && pdfResponse.data != null) {
            String? savedPath;

            if (Platform.isAndroid) {
              try {
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
              'Failed to download PDF from S3: ${pdfResponse.statusCode}',
            );
          }
        } else {
          throw Exception('Invoice not available for this order');
        }
      } else if (response.statusCode == 404) {
        throw Exception('No invoice available please wait for some time');
      } else {
        throw Exception('Failed to get invoice data: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.instance.log('Error downloading invoice: $e');
      if (e.toString().contains('No invoice available')) {
        rethrow;
      }
      throw Exception('Failed to download invoice: $e');
    }
  }
}
