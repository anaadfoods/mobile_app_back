import '../../domain/entities/rfp_delivery.dart';

class RfpDeliveryPatchModel extends RfpDeliveryPatch {
  const RfpDeliveryPatchModel({
    required super.patchId,
    required super.patchLabel,
    required super.weightKg,
    super.includedVegetables,
  });

  factory RfpDeliveryPatchModel.fromJson(Map<String, dynamic> json) {
    return RfpDeliveryPatchModel(
      patchId: json['patch_id']?.toString() ?? '',
      patchLabel: json['patch_label'] as String? ?? 'P1',
      weightKg:
          (json['weight_kg'] is num)
              ? (json['weight_kg'] as num).toDouble()
              : double.tryParse(json['weight_kg']?.toString() ?? '2.5') ?? 2.5,
      includedVegetables:
          (json['included_vegetables'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patch_id': patchId,
      'patch_label': patchLabel,
      'weight_kg': weightKg,
      'included_vegetables': includedVegetables,
    };
  }

  factory RfpDeliveryPatchModel.fromEntity(RfpDeliveryPatch entity) {
    return RfpDeliveryPatchModel(
      patchId: entity.patchId,
      patchLabel: entity.patchLabel,
      weightKg: entity.weightKg,
      includedVegetables: entity.includedVegetables,
    );
  }
}

class RfpDeliveryModel extends RfpDelivery {
  const RfpDeliveryModel({
    required super.id,
    required super.weekNumber,
    required super.date,
    required super.dayOfWeek,
    required super.status,
    required super.patches,
    super.description,
    super.trackingLabel,
    super.cancellationReason,
    super.assignDeliveryTo,
  });

  static String _dayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      case DateTime.sunday:
        return 'Sunday';
      default:
        return 'Monday';
    }
  }

  factory RfpDeliveryModel.fromJson(
    Map<String, dynamic> json, {
    DateTime? batchStartDate,
    int? fallbackWeekNumber,
  }) {
    final parsedDate =
        DateTime.tryParse(
          json['delivery_date'] as String? ?? json['date'] as String? ?? '',
        ) ??
        DateTime.now();

    final day = json['day_of_week'] as String? ?? _dayName(parsedDate.weekday);

    final rawStatus = (json['status'] as String? ?? 'scheduled').toUpperCase();
    String normalizedStatus;
    if (rawStatus == 'DELIVERED') {
      normalizedStatus = 'delivered';
    } else if (rawStatus == 'OUT_FOR_DELIVERY') {
      normalizedStatus = 'out_for_delivery';
    } else if (rawStatus == 'NOT_DELIVERED' || rawStatus == 'CANCELLED') {
      normalizedStatus = 'cancelled';
    } else {
      // PENDING
      final now = DateTime.now();
      final diffDays = parsedDate.difference(now).inDays;
      if (diffDays < 0) {
        normalizedStatus = 'delivered';
      } else if (diffDays <= 7) {
        normalizedStatus = 'upcoming';
      } else {
        normalizedStatus = 'scheduled';
      }
    }

    int computedWeek = json['week_number'] as int? ?? fallbackWeekNumber ?? 1;
    if (json['week_number'] == null && batchStartDate != null) {
      final daysDiff = parsedDate.difference(batchStartDate).inDays;
      computedWeek = (daysDiff ~/ 7) + 1;
      if (computedWeek < 1) computedWeek = 1;
      if (computedWeek > 12) computedWeek = 12;
    }

    final reason = json['cancellation_reason'] as String?;
    final desc =
        json['description'] as String? ??
        (reason != null && reason.isNotEmpty
            ? reason
            : (normalizedStatus == 'delivered'
                ? 'Delivered safely'
                : (normalizedStatus == 'out_for_delivery'
                    ? 'Harvest out for delivery'
                    : 'Scheduled farm dispatch')));

    return RfpDeliveryModel(
      id: json['id']?.toString() ?? '',
      weekNumber: computedWeek,
      date: parsedDate,
      dayOfWeek: day,
      status: normalizedStatus,
      patches:
          (json['patches'] as List<dynamic>?)
              ?.map(
                (e) =>
                    RfpDeliveryPatchModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      description: desc,
      trackingLabel:
          json['tracking_label'] as String? ??
          (normalizedStatus == 'out_for_delivery'
              ? 'Out for Delivery'
              : (normalizedStatus == 'upcoming' ? 'Dispatched' : null)),
      cancellationReason: reason,
      assignDeliveryTo:
          json['assign_delivery_to'] as String? ??
          json['assigned_agent_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'week_number': weekNumber,
      'delivery_date': date.toIso8601String(),
      'day_of_week': dayOfWeek,
      'status': status.toUpperCase(),
      'patches':
          patches
              .map((p) => RfpDeliveryPatchModel.fromEntity(p).toJson())
              .toList(),
      'description': description,
      'tracking_label': trackingLabel,
      'cancellation_reason': cancellationReason,
      'assign_delivery_to': assignDeliveryTo,
    };
  }

  factory RfpDeliveryModel.fromEntity(RfpDelivery entity) {
    return RfpDeliveryModel(
      id: entity.id,
      weekNumber: entity.weekNumber,
      date: entity.date,
      dayOfWeek: entity.dayOfWeek,
      status: entity.status,
      patches: entity.patches,
      description: entity.description,
      trackingLabel: entity.trackingLabel,
      cancellationReason: entity.cancellationReason,
      assignDeliveryTo: entity.assignDeliveryTo,
    );
  }
}
