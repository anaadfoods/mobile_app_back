class RfpPlan {
  final int id;
  final String customerNumber;
  final String status;
  final int planId;
  final String name;
  final String desc;
  final int duration;
  final DateTime startDate;
  final String createdAt;

  RfpPlan({
    required this.id,
    required this.customerNumber,
    required this.status,
    required this.planId,
    required this.name,
    required this.desc,
    required this.duration,
    required this.startDate,
    required this.createdAt,
  });

  factory RfpPlan.fromJson(Map<String, dynamic> json) {
    return RfpPlan(
      id: json['id'],
      customerNumber: json['customer_number'] ?? '',
      status: json['status'] ?? '',
      planId: json['plan_id'] ?? 0,
      name: json['name'] ?? '',
      desc: json['desc'] ?? '',
      duration: json['duration'] ?? 0,
      startDate: DateTime.parse(json['start_date']),
      createdAt: json['created_at'] ?? '',
    );
  }

  /// Calculate the end date based on start_date + duration days
  DateTime get endDate => startDate.add(Duration(days: duration));

  /// Number of days remaining from today
  int get daysRemaining {
    final remaining = endDate.difference(DateTime.now()).inDays;
    return remaining > 0 ? remaining : 0;
  }

  /// Progress as a fraction (0.0 to 1.0)
  double get progress {
    if (duration <= 0) return 0;
    final elapsed = DateTime.now().difference(startDate).inDays;
    return (elapsed / duration).clamp(0.0, 1.0);
  }

  bool get isActive => status.toUpperCase() == 'ACTIVE';
}
