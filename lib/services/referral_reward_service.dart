import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:grocery_app/services/api_config.dart';
import 'package:grocery_app/services/auth_service.dart';
import 'package:grocery_app/models/referral_model.dart';

/// Service to fetch referral reward count and referral data
class ReferralRewardService {
  final AuthService _authService = AuthService();

  /// Fetches the pending referral rewards count
  /// Returns 0 if there's an error or no rewards
  Future<int> getPendingRewardsCount() async {
    try {
      final token = await _authService.getAccessToken();
      if (token == null) return 0;

      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}${ApiConfig.referralRewardCountEndpoint}',
        ),
        headers: ApiConfig.getAuthHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['pending_rewards_count'] ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Fetches the user's referral data including code and referred users
  Future<ReferralData?> fetchReferrals() async {
    try {
      final token = await _authService.getAccessToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.referralsEndpoint}'),
        headers: ApiConfig.getAuthHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ReferralData.fromJson(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
