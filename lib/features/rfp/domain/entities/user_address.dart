/// A user's saved physical delivery address matching backend `UserAddress`.
class UserAddress {
  final int id;
  final String label; // 'HOME', 'OFFICE', 'OTHER'
  final String fullName;
  final String phoneNumber;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String pincode;
  final bool isDefault;

  const UserAddress({
    required this.id,
    this.label = 'HOME',
    required this.fullName,
    required this.phoneNumber,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    required this.pincode,
    this.isDefault = false,
  });

  String get formattedAddress {
    final parts = [
      addressLine1,
      if (addressLine2 != null && addressLine2!.isNotEmpty) addressLine2!,
    ];
    return parts.join(', ');
  }
}
