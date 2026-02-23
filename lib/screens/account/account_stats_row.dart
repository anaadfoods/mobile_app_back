import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grocery_app/screens/dashboard/dashboard_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:grocery_app/routes/app_routes.dart';

/// Interactive gradient-filled stat chips displayed in a horizontal row.
/// Each chip shows icon + count + label with a colorful gradient background.
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

    return Row(
      children: [
        Expanded(
          child: _buildStatChip(
            context,
            theme,
            count: totalOrders,
            label: 'Orders',
            icon: Icons.shopping_bag_outlined,
            iconColor: Colors.amber,
            gradient: [theme.colorScheme.primary, const Color(0xFF5A7D62)],
            onTap: () {
              HapticFeedback.lightImpact();
              context.pushNamed(AppRoute.orderList.name);
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatChip(
            context,
            theme,
            count: activeSubscriptions,
            label: 'Plans',
            icon: Icons.autorenew_rounded,
            iconColor: const Color(0xFF42A5F5),
            gradient: [theme.colorScheme.primary, const Color(0xFF5A7D62)],
            onTap: () {
              HapticFeedback.lightImpact();
              context.pushNamed(AppRoute.subscriptionList.name);
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatChip(
            context,
            theme,
            count: favoriteCount,
            label: 'Wishlist',
            icon: Icons.favorite_rounded,
            iconColor: const Color(0xFFEF5350),
            gradient: [theme.colorScheme.primary, const Color(0xFF5A7D62)],
            onTap: () {
              HapticFeedback.lightImpact();
              context
                  .findAncestorStateOfType<DashboardScreenState>()!
                  .switchToTab(3);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatChip(
    BuildContext context,
    ThemeData theme, {
    required int count,
    required String label,
    required IconData icon,
    Color iconColor = Colors.white,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: Material(
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradient,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: gradient.first.withAlpha(60),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: iconColor, size: 18),
                  const SizedBox(height: 4),
                  Text(
                    count.toString(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withAlpha(220),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}