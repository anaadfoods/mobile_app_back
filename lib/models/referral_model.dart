/// Model for referrer details
class ReferredBy {
  final int id;
  final String email;
  final String username;
  final String firstName;
  final String lastName;
  final String? rewardYouGet;

  ReferredBy({
    required this.id,
    required this.email,
    required this.username,
    required this.firstName,
    required this.lastName,
    this.rewardYouGet,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory ReferredBy.fromJson(Map<String, dynamic> json) {
    return ReferredBy(
      id: json['id'] is int
          ? json['id']
          : (int.tryParse(json['id']?.toString() ?? '') ?? 0),
      email: json['email']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      rewardYouGet: json['reward_you_get']?.toString(),
    );
  }
}

/// Model for a referred user
class ReferredUser {
  final int id;
  final String email;
  final String username;
  final String firstName;
  final String lastName;
  final DateTime dateJoined;
  final String? status; // For future: "PENDING" or "ACCEPTED"
  final String? statusDisplay;
  final String? rewardYouGet;

  ReferredUser({
    required this.id,
    required this.email,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.dateJoined,
    this.status,
    this.statusDisplay,
    this.rewardYouGet,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory ReferredUser.fromJson(Map<String, dynamic> json) {
    return ReferredUser(
      id: json['id'] is int
          ? json['id']
          : (int.tryParse(json['id']?.toString() ?? '') ?? 0),
      email: json['email']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      dateJoined:
          DateTime.tryParse(json['date_joined']?.toString() ?? '') ??
          DateTime.now(),
      status: json['status']?.toString(),
      statusDisplay: json['status_display']?.toString(),
      rewardYouGet: json['reward_you_get']?.toString(),
    );
  }
}

/// Model for rewards info
class RewardsInfo {
  final String youGet;
  final String theyGet;

  RewardsInfo({
    required this.youGet,
    required this.theyGet,
  });

  factory RewardsInfo.fromJson(Map<String, dynamic> json) {
    return RewardsInfo(
      youGet: json['you_get']?.toString() ?? '',
      theyGet: json['they_get']?.toString() ?? '',
    );
  }
}

/// Model for referral data
class ReferralData {
  final String referralCode;
  final int referralsCount;
  final int orderedCount;
  final int pendingCount;
  final int pendingRewardCount;
  final ReferredBy? referredBy;
  final RewardsInfo? rewardsInfo;
  final List<ReferredUser> referredUsers;

  ReferralData({
    required this.referralCode,
    required this.referralsCount,
    required this.orderedCount,
    required this.pendingCount,
    required this.pendingRewardCount,
    this.referredBy,
    this.rewardsInfo,
    required this.referredUsers,
  });

  factory ReferralData.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;

    ReferredBy? parsedReferredBy;
    if (data['referred_by'] is Map<String, dynamic>) {
      parsedReferredBy = ReferredBy.fromJson(
        data['referred_by'] as Map<String, dynamic>,
      );
    } else if (data['referred_by'] is String &&
        (data['referred_by'] as String).isNotEmpty) {
      parsedReferredBy = ReferredBy(
        id: 0,
        email: '',
        username: data['referred_by'] as String,
        firstName: data['referred_by'] as String,
        lastName: '',
      );
    }

    return ReferralData(
      referralCode: data['referral_code']?.toString() ?? '',
      referralsCount: data['referrals_count'] is int
          ? data['referrals_count']
          : (int.tryParse(data['referrals_count']?.toString() ?? '') ?? 0),
      orderedCount: data['ordered_count'] is int
          ? data['ordered_count']
          : (int.tryParse(data['ordered_count']?.toString() ?? '') ?? 0),
      pendingCount: data['pending_count'] is int
          ? data['pending_count']
          : (int.tryParse(data['pending_count']?.toString() ?? '') ?? 0),
      pendingRewardCount: data['pending_reward_count'] is int
          ? data['pending_reward_count']
          : (int.tryParse(data['pending_reward_count']?.toString() ?? '') ?? 0),
      referredBy: parsedReferredBy,
      rewardsInfo:
          data['rewards_info'] != null &&
                  data['rewards_info'] is Map<String, dynamic>
              ? RewardsInfo.fromJson(data['rewards_info'] as Map<String, dynamic>)
              : null,
      referredUsers:
          (data['referred_users'] as List<dynamic>?)
              ?.map(
                (user) => ReferredUser.fromJson(user as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }
}

