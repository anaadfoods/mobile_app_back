import '../../domain/entities/rfp_batch_group.dart';

class RfpBatchGroupModel extends RfpBatchGroup {
  const RfpBatchGroupModel({
    required super.id,
    required super.name,
    required super.maxFamilies,
    required super.bookedFamilyCount,
    required super.slotsRemaining,
    required super.isFull,
  });

  factory RfpBatchGroupModel.fromJson(Map<String, dynamic> json) {
    return RfpBatchGroupModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      maxFamilies: json['max_families'] as int? ?? 0,
      bookedFamilyCount: json['booked_family_count'] as int? ?? 0,
      slotsRemaining: json['slots_remaining'] as int? ?? 0,
      isFull: json['is_full'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'max_families': maxFamilies,
      'booked_family_count': bookedFamilyCount,
      'slots_remaining': slotsRemaining,
      'is_full': isFull,
    };
  }

  factory RfpBatchGroupModel.fromEntity(RfpBatchGroup entity) {
    return RfpBatchGroupModel(
      id: entity.id,
      name: entity.name,
      maxFamilies: entity.maxFamilies,
      bookedFamilyCount: entity.bookedFamilyCount,
      slotsRemaining: entity.slotsRemaining,
      isFull: entity.isFull,
    );
  }
}
