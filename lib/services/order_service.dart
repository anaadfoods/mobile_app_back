import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:grocery_app/models/order_model.dart';
import 'package:grocery_app/services/auth_service.dart';
import 'package:grocery_app/services/api_config.dart';

class OrderService {
  // static const String baseUrl = 'http://192.168.19.81:8000';
  // static const String baseUrl = 'http://192.168.19.81:8000';
  final String baseUrl = ApiConfig.baseUrl;

  static const String createOrderEndpoint = '/api/orders/create/';
  static const String getorders = '/api/orders/';
  static const String userDetailsEndpoint = '/api/user/details/';
  static const int timeoutSeconds = 30;

  final AuthService _authService = AuthService();

  // Singleton instance
  static final OrderService _instance = OrderService._internal();
  factory OrderService() {
    return _instance;
  }

  OrderService._internal();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Get user's shipping details if they exist
  Future<ShippingDetails?> getUserShippingDetails() async {
    try {
      final token = await _authService.getAccessToken();
      if (token == null) {
        return null;
      }

      final response = await http.get(
        Uri.parse('$baseUrl$userDetailsEndpoint'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ShippingDetails(
          name: data['name'] ?? '',
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
      print('Error loading shipping details: $e');
      return null;
    }
  }

  // Create a new order
  Future<OrderModel> createOrder(OrderModel order) async {
    try {
      final token = await _authService.getAccessToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      print('Creating order with data: ${jsonEncode(order.toJson())}');

      // Validate shipping details
      if (order.shippingAddress.isEmpty ||
          order.shippingCity.isEmpty ||
          order.shippingState.isEmpty ||
          order.shippingPincode.isEmpty ||
          order.shippingPhone.isEmpty) {
        //   final currentUser = await _authService.currentUser;
        //   if (currentUser != null) {
        //     final user = await _authService.getUserData();
        //     if (user != null) {
        //       order.shippingName = user.name;
        //       order.shippingEmail = user.email;
        //       order.shippingPhone = user.phone;

        throw Exception('Incomplete shipping details');
        // }
      }

      final response = await http.post(
        Uri.parse('$baseUrl$createOrderEndpoint'),
        headers: await _getHeaders(),
        body: jsonEncode(order.toJson()),
      );

      print('Order creation response: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print('Order created successfully: ${data}');
        return OrderModel.fromJson(data);
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage =
            errorData['message'] ??
            errorData['error'] ??
            'Failed to create order';
        print('Server error response: $errorData');
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Order creation error: $e');
      if (e is FormatException) {
        throw Exception('Invalid response format from server');
      } else if (e is http.ClientException) {
        throw Exception('Network error while creating order: ${e.message}');
      }
      throw Exception('Failed to create order: $e');
    }
  }

  Future<List<Order>> getOrders() async {
    try {
      final isAuthenticated = await _authService.isLoggedIn();
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      final response = await http
          .get(Uri.parse('$baseUrl$getorders'), headers: await _getHeaders())
          .timeout(Duration(seconds: timeoutSeconds));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data.map((json) => Order.fromJson(json)).toList();
        } else if (data is Map && data['data'] is List) {
          return (data['data'] as List)
              .map((json) => Order.fromJson(json))
              .toList();
        } else {
          throw Exception('Unexpected response format');
        }
      } else if (response.statusCode == 401) {
        final refreshed = await _authService.refreshAccessToken();
        if (refreshed) {
          return getOrders();
        }
        throw Exception('Authentication failed');
      } else {
        throw Exception('Failed to fetch orders: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Failed to fetch orders: $e');
    }
  }

  Future<bool> cancelOrder(String orderNumber) async {
    try {
      final isAuthenticated = await _authService.isLoggedIn();
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      final response = await http
          .post(
            Uri.parse(
              '$baseUrl${ApiConfig.ordersEndpoint}$orderNumber/cancel-request/',
            ),
            headers: await _getHeaders(),
          )
          .timeout(Duration(seconds: timeoutSeconds));

      print('Cancel order response: ${response.statusCode}');
      print('Cancel order body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 'success') {
          // Refresh the orders list after successful cancellation
          await getOrders();
          return true;
        }
        return false;
      } else if (response.statusCode == 401) {
        final refreshed = await _authService.refreshAccessToken();
        if (refreshed) {
          return cancelOrder(orderNumber);
        }
        throw Exception('Authentication failed');
      } else {
        final responseData = jsonDecode(response.body);
        throw Exception(responseData['message'] ?? 'Failed to cancel order');
      }
    } catch (e) {
      print('Error cancelling order: $e');
      throw Exception('Failed to cancel order: $e');
    }
  }
}
