import 'package:http/http.dart' as http;
import '../models/rfp_plan_model.dart';
import '../models/rfp_delivery_model.dart';
import '../common_widgets/global_import.dart';

class DeliveryService {
  final AuthService _authService = AuthService();

  final String _plansUrl = "${ApiConfig.baseUrl}/api/rfp/plans";

  Future<String?> _getToken() async {
    return await _authService.getAccessToken();
  }

  Future<List<RfpPlan>> fetchPlans() async {
    try {
      final token = await _getToken();

      final response = await http.get(
        Uri.parse(_plansUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = json.decode(response.body);
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
      final token = await _getToken();

      final response = await http.get(
        Uri.parse('$_plansUrl/$planId/deliveries'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = json.decode(response.body);
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
      final token = await _getToken();

      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/api/rfp/deliveries"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = json.decode(response.body);
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
      final token = await _getToken();

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/rfp/deliveries/$deliveryId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return DeliveryDetail.fromJson(json.decode(response.body));
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
