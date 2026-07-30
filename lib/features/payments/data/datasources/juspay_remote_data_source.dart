import 'package:dio/dio.dart' as dio;
import 'package:grocery_app/services/api_client.dart';
import 'package:grocery_app/services/payment_client.dart';
import '../models/payment_status_model.dart';

class JuspayRemoteDataSource {
  final ApiClient _apiClient;
  final PaymentClient _paymentClient;

  JuspayRemoteDataSource({
    ApiClient? apiClient,
    PaymentClient? paymentClient,
  })  : _apiClient = apiClient ?? ApiClient.instance,
        _paymentClient = paymentClient ?? PaymentClient.instance;

  Future<PaymentStatusModel> fetchStatus(String reference) async {
    final response = await _apiClient.get(
      '/api/payments/status/$reference/',
    );
    return PaymentStatusModel.fromJson(
      Map<String, dynamic>.from(response.data),
    );
  }

  Future<void> verifyJuspayResponse(String orderId) async {
    final Map<String, String> body = {'order_id': orderId};
    await _paymentClient.post(
      '/handleJuspayResponse',
      data: body,
      options: dio.Options(
        contentType: dio.Headers.formUrlEncodedContentType,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
  }
}
