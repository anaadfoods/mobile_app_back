import 'package:grocery_app/services/api_config.dart';
import 'package:grocery_app/features/auth/domain/entities/user.dart';

class UserModel {
  final String email;
  final String username;
  final String password;
  final String confirmPassword;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String? gender;
  final String? address;
  final String? pincode;
  final String? city;
  final String? state;
  final String? profilePicture;
  final String? referralCode;
  final bool isEmailVerified;
  final bool isRfp;
  UserModel({
    required this.email,
    required this.username,
    required this.password,
    required this.confirmPassword,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.gender,
    this.address,
    this.pincode,
    this.city,
    this.state,
    this.profilePicture,
    this.referralCode,
    this.isEmailVerified = false,
    this.isRfp = false,
  });

  // Convert UserModel to JSON for registration
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'username': username,
      'password': password,
      'confirm_password': confirmPassword,
      'first_name': firstName,
      'last_name': lastName,
      'phone_number': phoneNumber,
      'gender': gender,
      'referral_code': referralCode,
    };
  }

  // Convert UserModel to JSON for profile updates
  Map<String, dynamic> toProfileJson() {
    return {
      'email': email,
      'username': username,
      'first_name': firstName,
      'last_name': lastName,
      'phone_number': phoneNumber,
      if (address != null) 'address': address,
      if (pincode != null) 'pincode': pincode,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      'gender': gender,
      if (profilePicture != null) 'profile_picture': profilePicture,
      if (referralCode != null) 'referral_code': referralCode,
      'is_email_verified': isEmailVerified,
    };
  }

  // Create UserModel from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    final String? rawImageUrl = json['profile_picture'];
    String? finalImageUrl;

    // 2. Check if the URL is valid and complete
    if (rawImageUrl != null && rawImageUrl.isNotEmpty) {
      // If it's a full URL, use it directly. Otherwise, prepend the base URL.
      finalImageUrl =
          rawImageUrl.startsWith('http')
              ? rawImageUrl
              : '${ApiConfig.baseUrl}$rawImageUrl';
    }

    return UserModel(
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      password: json['password'] ?? '',
      confirmPassword: json['confirm_password'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      gender: json['gender'] ?? '',
      address: json['address'],
      pincode: json['pincode'],
      city: json['city'],
      state: json['state'],
      profilePicture: finalImageUrl,
      referralCode: json['referral_code'],
      isEmailVerified: json['is_email_verified'] ?? false,
      isRfp: json['is_rfp'] ?? false,
    );
  }

  // Create a copy of UserModel with updated fields
  UserModel copyWith({
    String? email,
    String? username,
    String? password,
    String? confirmPassword,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? address,
    String? gender,
    String? pincode,
    String? city,
    String? state,
    String? profilePicture,
    String? referralCode,
    bool? isEmailVerified,
    bool? isRfp,
  }) {
    return UserModel(
      email: email ?? this.email,
      username: username ?? this.username,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      gender: gender ?? this.gender,
      pincode: pincode ?? this.pincode,
      city: city ?? this.city,
      state: state ?? this.state,
      profilePicture: profilePicture ?? this.profilePicture,
      referralCode: referralCode ?? this.referralCode,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isRfp: isRfp ?? this.isRfp,
    );
  }

  // Create UserModel from domain User entity
  factory UserModel.fromDomain(dynamic domainUser) {
    return UserModel(
      email: domainUser.email,
      username: domainUser.username,
      password: '',
      confirmPassword: '',
      firstName: domainUser.firstName,
      lastName: domainUser.lastName,
      phoneNumber: domainUser.phoneNumber,
      gender: domainUser.gender,
      address: domainUser.address,
      pincode: domainUser.pincode,
      city: domainUser.city,
      state: domainUser.state,
      profilePicture: domainUser.profilePicture,
      referralCode: domainUser.referralCode,
      isEmailVerified: domainUser.isEmailVerified,
      isRfp: domainUser.isRfp,
    );
  }

  User toDomain() {
    return User(
      email: email,
      username: username,
      firstName: firstName,
      lastName: lastName,
      phoneNumber: phoneNumber,
      gender: gender,
      address: address,
      pincode: pincode,
      city: city,
      state: state,
      profilePicture: profilePicture,
      referralCode: referralCode,
      isEmailVerified: isEmailVerified,
      isRfp: isRfp,
    );
  }
}
