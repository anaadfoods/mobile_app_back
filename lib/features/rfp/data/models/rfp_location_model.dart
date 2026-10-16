import '../../domain/entities/rfp_location.dart';

class RfpLocationModel extends RfpLocation {
  const RfpLocationModel({
    required super.id,
    required super.name,
    required super.pincode,
    required super.sector,
    required super.isActive,
  });

  factory RfpLocationModel.fromJson(Map<String, dynamic> json) {
    return RfpLocationModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      pincode: json['pincode'] as String? ?? '',
      sector: json['sector'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'pincode': pincode,
      'sector': sector,
      'is_active': isActive,
    };
  }

  factory RfpLocationModel.fromEntity(RfpLocation entity) {
    return RfpLocationModel(
      id: entity.id,
      name: entity.name,
      pincode: entity.pincode,
      sector: entity.sector,
      isActive: entity.isActive,
    );
  }
}
