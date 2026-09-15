/// Domain entity representing 3-Tier AI Token Quota status for the authenticated user.
class TokenQuotaInfo {
  /// User Tier: NON_ORDER, ONE_ORDER, or SUBSCRIPTION
  final String tier;

  /// Display name for user's tier (e.g. "Standard Explorer Tier", "Subscription Premium Tier")
  final String tierName;

  /// Maximum AI queries/tokens allowed today
  final int dailyLimit;

  /// AI queries/tokens consumed today
  final int tokensUsed;

  /// AI queries/tokens remaining today
  final int tokensRemaining;

  const TokenQuotaInfo({
    required this.tier,
    required this.tierName,
    required this.dailyLimit,
    required this.tokensUsed,
    required this.tokensRemaining,
  });

  factory TokenQuotaInfo.fromJson(Map<String, dynamic> json) {
    return TokenQuotaInfo(
      tier: json['tier'] as String? ?? 'NON_ORDER',
      tierName: json['tier_name'] as String? ?? 'Standard Tier',
      dailyLimit: json['daily_limit'] as int? ?? 5,
      tokensUsed: json['tokens_used'] as int? ?? 0,
      tokensRemaining: json['tokens_remaining'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tier': tier,
      'tier_name': tierName,
      'daily_limit': dailyLimit,
      'tokens_used': tokensUsed,
      'tokens_remaining': tokensRemaining,
    };
  }
}
