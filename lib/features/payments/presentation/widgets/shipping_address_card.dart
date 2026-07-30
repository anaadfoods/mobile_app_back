import 'package:flutter/material.dart';
import 'package:grocery_app/core/theme/app_colors.dart';
import 'package:grocery_app/models/shipping_details.dart';

class ShippingAddressCard extends StatelessWidget {
  final ShippingDetails? shippingDetails;

  const ShippingAddressCard({
    super.key,
    required this.shippingDetails,
  });

  @override
  Widget build(BuildContext context) {
    if (shippingDetails == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: AppColors.harvestAmber,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Delivery Address',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.deepSoilGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 14,
                      color: AppColors.amberWarn,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Verified',
                      style: TextStyle(
                        color: AppColors.amberWarn,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (shippingDetails!.name.isNotEmpty) ...[
            Text(
              shippingDetails!.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
          ],
          Text(shippingDetails!.address, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 8),
          Text(
            '${shippingDetails!.city}, ${shippingDetails!.state} - ${shippingDetails!.pincode}',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.phone_rounded, size: 16, color: theme.hintColor),
              const SizedBox(width: 6),
              Text(
                shippingDetails!.phone,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
