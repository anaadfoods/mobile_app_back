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

  UserModel({
    required this.email,
    required this.username,
    required this.password,
    required this.confirmPassword,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    this.gender,
    this.address,
    this.pincode,
    this.city,
    this.state,
    this.profilePicture,
    this.referralCode,
    this.isEmailVerified = false,
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
      if (gender != null) 'gender': gender,
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
      if (gender != null) 'gender': gender,
      if (profilePicture != null) 'profile_picture': profilePicture,
      if (referralCode != null) 'referral_code': referralCode,
      'is_email_verified': isEmailVerified,
    };
  }

  // Create UserModel from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      password: json['password'] ?? '',
      confirmPassword: json['confirm_password'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      address: json['address'],
      pincode: json['pincode'],
      city: json['city'],
      state: json['state'],
      profilePicture: json['profile_picture'],
      referralCode: json['referral_code'],
      isEmailVerified: json['is_email_verified'] ?? false,
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
    String? pincode,
    String? city,
    String? state,
    String? profilePicture,
    String? referralCode,
    bool? isEmailVerified,
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
      pincode: pincode ?? this.pincode,
      city: city ?? this.city,
      state: state ?? this.state,
      profilePicture: profilePicture ?? this.profilePicture,
      referralCode: referralCode ?? this.referralCode,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
    );
  }
}
