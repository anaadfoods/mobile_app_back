class PlanSearchResult {
  final int planId;
  final String planName;

  PlanSearchResult({required this.planId, required this.planName});

  factory PlanSearchResult.fromJson(Map<String, dynamic> json) {
    return PlanSearchResult(
      planId: json['plan_id'],
      planName: json['plan_name'],
    );
  }
}