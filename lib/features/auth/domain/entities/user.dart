class User {
  final String email;
  final String username;
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

  const User({
    required this.email,
    required this.username,
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
    this.isRfp = false,
  });

  User copyWith({
    String? email,
    String? username,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? gender,
    String? address,
    String? pincode,
    String? city,
    String? state,
    String? profilePicture,
    String? referralCode,
    bool? isEmailVerified,
    bool? isRfp,
  }) {
    return User(
      email: email ?? this.email,
      username: username ?? this.username,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      gender: gender ?? this.gender,
      address: address ?? this.address,
      pincode: pincode ?? this.pincode,
      city: city ?? this.city,
      state: state ?? this.state,
      profilePicture: profilePicture ?? this.profilePicture,
      referralCode: referralCode ?? this.referralCode,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isRfp: isRfp ?? this.isRfp,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          email == other.email &&
          username == other.username &&
          firstName == other.firstName &&
          lastName == other.lastName &&
          phoneNumber == other.phoneNumber &&
          gender == other.gender &&
          address == other.address &&
          pincode == other.pincode &&
          city == other.city &&
          state == other.state &&
          profilePicture == other.profilePicture &&
          referralCode == other.referralCode &&
          isEmailVerified == other.isEmailVerified &&
          isRfp == other.isRfp;

  @override
  int get hashCode =>
      email.hashCode ^
      username.hashCode ^
      firstName.hashCode ^
      lastName.hashCode ^
      phoneNumber.hashCode ^
      gender.hashCode ^
      address.hashCode ^
      pincode.hashCode ^
      city.hashCode ^
      state.hashCode ^
      profilePicture.hashCode ^
      referralCode.hashCode ^
      isEmailVerified.hashCode ^
      isRfp.hashCode;
}
