import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grocery_app/core/theme/app_colors.dart';
import 'package:grocery_app/features/products/presentation/widgets/subscription_plan_card.dart';
import 'package:grocery_app/models/product_model.dart';

class SubscriptionOneTimeCard extends StatelessWidget {
  final Product product;
  final bool isSelected;
  final int quantity;
  final ValueChanged<int> onPlanSelected;

  const SubscriptionOneTimeCard({
    super.key,
    required this.product,
    required this.isSelected,
    required this.quantity,
    required this.onPlanSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accentColor = AppColors.harvestAmber;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onPlanSelected(-1);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [accentColor, accentColor.withValues(alpha: 0.85)],
                )
              : null,
          color: isSelected
              ? null
              : (isDark ? AppColors.darkSurfaceElevated : AppColors.pureWhite),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? accentColor.withValues(alpha: 0.5)
                : (isDark ? AppColors.parchment.withValues(alpha: 0.1) : AppColors.charcoal12),
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [
                  BoxShadow(
                    color: AppColors.charcoal.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                      ? AppColors.pureWhite.withValues(alpha: 0.2)
                      : AppColors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.pureWhite
                          : (isDark ? AppColors.parchment54 : AppColors.charcoal38),
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          size: 16,
                          color: AppColors.pureWhite,
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'One-Time Purchase',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? AppColors.pureWhite : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Single order, no commitment',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isSelected
                              ? AppColors.pureWhite.withValues(alpha: 0.7)
                              : theme.hintColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '₹${product.finalPrice.toStringAsFixed(0)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? AppColors.pureWhite : AppColors.harvestAmber,
                  ),
                ),
              ],
            ),
            if (isSelected) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.pureWhite.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SubscriptionPriceRow(
                  label: 'Total (1 time × $quantity)',
                  amount: product.finalPrice * quantity,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
