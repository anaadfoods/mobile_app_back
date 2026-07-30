import 'package:grocery_app/services/api_client.dart';
import '../models/payment_status_model.dart';

class EasebuzzRemoteDataSource {
  final ApiClient _apiClient;

  EasebuzzRemoteDataSource({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient.instance;

  Future<PaymentStatusModel> fetchStatus(String reference) async {
    final response = await _apiClient.get(
      '/api/payments/status/$reference/',
    );
    return PaymentStatusModel.fromJson(
      Map<String, dynamic>.from(response.data),
    );
  }
}
