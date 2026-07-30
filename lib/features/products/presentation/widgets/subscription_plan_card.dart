import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grocery_app/core/theme/app_colors.dart';
import 'package:grocery_app/models/subscription_plan_model.dart';
import 'package:grocery_app/models/plan_Search_model.dart';
import 'package:grocery_app/services/plan_search_service.dart';

class SubscriptionPriceRow extends StatelessWidget {
  final String label;
  final double amount;

  const SubscriptionPriceRow({
    super.key,
    required this.label,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.pureWhite,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          '₹${amount.toStringAsFixed(0)}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.pureWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class SubscriptionPaymentChip extends StatelessWidget {
  final String label;
  final int value;
  final bool isSelected;
  final VoidCallback onTap;

  const SubscriptionPaymentChip({
    super.key,
    required this.label,
    required this.value,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.pureWhite
              : AppColors.pureWhite.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.charcoal : AppColors.pureWhite,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class SubscriptionPlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final PlanSearchResult planData;
  final bool isSelected;
  final bool isEnabled;
  final int index;
  final int quantity;
  final int paymentOption;
  final ValueChanged<int> onPlanSelected;
  final ValueChanged<int> onPaymentOptionChanged;

  const SubscriptionPlanCard({
    super.key,
    required this.plan,
    required this.planData,
    required this.isSelected,
    required this.isEnabled,
    required this.index,
    required this.quantity,
    required this.paymentOption,
    required this.onPlanSelected,
    required this.onPaymentOptionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accentColor = AppColors.harvestAmber;

    return GestureDetector(
      onTap: isEnabled
          ? () {
              HapticFeedback.selectionClick();
              onPlanSelected(index);
            }
          : null,
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
              : (isDark ? AppColors.darkMintGreen : AppColors.pureWhite),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? accentColor.withValues(alpha: 0.5)
                : (isDark ? AppColors.rawEarth26 : AppColors.charcoal12),
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
        child: Opacity(
          opacity: isEnabled ? 1.0 : 0.5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                          plan.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: isSelected
                                ? AppColors.pureWhite
                                : (isDark ? AppColors.pureWhite : null),
                            fontWeight: (isDark && !isSelected)
                                ? FontWeight.w900
                                : FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${plan.durationMonths} months • ${planData.discountPercentage.toStringAsFixed(0)}% off',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isSelected
                                ? AppColors.pureWhite.withValues(alpha: 0.7)
                                : (isDark ? AppColors.parchment70 : theme.hintColor),
                            fontWeight: (isDark && !isSelected)
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        isEnabled
                            ? '₹${planData.discountedPrice.toStringAsFixed(0)}'
                            : 'Unavailable',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? AppColors.pureWhite : AppColors.harvestAmber,
                        ),
                      ),
                      if (isEnabled)
                        Text(
                          plan.durationMonths == 1 ? '/one month' : '/month',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isSelected
                                ? AppColors.pureWhite.withValues(alpha: 0.6)
                                : (isDark ? AppColors.parchment70 : theme.hintColor),
                            fontWeight: (isDark && !isSelected)
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                    ],
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SubscriptionPriceRow(
                        label: 'Total (${plan.durationMonths}mo × $quantity)',
                        amount: planData.discountedPrice * plan.durationMonths * quantity,
                      ),
                      const SizedBox(height: 8),
                      if (paymentOption == 0)
                        SubscriptionPriceRow(
                          label: 'Pay Now',
                          amount: planData.discountedPrice * plan.durationMonths * quantity,
                        )
                      else
                        SubscriptionPriceRow(
                          label: 'Installment (${plan.installmentFrequencyMonths}mo)',
                          amount: planData.discountedPrice *
                              plan.installmentFrequencyMonths *
                              quantity,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    const Text(
                      'Payment:',
                      style: TextStyle(
                        color: AppColors.parchment70,
                        fontSize: 13,
                      ),
                    ),
                    SubscriptionPaymentChip(
                      label: 'One Time',
                      value: 0,
                      isSelected: paymentOption == 0,
                      onTap: () => onPaymentOptionChanged(0),
                    ),
                    if (plan.allowsInstallments)
                      SubscriptionPaymentChip(
                        label: 'Installment',
                        value: 1,
                        isSelected: paymentOption == 1,
                        onTap: () => onPaymentOptionChanged(1),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
