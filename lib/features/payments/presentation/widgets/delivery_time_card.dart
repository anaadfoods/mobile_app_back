import 'package:flutter/material.dart';
import 'package:grocery_app/core/theme/app_colors.dart';
import 'package:grocery_app/services/api_config.dart';

class DeliveryTimeCard extends StatelessWidget {
  final String expectedDeliveryDate;
  final double currentDeliveryCharge;

  const DeliveryTimeCard({
    super.key,
    required this.expectedDeliveryDate,
    required this.currentDeliveryCharge,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.deepSoilGreen.withValues(alpha: 0.15),
            AppColors.deepSoilGreen.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.deepSoilGreen.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.deepSoilGreen.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.local_shipping_rounded,
              color: AppColors.harvestAmber,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estimated Delivery',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  ApiConfig.showExpectedDeliveryDate
                      ? expectedDeliveryDate
                      : ApiConfig.alternativeDeliveryText,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.harvestAmber,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.visible,
                ),
              ],
            ),
          ),
          if (currentDeliveryCharge == 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.deepSoilGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'FREE',
                style: TextStyle(
                  color: AppColors.parchment,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
