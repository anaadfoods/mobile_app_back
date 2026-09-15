import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:grocery_app/core/theme/app_colors.dart';

class SubscriptionCardWidget extends StatelessWidget {
  final Map<String, dynamic> subscriptionData;

  const SubscriptionCardWidget({super.key, required this.subscriptionData});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (subscriptionData.containsKey('plans')) {
      return _buildPlansMode(context, isDark);
    } else {
      return _buildSubscriptionMode(context, isDark);
    }
  }

  Widget _buildSubscriptionMode(BuildContext context, bool isDark) {
    final status =
        subscriptionData['status']?.toString().toUpperCase() ?? 'ACTIVE';
    final planName =
        subscriptionData['plan_name']?.toString() ?? 'Daily Milk Subscription';
    final nextDelivery =
        subscriptionData['next_delivery']?.toString() ?? 'Tomorrow, 6:00 AM';
    final items = subscriptionData['items'] as List<dynamic>? ?? [];

    Color statusColor = AppColors.successGreen;
    if (status == 'PAUSED') statusColor = AppColors.harvestAmber;
    if (status == 'CANCELLED') statusColor = AppColors.softRed;

    return Container(
      margin: const EdgeInsets.only(top: 10.0, bottom: 4.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : AppColors.softCream,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white12
              : AppColors.deepSoilGreen.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  planName,
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.charcoal,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.local_shipping_outlined,
                color: isDark ? Colors.white70 : AppColors.charcoal70,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                "Next delivery: $nextDelivery",
                style: TextStyle(
                  color: isDark ? Colors.white70 : AppColors.charcoal70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (items.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              "Included Items:",
              style: TextStyle(
                color: isDark ? Colors.white54 : AppColors.charcoal54,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            ...items.take(3).map((item) {
              final name = item['name']?.toString() ?? 'Item';
              final qty = item['quantity']?.toString() ?? '1';
              return Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.successGreen,
                      size: 12,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "$qty × $name",
                        style: TextStyle(
                          color: isDark ? Colors.white : AppColors.charcoal,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        isDark ? Colors.white : AppColors.deepSoilGreen,
                    side: BorderSide(
                      color: isDark
                          ? Colors.white30
                          : AppColors.deepSoilGreen.withValues(alpha: 0.4),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: () {},
                  child: Text(
                    status == 'PAUSED' ? "Resume" : "Pause",
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.harvestAmber,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: () => context.push('/subscriptions'),
                  child: const Text(
                    "View Details",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlansMode(BuildContext context, bool isDark) {
    final plans = subscriptionData['plans'] as List<dynamic>? ?? [];
    if (plans.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 10.0, bottom: 4.0),
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: plans.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final plan = plans[index];
          final planName = plan['name']?.toString() ?? 'Plan';
          final price = plan['price']?.toString() ?? '₹0';
          final period = plan['period']?.toString() ?? 'month';
          final productsCount = plan['products_count']?.toString() ?? '3 items';

          return Container(
            width: 220,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color:
                  isDark
                      ? AppColors.darkSurfaceElevated
                      : AppColors.softCream,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white12
                    : AppColors.deepSoilGreen.withValues(alpha: 0.15),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 1.5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  planName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.charcoal,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "$price / $period",
                  style: const TextStyle(
                    color: AppColors.harvestAmber,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Includes $productsCount",
                  style: TextStyle(
                    color: isDark ? Colors.white70 : AppColors.charcoal70,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.harvestAmber,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onPressed: () => context.push('/subscriptions'),
                    child: const Text(
                      "View Plan",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
