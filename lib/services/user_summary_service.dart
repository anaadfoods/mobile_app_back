import 'dart:convert';
import 'package:grocery_app/models/user_summary_model.dart';
import 'package:grocery_app/services/api_config.dart';
import 'package:grocery_app/services/auth_service.dart';
import 'package:http/http.dart' as http;

/// Service for fetching user summary data
class UserSummaryService {
  final AuthService _authService = AuthService();

  /// Fetches the user summary from the API
  /// Returns UserSummaryModel on success, null on failure
  Future<UserSummaryModel?> getUserSummary() async {
    try {
      final token = await _authService.getAccessToken();
      if (token == null) {
        return null;
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.userSummaryEndpoint}'),
        headers: ApiConfig.getAuthHeaders(token),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 'success' &&
            responseData['data'] != null) {
          return UserSummaryModel.fromJson(responseData['data']);
        }
      } else if (response.statusCode == 401) {
        // Token expired, try refreshing
        final refreshResult = await _authService.refreshAccessToken();
        if (refreshResult) {
          return getUserSummary();
        }
      }
      return null;
    } catch (e) {
      print('Error fetching user summary: $e');
      return null;
    }
  }
}
