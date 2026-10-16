import 'package:flutter/material.dart';
import '../rfp_theme.dart';

/// Payment method selection tiles shown in Checkout.
class RfpPaymentMethodSelector extends StatelessWidget {
  final String selectedMethod;
  final ValueChanged<String> onSelect;

  const RfpPaymentMethodSelector({
    super.key,
    required this.selectedMethod,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select Payment Method', style: RfpTheme.headlineSm),
        const SizedBox(height: RfpTheme.spaceMd),
        _buildPaymentTile(
          'upi',
          Icons.qr_code,
          'UPI / QR Code',
          'Google Pay, PhonePe, Paytm, BHIM',
        ),
        const SizedBox(height: RfpTheme.spaceSm),
        _buildPaymentTile(
          'card',
          Icons.credit_card,
          'Credit / Debit Card',
          'Visa, Mastercard, RuPay & Amex',
        ),
        const SizedBox(height: RfpTheme.spaceSm),
        _buildPaymentTile(
          'netbanking',
          Icons.account_balance,
          'Net Banking',
          'All major Indian banks supported',
        ),
      ],
    );
  }

  Widget _buildPaymentTile(
    String method,
    IconData icon,
    String title,
    String subtitle,
  ) {
    final isSelected = selectedMethod == method;
    return GestureDetector(
      onTap: () => onSelect(method),
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
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: RfpTheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(RfpTheme.radiusMd),
              ),
              child: Icon(icon, color: RfpTheme.primary, size: 20),
            ),
            const SizedBox(width: RfpTheme.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: RfpTheme.bodyMd.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: RfpTheme.bodySm.copyWith(
                      color: RfpTheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? RfpTheme.primary : RfpTheme.outline,
            ),
          ],
        ),
      ),
    );
  }
}
