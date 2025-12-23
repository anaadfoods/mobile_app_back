import 'package:http/http.dart' as http;
import '../models/rfp_delivery_model.dart';
import '../common_widgets/global_import.dart';// Adjust import path as needed

class DeliveryService {
    final AuthService _authService = AuthService();

  // IMPORTANT: Replace with your actual API endpoint and Bearer Token
  // final String _apiUrl = "https://app.anaadfoods.com/api/rfp/deliveries";
  final String _apiUrl = "${ApiConfig.baseUrl}/api/rfp/deliveries";
  
 Future<String?> _getToken() async {
    return await _authService.getAccessToken();
  }

  Future<List<Delivery>> fetchDeliveries() async {
    try {

final token = await _getToken();
      
      final response = await http.get(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = json.decode(response.body);
        // The API returns the newest first, so this works well.
        return jsonResponse.map((data) => Delivery.fromJson(data)).toList();
      } else {
        // Handle server errors
        throw Exception('Failed to load deliveries: ${response.statusCode}');
      }
    } catch (e) {
      // Handle network errors or other exceptions
      throw Exception('Failed to fetch deliveries: $e');
    }
  }


  Future<DeliveryDetail> fetchDeliveryDetails(int deliveryId) async {
    try {
      final token = await _getToken();

      final response = await http.get(
        Uri.parse('$_apiUrl/$deliveryId'), // e.g., .../deliveries/3
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return DeliveryDetail.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load delivery details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch delivery details: $e');
    }
  }
}