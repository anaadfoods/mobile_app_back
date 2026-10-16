/// A single delivery drop in the 12-week schedule.
class RfpDelivery {
  final String id;
  final int weekNumber;
  final DateTime date;
  final String dayOfWeek; // 'Monday', 'Thursday'
  final String status; // 'delivered', 'upcoming', 'in_transit', 'scheduled'
  final List<RfpDeliveryPatch> patches;
  final String? description;
  final String? trackingLabel;
  final String? cancellationReason;
  final String? assignDeliveryTo;

  const RfpDelivery({
    required this.id,
    required this.weekNumber,
    required this.date,
    required this.dayOfWeek,
    required this.status,
    required this.patches,
    this.description,
    this.trackingLabel,
    this.cancellationReason,
    this.assignDeliveryTo,
  });

  double get totalWeight => patches.fold(0.0, (sum, p) => sum + p.weightKg);

  bool get isUpcoming => status.toLowerCase() == 'upcoming';
  bool get isOutForDelivery => status.toLowerCase() == 'out_for_delivery';
  bool get isDelivered => status.toLowerCase() == 'delivered';
}

/// Patch-specific info within a delivery.
class RfpDeliveryPatch {
  final String patchId;
  final String patchLabel;
  final double weightKg;
  final List<String>? includedVegetables;

  const RfpDeliveryPatch({
    required this.patchId,
    required this.patchLabel,
    required this.weightKg,
    this.includedVegetables,
  });
}
