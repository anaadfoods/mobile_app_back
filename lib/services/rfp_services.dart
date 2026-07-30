import 'package:grocery_app/services/token_service.dart';
import '../models/rfp_plan_model.dart';
import '../models/rfp_delivery_model.dart';
import '../common_widgets/global_import.dart';

import 'package:grocery_app/service_locator.dart';

class DeliveryService {
  factory DeliveryService() => getIt<DeliveryService>();
  DeliveryService.create();

  final TokenService _tokenService = getIt<TokenService>();

  Future<String?> _getToken() async {
    return await _tokenService.getAccessToken();
  }

  Future<List<RfpPlan>> fetchPlans() async {
    try {
      final response = await ApiClient.instance.get('/api/rfp/plans/');

      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = response.data;
        return jsonResponse.map((data) => RfpPlan.fromJson(data)).toList();
      } else {
        throw Exception('Failed to load plans: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch plans: $e');
    }
  }

  Future<List<Delivery>> fetchPlanDeliveries(int planId) async {
    try {
      final response = await ApiClient.instance.get('/api/rfp/plans/$planId/deliveries/');

      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = response.data;
        return jsonResponse.map((data) => Delivery.fromJson(data)).toList();
      } else {
        throw Exception(
          'Failed to load plan deliveries: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to fetch plan deliveries: $e');
    }
  }

  Future<List<Delivery>> fetchDeliveries() async {
    try {
      final response = await ApiClient.instance.get('/api/rfp/deliveries/');

      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = response.data;
        return jsonResponse.map((data) => Delivery.fromJson(data)).toList();
      } else {
        throw Exception('Failed to load deliveries: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch deliveries: $e');
    }
  }

  Future<DeliveryDetail> fetchDeliveryDetails(int deliveryId) async {
    try {
      final response = await ApiClient.instance.get('/api/rfp/deliveries/$deliveryId/');

      if (response.statusCode == 200) {
        return DeliveryDetail.fromJson(response.data);
      } else {
        throw Exception(
          'Failed to load delivery details: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to fetch delivery details: $e');
    }
  }
}
