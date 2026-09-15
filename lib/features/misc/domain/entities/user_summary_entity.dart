/// Pure Dart entity representing user summary data.
///
/// This entity is used by the Account screen to display user statistics
/// (total orders, total spent, etc.). It has no Flutter imports.
class UserSummaryEntity {
  final int totalOrders;
  final double totalSpent;
  final int activePlans;
  final int totalSubscriptions;
  final int cancelledOrders;
  final int totalProducts;

  const UserSummaryEntity({
    required this.totalOrders,
    required this.totalSpent,
    required this.activePlans,
    required this.totalSubscriptions,
    required this.cancelledOrders,
    required this.totalProducts,
  });
}
