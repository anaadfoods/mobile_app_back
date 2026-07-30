import 'package:flutter/material.dart';
import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:grocery_app/features/misc/presentation/screens/help_screen.dart';

class OrderListLoadingState extends StatelessWidget {
  const OrderListLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return const LoadingStateWidget();
  }
}

class OrderListErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const OrderListErrorState({
    super.key,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.softRed.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: AppColors.softRed,
              size: 48,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Something went wrong',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.hintColor,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.deepSoilGreen,
              foregroundColor: AppColors.parchment,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}

class OrderListEmptyState extends StatelessWidget {
  const OrderListEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.deepSoilGreen.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shopping_bag_outlined,
              color: AppColors.deepSoilGreen,
              size: 64,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Orders Yet',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Browse our fresh items and place your first order!',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.hintColor,
            ),
          ),
        ],
      ),
    );
  }
}

class OrderListHelpCard extends StatelessWidget {
  const OrderListHelpCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppColors.deepSoilGreen.withValues(alpha: 0.2),
                  AppColors.deepSoilGreen.withValues(alpha: 0.1),
                ]
              : [
                  AppColors.deepSoilGreen.withValues(alpha: 0.08),
                  AppColors.deepSoilGreen.withValues(alpha: 0.04),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.deepSoilGreen.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.deepSoilGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              color: AppColors.deepSoilGreen,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need Help?',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Contact our support team for any order issues',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => HelpScreen()),
              );
            },
            icon: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.deepSoilGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_forward,
                color: AppColors.parchment,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OrderListStatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;

  const OrderListStatChip({
    super.key,
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.parchment.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.parchment.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '$count $label',
            style: const TextStyle(
              color: AppColors.parchment,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
