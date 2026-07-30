import 'dart:io';
import 'package:dio/dio.dart' as dio;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:grocery_app/services/api_client.dart';
import 'package:grocery_app/services/api_exception.dart';
import 'package:grocery_app/services/api_config.dart';
import 'package:grocery_app/utils/app_logger.dart';
import 'package:grocery_app/models/order_model.dart';
import 'package:grocery_app/models/order_tracking_model.dart';

abstract class OrdersRemoteDataSource {
  Future<ShippingDetails?> getUserShippingDetails();
  Future<dynamic> createOrder(OrderModel order);
  Future<List<Order>> getOrders();
  Future<Order> getOrderById(int orderId);
  Future<OrderTracking?> getOrderTracking(String orderNumber);
  Future<Map<String, dynamic>> cancelOrder(int orderId, {String? reason});
  Future<String> downloadInvoice(String orderNumber);
}

class OrdersRemoteDataSourceImpl implements OrdersRemoteDataSource {
  final ApiClient _apiClient;

  OrdersRemoteDataSourceImpl({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  @override
  Future<ShippingDetails?> getUserShippingDetails() async {
    try {
      final response = await _apiClient.get('/api/user/details/');
      if (response.statusCode == 200) {
        final data = response.data;
        return ShippingDetails(
          address: data['shipping_address'] ?? '',
          name: data['shipping_name'] ?? '',
          city: data['shipping_city'] ?? '',
          state: data['shipping_state'] ?? '',
          pincode: data['shipping_pincode'] ?? '',
          phone: data['shipping_phone'] ?? '',
        );
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw ApiException('Failed to load shipping details', response.statusCode ?? 500);
      }
    } catch (e) {
      AppLogger.instance.log('Error loading shipping details: $e');
      if (e is ApiException) rethrow;
      throw Exception('Failed to load shipping details: $e');
    }
  }

  @override
  Future<dynamic> createOrder(OrderModel order) async {
    try {
      if (order.shippingAddress.isEmpty ||
          order.shippingCity.isEmpty ||
          order.shippingState.isEmpty ||
          order.shippingPincode.isEmpty ||
          order.shippingPhone.isEmpty) {
        throw Exception('Incomplete shipping details');
      }

      final response = await _apiClient.post(
        '/api/orders/create/',
        data: order.toJson(),
      );

      if (response.statusCode == 201) {
        final data = response.data;
        if (data is Map &&
            (data.containsKey('checkout_url') ||
             data.containsKey('access_key') ||
             data.containsKey('payment_required'))) {
          return OrderCreateResponse.fromJson(Map<String, dynamic>.from(data));
        }
        return Order.fromJson(data);
      } else {
        throw ApiException(response.data?.toString() ?? 'Server error', response.statusCode ?? 500);
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

  @override
  Future<List<Order>> getOrders() async {
    try {
      final response = await _apiClient.get('/api/orders/');
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

  @override
  Future<Order> getOrderById(int orderId) async {
    try {
      final response = await _apiClient.get('/api/orders/$orderId/');
      if (response.statusCode == 200) {
        final data = response.data;
        final orderData =
            data is Map && data.containsKey('data') ? data['data'] : data;
        return Order.fromJson(orderData);
      } else {
        throw Exception('Failed to fetch order (Status: ${response.statusCode})');
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

  @override
  Future<OrderTracking?> getOrderTracking(String orderNumber) async {
    try {
      final response = await _apiClient.get(
        ApiConfig.orderTrackingEndpoint(orderNumber),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return OrderTracking.fromJson(data);
      } else {
        return null;
      }
    } catch (e) {
      AppLogger.instance.log('Error fetching order tracking: $e');
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>> cancelOrder(int orderId, {String? reason}) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.ordersEndpoint}$orderId/cancel-request/',
        data: reason != null ? {'reason': reason} : null,
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        final isSuccess = responseData['status'] == 'success' ||
            responseData['refund_initiated'] == true ||
            responseData['message'] != null;
        if (isSuccess) {
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

  @override
  Future<String> downloadInvoice(String orderNumber) async {
    try {
      final response = await _apiClient.get(
        '/api/invoicing/orders/$orderNumber/invoice/',
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true && data['invoice'] != null) {
          final invoiceData = data['invoice'];
          final s3Url = invoiceData['s3_url'];
          final displayName =
              invoiceData['display_name'] ?? 'Invoice-$orderNumber';

          // Download PDF using simple dio (no auth header needed for S3)
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

            AppLogger.instance.log('Invoice downloaded to: $savedPath');
            await OpenFilex.open(savedPath);
            return savedPath;
          } else {
            throw Exception('Failed to download PDF from S3: ${pdfResponse.statusCode}');
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
