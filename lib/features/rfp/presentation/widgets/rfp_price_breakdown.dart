import 'package:flutter/material.dart';
import '../../domain/entities/rfp_pricing.dart';
import '../rfp_theme.dart';

/// Price breakdown card shown in Checkout.
class RfpPriceBreakdown extends StatelessWidget {
  final RfpPricing? pricing;

  const RfpPriceBreakdown({super.key, required this.pricing});

  @override
  Widget build(BuildContext context) {
    if (pricing == null) {
      return Container(
        padding: const EdgeInsets.all(RfpTheme.spaceLg),
        decoration: BoxDecoration(
          color: RfpTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(RfpTheme.radiusLg),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: RfpTheme.primary),
        ),
      );
    }

    final p = pricing!;
    return Container(
      padding: const EdgeInsets.all(RfpTheme.spaceLg),
      decoration: BoxDecoration(
        color: RfpTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(RfpTheme.radiusLg),
        boxShadow: RfpTheme.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Price Breakup', style: RfpTheme.headlineSm),
          const SizedBox(height: RfpTheme.spaceMd),
          _priceRow(
            'Total Plan Value',
            '₹${p.basePrice.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
          ),
          if (p.discountLabel != null)
            _priceRow(
              p.discountLabel!,
              '-₹${p.discountAmount.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
              isDiscount: true,
            ),
          const Divider(color: RfpTheme.outlineVariant, height: 24),
          _priceRow(
            'Final Plan Value',
            '₹${p.finalPrice.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
            isBold: true,
          ),
          const SizedBox(height: RfpTheme.spaceMd),
          // Booking amount highlight
          Container(
            padding: const EdgeInsets.all(RfpTheme.spaceMd),
            decoration: BoxDecoration(
              color: RfpTheme.secondaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(RfpTheme.radiusMd),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Booking Amount Today',
                      style: RfpTheme.labelMd.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Secures your harvest slots',
                      style: RfpTheme.labelSm.copyWith(
                        color: RfpTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                Text(
                  '₹${p.bookingAmount.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                  style: RfpTheme.headlineSm.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: RfpTheme.spaceSm),
          _priceRow(
            'Remaining Amount (payable later)',
            '₹${p.remainingAmount.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
          ),
          const SizedBox(height: RfpTheme.spaceMd),
          // Info box
          Container(
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
                const Icon(
                  Icons.info_outline,
                  size: 20,
                  color: RfpTheme.primary,
                ),
                const SizedBox(width: RfpTheme.spaceSm),
                Expanded(
                  child: Text(
                    'Only the Booking Amount (₹${p.bookingAmount.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')})'
                    ' is payable today. The remaining ₹${p.remainingAmount.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} will be billed incrementally'
                    ' according to your harvest schedule.',
                    style: RfpTheme.bodySm.copyWith(
                      color: RfpTheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(
    String label,
    String value, {
    bool isBold = false,
    bool isDiscount = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style:
                isBold
                    ? RfpTheme.bodyMd.copyWith(fontWeight: FontWeight.w600)
                    : RfpTheme.bodyMd,
          ),
          Text(
            value,
            style: (isBold
                    ? RfpTheme.bodyMd.copyWith(fontWeight: FontWeight.w600)
                    : RfpTheme.bodyMd)
                .copyWith(color: isDiscount ? RfpTheme.secondary : null),
          ),
        ],
      ),
    );
  }
}
