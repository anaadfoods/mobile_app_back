/// Model representing the user summary from the API
/// GET /api/core/user-summary/
class UserSummaryModel {
  final OrdersSummary orders;
  final SubscriptionsSummary subscriptions;
  final FavoritesSummary favorites;

  UserSummaryModel({
    required this.orders,
    required this.subscriptions,
    required this.favorites,
  });

  factory UserSummaryModel.fromJson(Map<String, dynamic> json) {
    return UserSummaryModel(
      orders: OrdersSummary.fromJson(json['orders'] ?? {}),
      subscriptions: SubscriptionsSummary.fromJson(json['subscriptions'] ?? {}),
      favorites: FavoritesSummary.fromJson(json['favorites'] ?? {}),
    );
  }

  /// Empty/default summary for initial state
  factory UserSummaryModel.empty() {
    return UserSummaryModel(
      orders: OrdersSummary.empty(),
      subscriptions: SubscriptionsSummary.empty(),
      favorites: FavoritesSummary.empty(),
    );
  }
}

/// Orders summary with counts by status
class OrdersSummary {
  final Map<String, int> byStatus;
  final int total;

  OrdersSummary({required this.byStatus, required this.total});

  factory OrdersSummary.fromJson(Map<String, dynamic> json) {
    final byStatusData = json['by_status'] as Map<String, dynamic>? ?? {};
    return OrdersSummary(
      byStatus: byStatusData.map(
        (key, value) => MapEntry(key, value as int? ?? 0),
      ),
      total: json['total'] as int? ?? 0,
    );
  }

  factory OrdersSummary.empty() {
    return OrdersSummary(byStatus: {}, total: 0);
  }
}

/// Subscriptions summary with active counts by plan
class SubscriptionsSummary {
  final Map<String, int> activeByPlan;
  final int activeTotal;

  SubscriptionsSummary({required this.activeByPlan, required this.activeTotal});

  factory SubscriptionsSummary.fromJson(Map<String, dynamic> json) {
    final activeByPlanData =
        json['active_by_plan'] as Map<String, dynamic>? ?? {};
    return SubscriptionsSummary(
      activeByPlan: activeByPlanData.map(
        (key, value) => MapEntry(key, value as int? ?? 0),
      ),
      activeTotal: json['active_total'] as int? ?? 0,
    );
  }

  factory SubscriptionsSummary.empty() {
    return SubscriptionsSummary(activeByPlan: {}, activeTotal: 0);
  }
}

/// Favorites summary
class FavoritesSummary {
  final int count;

  FavoritesSummary({required this.count});

  factory FavoritesSummary.fromJson(Map<String, dynamic> json) {
    return FavoritesSummary(count: json['count'] as int? ?? 0);
  }

  factory FavoritesSummary.empty() {
    return FavoritesSummary(count: 0);
  }
}
