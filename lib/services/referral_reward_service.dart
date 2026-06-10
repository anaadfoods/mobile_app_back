import 'package:grocery_app/services/api_config.dart';
import 'package:grocery_app/services/token_service.dart';
import 'package:grocery_app/services/api_client.dart';
import 'package:grocery_app/models/referral_model.dart';

import 'package:grocery_app/service_locator.dart';

/// Service to fetch referral reward count and referral data
class ReferralRewardService {
  factory ReferralRewardService() => getIt<ReferralRewardService>();
  ReferralRewardService.create();

  final TokenService _tokenService = getIt<TokenService>();

  /// Fetches the pending referral rewards count
  /// Returns 0 if there's an error or no rewards
  Future<int> getPendingRewardsCount() async {
    try {
      final token = await _tokenService.getAccessToken();
      if (token == null) return 0;

      final response = await ApiClient.instance.get(
        ApiConfig.referralRewardCountEndpoint,
      );

      if (response.statusCode == 200) {
        final data = response.data;
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
      final token = await _tokenService.getAccessToken();
      if (token == null) return null;

      final response = await ApiClient.instance.get(
        ApiConfig.referralsEndpoint,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return ReferralData.fromJson(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
