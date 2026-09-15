import 'package:grocery_app/utils/app_logger.dart';
import 'package:grocery_app/models/user_summary_model.dart';
import 'package:grocery_app/services/api_config.dart';
import 'package:grocery_app/services/token_service.dart';
import 'package:grocery_app/services/api_client.dart';

import 'package:grocery_app/service_locator.dart';

/// Service for fetching user summary data
class UserSummaryService {
  factory UserSummaryService() => getIt<UserSummaryService>();
  UserSummaryService.create();

  final TokenService _tokenService = getIt<TokenService>();

  /// Fetches the user summary from the API
  /// Returns UserSummaryModel on success, null on failure
  Future<UserSummaryModel?> getUserSummary() async {
    try {
      final token = await _tokenService.getAccessToken();
      if (token == null) {
        return null;
      }

      final response = await ApiClient.instance.get(
        ApiConfig.userSummaryEndpoint,
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['status'] == 'success' &&
            responseData['data'] != null) {
          return UserSummaryModel.fromJson(responseData['data']);
        }
      }
      return null;
    } catch (e) {
      AppLogger.instance.log('Error fetching user summary: $e');
      return null;
    }
  }
}
