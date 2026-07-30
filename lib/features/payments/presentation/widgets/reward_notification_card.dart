import 'package:flutter/material.dart';
import 'package:grocery_app/core/theme/app_colors.dart';

class RewardNotificationCard extends StatelessWidget {
  final int pendingRewardsCount;

  const RewardNotificationCard({
    super.key,
    required this.pendingRewardsCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.deepSoilGreen,
            AppColors.deepSoilGreen.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepSoilGreen.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.parchment.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.card_giftcard_rounded,
              color: AppColors.harvestAmber,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🎁 Rewards Waiting!',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.parchment,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  pendingRewardsCount == 1
                      ? 'You have 1 referral reward waiting in your orders!'
                      : 'You have $pendingRewardsCount referral rewards waiting in your orders!',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.parchment.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
