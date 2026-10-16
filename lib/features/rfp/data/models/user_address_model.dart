import '../../domain/entities/user_address.dart';

class UserAddressModel extends UserAddress {
  const UserAddressModel({
    required super.id,
    super.label,
    required super.fullName,
    required super.phoneNumber,
    required super.addressLine1,
    super.addressLine2,
    required super.city,
    required super.state,
    required super.pincode,
    super.isDefault,
  });

  factory UserAddressModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final idInt =
        rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '0') ?? 0;

    return UserAddressModel(
      id: idInt,
      label: json['label'] as String? ?? 'HOME',
      fullName: json['full_name'] as String? ?? '',
      phoneNumber: json['phone_number'] as String? ?? '',
      addressLine1:
          (json['address_line_1'] ?? json['address_line1']) as String? ?? '',
      addressLine2:
          (json['address_line_2'] ?? json['address_line2']) as String?,
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      pincode: json['pincode'] as String? ?? '',
      isDefault: json['is_default'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'address_line_1': addressLine1,
      if (addressLine2 != null && addressLine2!.isNotEmpty)
        'address_line_2': addressLine2,
      'city': city,
      'state': state,
      'pincode': pincode,
      'is_default': isDefault,
    };
  }

  factory UserAddressModel.fromEntity(UserAddress entity) {
    return UserAddressModel(
      id: entity.id,
      label: entity.label,
      fullName: entity.fullName,
      phoneNumber: entity.phoneNumber,
      addressLine1: entity.addressLine1,
      addressLine2: entity.addressLine2,
      city: entity.city,
      state: entity.state,
      pincode: entity.pincode,
      isDefault: entity.isDefault,
    );
  }
}
