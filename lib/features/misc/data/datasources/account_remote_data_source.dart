import 'package:grocery_app/features/misc/domain/entities/user_summary_entity.dart';
import 'package:grocery_app/models/user_summary_model.dart';
import 'package:grocery_app/services/api_client.dart';
import 'package:grocery_app/services/api_config.dart';
import 'package:grocery_app/services/token_service.dart';
import 'package:grocery_app/utils/app_logger.dart';

/// Remote data source for account-related API calls.
///
/// Delegates to existing ApiClient for HTTP requests.
abstract class AccountRemoteDataSource {
  Future<UserSummaryModel?> getUserSummary();
  Future<Map<String, dynamic>?> getUserProfile();
}

class AccountRemoteDataSourceImpl implements AccountRemoteDataSource {
  final TokenService _tokenService;

  AccountRemoteDataSourceImpl({required TokenService tokenService})
      : _tokenService = tokenService;

  @override
  Future<UserSummaryModel?> getUserSummary() async {
    try {
      final token = await _tokenService.getAccessToken();
      if (token == null) return null;

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

  @override
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final response = await ApiClient.instance.get(ApiConfig.profileEndpoint);

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['status'] == 'success' &&
            responseData['data'] != null) {
          return responseData['data'] as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      AppLogger.instance.log('Error getting user profile: $e');
      return null;
    }
  }
}
