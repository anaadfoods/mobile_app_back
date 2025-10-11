import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:grocery_app/models/order_model.dart';
import 'package:grocery_app/services/auth_service.dart';
import 'package:grocery_app/services/api_config.dart';
import 'package:grocery_app/models/payment_status_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_filex/open_filex.dart'; // To open the downloaded file


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
  Future<dynamic> createOrder(OrderModel order ) async {
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
        throw Exception('Incomplete shipping details');
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
        print('Order created successfully: $data');
        // If payment_links is present, return OrderCreateResponse
        if (data is Map && data.containsKey('payment_links')) {
          return OrderCreateResponse.fromJson(Map<String, dynamic>.from(data));
        }
        return OrderModel.fromJson(data);
      } else {
        final errorData = jsonDecode(response.body);
        print('Server error response: $errorData');
        throw errorData;
      }
    } catch (e) {
      print('Order creation error: $e');
      if (e is FormatException) {
        throw Exception('Invalid response format from server');
      } else if (e is http.ClientException) {
        throw Exception('Network error while creating order: ${e.message}');
      } else if (e is Map<String, dynamic>) {
        // This is a server error response, pass it through
        rethrow;
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

  Future<OrderModel> getOrderById(int orderId) async {
    final token = await _authService.getAccessToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/orders/$orderId/'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return OrderModel.fromJson(data);
    } else {
      throw Exception('Failed to fetch order details');
    }
  }

  Future<bool> cancelOrder(int orderId) async {
    try {
      final isAuthenticated = await _authService.isLoggedIn();
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      final response = await http
          .post(
            Uri.parse(
              '$baseUrl${ApiConfig.ordersEndpoint}$orderId/cancel-request/',
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
          return cancelOrder(orderId);
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

  Future<PaymentStatus> fetchPaymentStatus(int orderId) async {
    final token = await _authService.getAccessToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/payments/status/$orderId/'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return PaymentStatus.fromJson(data);
    } else {
      throw Exception('Failed to fetch payment status');
    }
  }

  final String _endpoint = "http://65.2.69.45:5000/handleJuspayResponse";

  /// Posts the order_id to the Juspay response handler.
  /// Returns the HTTP response.
  Future<http.Response> postOrderId(String orderId) async {
    // Body as x-www-form-urlencoded
    final Map<String, String> body = {'order_id': orderId};

    // Headers (optional - http package sets Content-Type automatically)
    final Map<String, String> headers = {
      'Content-Type': 'application/x-www-form-urlencoded',
    };

    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: headers,
        body: body,
      );
      print(response);
      return response;
    } catch (e) {
      throw Exception('Failed to post order_id: $e');
    }
  }





// Helper function to get the downloads directory
Future<String?> _getDownloadsDirectoryPath() async {
  Directory? directory;
  try {
    if (Platform.isIOS) {
      // iOS doesn't have a standard "Downloads" folder.
      // We use the application's documents directory.
      directory = await getApplicationDocumentsDirectory();
    } else {
      // Android has a public downloads directory.
      directory = Directory('/storage/emulated/0/Download');
      //
      // If the directory doesn't exist, try to create it.
      // This can fail if permissions are not granted.
      if (!await directory.exists()) {
        directory = await getExternalStorageDirectory();
      }
    }
  } catch (err) {
    print("Cannot get download directory: $err");
  }
  return directory?.path;
}

Future<String> downloadOrderInvoice(String orderNumber) async {
  try {
  
    final token = await _authService.getAccessToken();
    if (token == null) throw Exception('Authentication required');
    
    final response = await http.get(
      Uri.parse('$baseUrl/api/odoo/orders/$orderNumber/invoice/'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['invoice'] != null) {
        final invoiceData = data['invoice'];
        final s3Url = invoiceData['s3_url'];
        final displayName = invoiceData['display_name'] ?? 'Invoice-$orderNumber';

        // Download the PDF from S3 (without auth headers)
        final pdfResponse = await http.get(Uri.parse(s3Url));

        if (pdfResponse.statusCode == 200) {
          // 📂 2. Get the correct downloads path
            print(pdfResponse.statusCode);
          final downloadsPath = await _getDownloadsDirectoryPath();
          print(downloadsPath);
          if (downloadsPath == null) {
            throw Exception("Could not find the downloads directory.");
          }

          final sanitizedDisplayName = displayName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
          final filePath = '$downloadsPath/$sanitizedDisplayName.pdf';
          final file = File(filePath);

          // Write the PDF bytes to the file
          await file.writeAsBytes(pdfResponse.bodyBytes);
          print('Invoice downloaded successfully to: $filePath');

          // 🚀 3. Open the downloaded file
                final openResult = await OpenFilex.open(filePath);

          // final openResult = await OpenFile.open(filePath);
          // print('OpenFile result: ${openResult.message}');

          return filePath;
        } else {
          throw Exception('Failed to download PDF from S3: ${pdfResponse.statusCode}');
        }
      } else {
        throw Exception('Invoice not available for this order');
      }
    } else if (response.statusCode == 404) {
      throw Exception('Invoice not found for this order');
    } else {
      throw Exception('Failed to get invoice data: ${response.statusCode}');
    }
  } catch (e) {
    print('Error downloading invoice: $e');
    throw Exception('Failed to download invoice: $e');
  }
}



// Add open_file_plus to your pubspec.yaml for a better user experience
// // import 'package:open_file_plus/open_file_plus.dart';

// Future<String> downloadOrderInvoice(String orderNumber) async {
//   try {
//     // This token is for YOUR API, not for AWS S3.
//     final token = await _authService.getAccessToken();
//     if (token == null) {
//       throw Exception('Authentication required');
//     }

//     // 1. Get the invoice data (including the S3 URL) from your API
//     final response = await http.get(
//       Uri.parse('$baseUrl/api/odoo/orders/$orderNumber/invoice/'),
//       headers: await _getHeaders(), // Assuming _getHeaders() adds the Bearer token
//     );

//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);

//       if (data['success'] == true && data['invoice'] != null) {
//         final invoiceData = data['invoice'];
//         final s3Url = invoiceData['s3_url'];
//         final displayName = invoiceData['display_name'] ?? 'Invoice-$orderNumber';

//         // 2. Download the PDF from the pre-signed S3 URL
//         // REMOVED the headers from this call. S3 pre-signed URLs
//         // do not need an Authorization header.
//         final pdfResponse = await http.get(Uri.parse(s3Url));

//         if (pdfResponse.statusCode == 200) {
//           // Get a reliable, cross-platform temporary directory
//           final dir = await getTemporaryDirectory();
          
//           // Sanitize the filename to remove characters invalid for file systems
//           final sanitizedDisplayName = displayName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
//           final filePath = '${dir.path}/$sanitizedDisplayName.pdf';
//           final file = File(filePath);

//           // Write the PDF bytes to the file
//           await file.writeAsBytes(pdfResponse.bodyBytes);

//           print('Invoice downloaded successfully to: $filePath');
          
//           // Optional: Open the file for the user immediately
//           // await OpenFile.open(filePath);

//           return filePath;
//         } else {
//           throw Exception(
//             'Failed to download PDF from S3: ${pdfResponse.statusCode}',
//           );
//         }
//       } else {
//         throw Exception('Invoice not available for this order');
//       }
//     } else if (response.statusCode == 404) {
//       throw Exception('Invoice not found for this order');
//     } else {
//       final errorData = jsonDecode(response.body);
//       throw Exception(errorData['message'] ?? 'Failed to get invoice');
//     }
//   } catch (e) {
//     print('Error downloading invoice: $e');
//     throw Exception('Failed to download invoice: $e');
//   }
// }


  

  // /// Downloads the invoice for a specific order
  // /// Returns the file path where the invoice was saved
  // Future<String> downloadOrderInvoice(String orderNumber) async {
  //   try {
  //     final token = await _authService.getAccessToken();
  //     if (token == null) {
  //       throw Exception('Authentication required');
  //     }

  //     // First, get the invoice data from the API
  //     final response = await http.get(
  //       Uri.parse('$baseUrl/odoo/orders/$orderNumber/invoice/'),
  //       headers: await _getHeaders(),
  //     );

  //     if (response.statusCode == 200) {
  //       final data = jsonDecode(response.body);
  //       print("REsponse for the data invoice is $data");

  //       if (data['success'] == true && data['invoice'] != null) {
  //         final invoiceData = data['invoice'];
  //         final s3Url = invoiceData['s3_url'];
  //         final displayName =
  //             invoiceData['display_name'] ?? 'Invoice-$orderNumber';

  //         // Download the PDF from S3 URL
  //         final pdfResponse = await http.get(
  //           Uri.parse(s3Url),
  //           headers: {'Authorization': 'Bearer $token'},
  //         );

  //         if (pdfResponse.statusCode == 200) {
  //           // Get the downloads directory
  //           Directory? downloadsDir;
  //           if (Platform.isAndroid) {
  //             downloadsDir = Directory('/storage/emulated/0/Download');
  //           } else if (Platform.isIOS) {
  //             downloadsDir = await getApplicationDocumentsDirectory();
  //           } else {
  //             downloadsDir = await getApplicationDocumentsDirectory();
  //           }

  //           // Create the directory if it doesn't exist
  //           if (!await downloadsDir.exists()) {
  //             await downloadsDir.create(recursive: true);
  //           }

  //           // Create the file path
  //           final fileName = '$displayName.pdf';
  //           final filePath = '${downloadsDir.path}/$fileName';
  //           final file = File(filePath);

  //           // Write the PDF bytes to the file
  //           await file.writeAsBytes(pdfResponse.bodyBytes);

  //           print('Invoice downloaded successfully to: $filePath');
  //           return filePath;
  //         } else {
  //           throw Exception(
  //             'Failed to download PDF: ${pdfResponse.statusCode}',
  //           );
  //         }
  //       } else {
  //         throw Exception('Invoice not available for this order');
  //       }
  //     } else if (response.statusCode == 404) {

  //       throw Exception('Invoice not found for this order');
  //     } else {
  //       final errorData = jsonDecode(response.body);
  //       throw Exception(errorData['message'] ?? 'Failed to get invoice');
  //     }
  //   } catch (e) {
  //     print('Error downloading invoice: $e');
  //     throw Exception('Failed to download invoice: $e');
  //   }
  // }
}
