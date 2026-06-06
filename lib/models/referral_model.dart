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

  ReferredUser({
    required this.id,
    required this.email,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.dateJoined,
    this.status,
    this.statusDisplay,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory ReferredUser.fromJson(Map<String, dynamic> json) {
    return ReferredUser(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      dateJoined:
          DateTime.tryParse(json['date_joined'] ?? '') ?? DateTime.now(),
      status: json['status'], // Will be null if not provided by API yet
      statusDisplay: json['status_display'],
    );
  }
}

/// Model for referral data
class ReferralData {
  final String referralCode;
  final int referralsCount;
  final String? referredBy;
  final List<ReferredUser> referredUsers;

  ReferralData({
    required this.referralCode,
    required this.referralsCount,
    this.referredBy,
    required this.referredUsers,
  });

  factory ReferralData.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return ReferralData(
      referralCode: data['referral_code'] ?? '',
      referralsCount: data['referrals_count'] ?? 0,
      referredBy: data['referred_by'],
      referredUsers:
          (data['referred_users'] as List<dynamic>?)
              ?.map((user) => ReferredUser.fromJson(user))
              .toList() ??
          [],
    );
  }
}
