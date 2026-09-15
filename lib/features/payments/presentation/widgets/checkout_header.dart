import 'package:flutter/material.dart';
import 'package:grocery_app/core/theme/app_colors.dart';

class CheckoutHeader extends StatelessWidget {
  final bool isSubscription;
  final int totalItems;

  const CheckoutHeader({
    super.key,
    required this.isSubscription,
    required this.totalItems,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SliverToBoxAdapter(
      child: Container(
        height: 170,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.harvestAmber,
              AppColors.harvestAmber.withValues(alpha: 0.85),
              isDark
                  ? AppColors.harvestAmber.withValues(alpha: 0.7)
                  : AppColors.harvestAmber,
            ],
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.harvestAmber.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 10, 20),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.parchment,
                  ),
                  onPressed: () {
                    Navigator.maybePop(context);
                  },
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isSubscription ? "Subscription" : "Checkout",
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: AppColors.parchment,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "$totalItems item${totalItems > 1 ? 's' : ''} ready to order",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.parchment.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.parchment.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    isSubscription
                        ? Icons.card_membership_rounded
                        : Icons.shopping_bag_rounded,
                    color: AppColors.amberWarnBg,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
