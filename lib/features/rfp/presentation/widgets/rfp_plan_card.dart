import 'package:flutter/material.dart';
import '../../domain/entities/rfp_plan.dart';
import '../rfp_theme.dart';

/// Plan card widget for RFP subscription plan selection.
class RfpPlanCard extends StatelessWidget {
  final RfpPlan plan;
  final bool isSelected;
  final VoidCallback onTap;

  const RfpPlanCard({
    super.key,
    required this.plan,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPremium = plan.tier == 'premium';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(RfpTheme.spaceMd),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? RfpTheme.surfaceContainerHigh
                  : RfpTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(RfpTheme.radiusLg),
          border: Border.all(
            color: isSelected ? RfpTheme.primary : RfpTheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (plan.badge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: RfpTheme.spaceSm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: RfpTheme.primaryContainer,
                  borderRadius: BorderRadius.circular(RfpTheme.radiusFull),
                ),
                child: Text(
                  plan.badge!,
                  style: RfpTheme.labelSm.copyWith(
                    color: RfpTheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: RfpTheme.spaceSm),
            ],
            Row(
              children: [
                Text(
                  isPremium ? 'Premium Organic' : 'Standard',
                  style: RfpTheme.labelSm.copyWith(
                    color: RfpTheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  plan.isFull
                      ? '• FULL'
                      : '• ${plan.slotsRemaining} slots left',
                  style: RfpTheme.labelSm.copyWith(
                    color:
                        plan.isFull
                            ? RfpTheme.error
                            : RfpTheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Text(plan.name, style: RfpTheme.headlineSm),
            const SizedBox(height: RfpTheme.spaceXs),
            Text(
              plan.description,
              style: RfpTheme.bodySm.copyWith(color: RfpTheme.onSurfaceVariant),
              maxLines: 3,
            ),
            if (plan.totalPrice > 0) ...[
              const SizedBox(height: RfpTheme.spaceMd),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${plan.totalPrice.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                    style: RfpTheme.headlineSm.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (plan.hasDiscount) ...[
                    const SizedBox(width: 4),
                    Text(
                      '₹${plan.originalPrice!.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                      style: RfpTheme.bodySm.copyWith(
                        decoration: TextDecoration.lineThrough,
                        color: RfpTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                isPremium
                    ? '₹${plan.bookingAmount.toInt()} booking today'
                    : 'Total per season',
                style: RfpTheme.labelSm.copyWith(
                  color: RfpTheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
