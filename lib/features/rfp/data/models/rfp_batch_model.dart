import '../../domain/entities/rfp_batch.dart';
import 'rfp_batch_group_model.dart';
import 'rfp_plan_model.dart';

class RfpBatchModel extends RfpBatch {
  const RfpBatchModel({
    required super.id,
    required super.batchNumber,
    required super.startDate,
    required super.endDate,
    required super.totalWeeks,
    required super.currentWeek,
    required super.status,
    super.seasonLabel,
    required super.progressPercent,
    super.bookingStartDate,
    super.bookingEndDate,
    super.remainingPaymentDueDate,
    super.isFull,
    super.slotsRemaining,
    super.maxFamilies,
    super.bookedFamilyCount,
    super.cropCycleId,
    super.generalNote,
    super.imageUrl,
    super.groups,
    super.plans = const [],
  });

  factory RfpBatchModel.fromJson(Map<String, dynamic> json) {
    final start =
        DateTime.tryParse(json['start_date'] as String? ?? '') ??
        DateTime.now();
    final end =
        DateTime.tryParse(json['end_date'] as String? ?? '') ??
        DateTime.now().add(const Duration(days: 84));

    final totalWeeks = json['total_weeks'] as int? ?? 12;

    int currentWeek = json['current_week'] as int? ?? 1;
    if (json['current_week'] == null) {
      final now = DateTime.now();
      if (now.isBefore(start)) {
        currentWeek = 0;
      } else if (now.isAfter(end)) {
        currentWeek = totalWeeks;
      } else {
        currentWeek = (now.difference(start).inDays ~/ 7) + 1;
        if (currentWeek > totalWeeks) currentWeek = totalWeeks;
      }
    }

    final double progress =
        (json['progress_percent'] as num?)?.toDouble() ??
        (totalWeeks > 0 ? (currentWeek / totalWeeks).clamp(0.0, 1.0) : 0.0);

    final rawStatus = (json['status'] as String? ?? 'active').toLowerCase();
    final capacityMap =
        (json['capacity'] ?? json['capacity_summary']) as Map<String, dynamic>?;
    final imageUrl = json['image'] as String?;

    final plansList =
        (json['plans'] as List<dynamic>?)
            ?.map((p) => RfpPlanModel.fromJson(p as Map<String, dynamic>))
            .toList() ??
        const <RfpPlanModel>[];

    final groupsList =
        (json['groups'] as List<dynamic>?)
            ?.map((g) => RfpBatchGroupModel.fromJson(g as Map<String, dynamic>))
            .toList() ??
        const <RfpBatchGroupModel>[];

    final rawId = json['id'];
    final idStr = rawId?.toString() ?? '';
    final batchNum =
        json['batch_number'] as int? ??
        (rawId is int ? rawId : int.tryParse(idStr) ?? 1);

    return RfpBatchModel(
      id: idStr,
      batchNumber: batchNum,
      startDate: start,
      endDate: end,
      totalWeeks: totalWeeks,
      currentWeek: currentWeek,
      status: rawStatus,
      seasonLabel:
          json['season_name'] as String? ??
          json['name'] as String? ??
          json['season_label'] as String?,
      progressPercent: progress,
      bookingStartDate: DateTime.tryParse(
        json['booking_start_date'] as String? ?? '',
      ),
      bookingEndDate: DateTime.tryParse(
        json['booking_end_date'] as String? ?? '',
      ),
      remainingPaymentDueDate: DateTime.tryParse(
        json['remaining_payment_due_date'] as String? ?? '',
      ),
      isFull:
          (capacityMap?['is_full'] as bool?) ??
          (json['is_full'] as bool?) ??
          false,
      slotsRemaining:
          (capacityMap?['slots_remaining'] as int?) ??
          (capacityMap?['remaining_capacity'] as int?),
      maxFamilies: (capacityMap?['max_families'] as int?),
      bookedFamilyCount: (capacityMap?['booked_family_count'] as int?),
      cropCycleId: json['crop_cycle_id'] as String?,
      generalNote: json['general_note'] as String? ?? json['notes'] as String?,
      imageUrl: imageUrl,
      groups: groupsList,
      plans: plansList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': seasonLabel,
      'image': imageUrl,
      'batch_number': batchNumber,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'total_weeks': totalWeeks,
      'current_week': currentWeek,
      'status': status,
      'season_label': seasonLabel,
      'progress_percent': progressPercent,
      'booking_start_date': bookingStartDate?.toIso8601String(),
      'booking_end_date': bookingEndDate?.toIso8601String(),
      'remaining_payment_due_date': remainingPaymentDueDate?.toIso8601String(),
      'crop_cycle_id': cropCycleId,
      'capacity': {
        'max_families': maxFamilies,
        'booked_family_count': bookedFamilyCount,
        'is_full': isFull,
        'slots_remaining': slotsRemaining,
      },
      'general_note': generalNote,
      'groups':
          groups
              .map(
                (g) =>
                    g is RfpBatchGroupModel
                        ? g.toJson()
                        : {'id': g.id, 'name': g.name},
              )
              .toList(),
      'plans':
          plans
              .map(
                (p) =>
                    p is RfpPlanModel
                        ? p.toJson()
                        : RfpPlanModel.fromEntity(p).toJson(),
              )
              .toList(),
    };
  }

  factory RfpBatchModel.fromEntity(RfpBatch entity) {
    return RfpBatchModel(
      id: entity.id,
      batchNumber: entity.batchNumber,
      startDate: entity.startDate,
      endDate: entity.endDate,
      totalWeeks: entity.totalWeeks,
      currentWeek: entity.currentWeek,
      status: entity.status,
      seasonLabel: entity.seasonLabel,
      progressPercent: entity.progressPercent,
      bookingStartDate: entity.bookingStartDate,
      bookingEndDate: entity.bookingEndDate,
      remainingPaymentDueDate: entity.remainingPaymentDueDate,
      isFull: entity.isFull,
      slotsRemaining: entity.slotsRemaining,
      maxFamilies: entity.maxFamilies,
      bookedFamilyCount: entity.bookedFamilyCount,
      cropCycleId: entity.cropCycleId,
      generalNote: entity.generalNote,
      imageUrl: entity.imageUrl,
      groups: entity.groups,
      plans:
          entity.plans
              .map((p) => p is RfpPlanModel ? p : RfpPlanModel.fromEntity(p))
              .toList(),
    );
  }
}
