import 'package:flutter/material.dart';
import '../../domain/entities/rfp_plan.dart';
import '../../domain/entities/rfp_batch.dart';
import '../../domain/entities/rfp_pricing.dart';
import '../rfp_theme.dart';

/// Payment option selection & split transparency section shown in RFP Checkout.
/// Allows the user to choose between paying the booking deposit or paying in full.
class RfpSplitPaymentSection extends StatelessWidget {
  final RfpPlan? plan;
  final RfpBatch? batch;
  final RfpPricing? pricing;
  final String selectedPaymentType; // 'booking' or 'full'
  final ValueChanged<String>? onPaymentTypeChanged;

  const RfpSplitPaymentSection({
    super.key,
    required this.plan,
    required this.batch,
    this.pricing,
    this.selectedPaymentType = 'booking',
    this.onPaymentTypeChanged,
  });

  String _fmt(num n) => n.toInt().toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );

  @override
  Widget build(BuildContext context) {
    if (plan == null && pricing == null) return const SizedBox.shrink();

    final dueToday = pricing?.bookingAmount ?? (plan?.bookingAmount ?? 0);
    final dueLater = pricing?.remainingAmount ?? (plan?.remainingAmount ?? 0);
    final totalAmount =
        pricing?.finalPrice ?? (plan?.totalPrice ?? (dueToday + dueLater));
    final isFull = selectedPaymentType == 'full';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            'SPLIT PAYMENT TRANSPARENCY',
            style: RfpTheme.labelSm.copyWith(
              color: RfpTheme.onSurfaceVariant,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: RfpTheme.spaceMd),

        // Option 1: Pay Booking Amount (Split Payment)
        _buildPaymentOptionCard(
          isSelected: !isFull,
          onTap: () => onPaymentTypeChanged?.call('booking'),
          badgeText: 'RECOMMENDED',
          badgeColor: const Color(0xFFC9EEA9),
          badgeTextColor: const Color(0xFF003629),
          title: 'Pay Booking Amount (Split)',
          todayTitle: 'Due Today',
          todayAmountText: '₹${_fmt(dueToday)}',
          todaySublabel: 'Initial Booking Deposit',
          laterTitle: 'Due by Wk 3',
          laterAmountText: dueLater > 0 ? '₹${_fmt(dueLater)}' : '₹0',
          laterSublabel: 'Auto-debit on Week 3',
          description:
              'Stitch your batch reservation now with a low deposit. Remaining balance is due before delivery schedule begins.',
        ),

        const SizedBox(height: RfpTheme.spaceMd),

        // Option 2: Pay in Full
        _buildPaymentOptionCard(
          isSelected: isFull,
          onTap: () => onPaymentTypeChanged?.call('full'),
          badgeText: 'ONE-TIME PAYMENT',
          badgeColor: const Color(0xFFE8ECE9),
          badgeTextColor: const Color(0xFF003629),
          title: 'Pay In Full (100% Upfront)',
          todayTitle: 'Pay In Full',
          todayAmountText: '₹${_fmt(totalAmount)}',
          todaySublabel: '100% Upfront Today',
          laterTitle: 'Due Later',
          laterAmountText: '₹0',
          laterSublabel: 'Zero remaining balance',
          description:
              'Complete payment for all 12 weeks of organic harvest upfront. Completely hassle-free with zero future dues.',
        ),

        const SizedBox(height: RfpTheme.spaceMd),
        _buildDeliveryNote(isFull, dueLater),
        const SizedBox(height: RfpTheme.spaceMd),
        _buildCrateGuarantee(),
      ],
    );
  }

  Widget _buildPaymentOptionCard({
    required bool isSelected,
    required VoidCallback onTap,
    required String badgeText,
    required Color badgeColor,
    required Color badgeTextColor,
    required String title,
    required String todayTitle,
    required String todayAmountText,
    required String todaySublabel,
    required String laterTitle,
    required String laterAmountText,
    required String laterSublabel,
    required String description,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(RfpTheme.spaceMd),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? const Color(0xFF003629).withValues(alpha: 0.05)
                  : RfpTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(RfpTheme.radiusLg),
          border: Border.all(
            color:
                isSelected ? const Color(0xFF003629) : RfpTheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? RfpTheme.shadowMd : RfpTheme.shadowSm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color:
                      isSelected ? const Color(0xFF003629) : RfpTheme.outline,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: RfpTheme.headlineSm.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color:
                          isSelected
                              ? const Color(0xFF003629)
                              : RfpTheme.onSurface,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2.5,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(RfpTheme.radiusFull),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      color: badgeTextColor,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        todayTitle,
                        style: RfpTheme.labelSm.copyWith(
                          color: RfpTheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        todayAmountText,
                        style: RfpTheme.headlineLg.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color:
                              isSelected
                                  ? const Color(0xFF003629)
                                  : RfpTheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        todaySublabel,
                        style: RfpTheme.labelSm.copyWith(
                          color: RfpTheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 48,
                  color: RfpTheme.outlineVariant.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        laterTitle,
                        style: RfpTheme.labelSm.copyWith(
                          color: RfpTheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        laterAmountText,
                        style: RfpTheme.headlineLg.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: RfpTheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        laterSublabel,
                        style: RfpTheme.labelSm.copyWith(
                          color: RfpTheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: RfpTheme.bodySm.copyWith(
                color: RfpTheme.onSurfaceVariant.withValues(alpha: 0.8),
                fontSize: 11,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryNote(bool isFull, num remainingAmount) {
    return Container(
      padding: const EdgeInsets.all(RfpTheme.spaceMd),
      decoration: BoxDecoration(
        color: RfpTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(RfpTheme.radiusMd),
        border: Border.all(
          color: RfpTheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: RfpTheme.primary),
          const SizedBox(width: RfpTheme.spaceSm),
          Expanded(
            child: Text(
              isFull
                  ? 'Your 12-week harvest subscription is 100% paid upfront. Deliveries will arrive without any future payment obligations.'
                  : 'Your initial deliveries will begin upon booking confirmation. The remaining balance of ₹${_fmt(remainingAmount)} is scheduled for auto-debit before later deliveries.',
              style: RfpTheme.bodySm.copyWith(color: RfpTheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCrateGuarantee() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: RfpTheme.spaceMd,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: RfpTheme.secondaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(RfpTheme.radiusMd),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.verified_outlined,
            size: 20,
            color: RfpTheme.secondary,
          ),
          const SizedBox(width: RfpTheme.spaceSm),
          Expanded(
            child: Text(
              'Crate Guarantee: Cancel or pause anytime before Wk 3',
              style: RfpTheme.labelMd.copyWith(color: RfpTheme.secondary),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: RfpTheme.secondaryContainer,
              borderRadius: BorderRadius.circular(RfpTheme.radiusFull),
            ),
            child: Text(
              'Free Pause',
              style: RfpTheme.labelSm.copyWith(
                color: RfpTheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
