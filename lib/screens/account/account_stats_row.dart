import 'package:flutter/material.dart';
import 'package:grocery_app/screens/order/order_screen.dart';
import 'package:grocery_app/screens/MySubscriptionPlan/subscription_plan_detail.dart';
import 'package:grocery_app/screens/dashboard/dashboard_screen.dart';

class AccountStatsRow extends StatelessWidget {
  final int totalOrders;
  final int activeSubscriptions;
  final int favoriteCount;

  const AccountStatsRow({
    super.key,
    required this.totalOrders,
    required this.activeSubscriptions,
    required this.favoriteCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAnimatedStatItem(
                  context,
                  theme,
                  totalOrders,
                  'Orders',
                  Icons.shopping_bag_outlined,
                  Colors.green,
                  0,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => OrderScreen()),
                    );
                  },
                ),
                _buildGradientDivider(theme),
                _buildAnimatedStatItem(
                  context,
                  theme,
                  activeSubscriptions,
                  'Subscriptions',
                  Icons.autorenew_rounded,
                  Colors.green,
                  1,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SubscriptionScreen(),
                      ),
                    );
                  },
                ),
                _buildGradientDivider(theme),
                _buildAnimatedStatItem(
                  context,
                  theme,
                  favoriteCount,
                  'Wishlist',
                  Icons.favorite_outline_rounded,
                  const Color(0xFFD32F2F),
                  2,
                  () {
                    context
                        .findAncestorStateOfType<DashboardScreenState>()!
                        .switchToTab(3);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedStatItem(
    BuildContext context,
    ThemeData theme,
    int count,
    String label,
    IconData icon,
    Color color,
    int index,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.titleLarge?.color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.textTheme.bodyMedium?.color?.withAlpha(179),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGradientDivider(ThemeData theme) {
    return Container(
      height: 40,
      width: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.dividerColor.withAlpha(0),
            theme.dividerColor.withAlpha(128),
            theme.dividerColor.withAlpha(0),
          ],
        ),
      ),
    );
  }
}
