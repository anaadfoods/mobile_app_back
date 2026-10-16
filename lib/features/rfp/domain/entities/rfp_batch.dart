import 'rfp_batch_group.dart';
import 'rfp_plan.dart';

/// A farming batch representing a 12-week harvest cycle.
class RfpBatch {
  final String id;
  final int batchNumber;
  final DateTime startDate;
  final DateTime endDate;
  final int totalWeeks;
  final int currentWeek;
  final String status; // 'active', 'upcoming', 'completed'
  final String? seasonLabel;
  final double progressPercent;
  final DateTime? bookingStartDate;
  final DateTime? bookingEndDate;
  final DateTime? remainingPaymentDueDate;
  final bool isFull;
  final int? slotsRemaining;
  final int? maxFamilies;
  final int? bookedFamilyCount;
  final String? cropCycleId;
  final String? generalNote;
  final String? imageUrl;
  final List<RfpBatchGroup> groups;
  final List<RfpPlan> plans;

  const RfpBatch({
    required this.id,
    required this.batchNumber,
    required this.startDate,
    required this.endDate,
    required this.totalWeeks,
    required this.currentWeek,
    required this.status,
    this.seasonLabel,
    required this.progressPercent,
    this.bookingStartDate,
    this.bookingEndDate,
    this.remainingPaymentDueDate,
    this.isFull = false,
    this.slotsRemaining,
    this.maxFamilies,
    this.bookedFamilyCount,
    this.cropCycleId,
    this.generalNote,
    this.imageUrl,
    this.groups = const [],
    this.plans = const [],
  });

  int get weeksRemaining => totalWeeks - currentWeek;
  bool get isActive => status == 'active';
  bool get isUpcoming => status == 'upcoming';
}
