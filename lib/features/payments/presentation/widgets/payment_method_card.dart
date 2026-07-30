import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grocery_app/core/theme/app_colors.dart';

class PaymentMethodCard extends StatelessWidget {
  final bool isSubscription;
  final String selectedPaymentMethod;
  final ValueChanged<String> onSelected;

  const PaymentMethodCard({
    super.key,
    required this.isSubscription,
    required this.selectedPaymentMethod,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showPaymentMethodSelectionDialog(context, theme, isDark);
      },
      child: Container(
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _paymentMethodIcon(selectedPaymentMethod),
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
                    'Payment Method',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _paymentMethodLabel(selectedPaymentMethod),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.charcoal87 : AppColors.parchment,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.chevron_right_rounded,
                color: theme.hintColor,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _paymentMethodIcon(String method) {
    switch (method) {
      case 'UPI':
        return Icons.account_balance_wallet_rounded;
      case 'CARD':
        return Icons.credit_card_rounded;
      case 'NETBANKING':
        return Icons.account_balance_rounded;
      case 'INSTALLMENT':
        return Icons.payment_rounded;
      case 'COD':
      default:
        return Icons.money_rounded;
    }
  }

  String _paymentMethodLabel(String method) {
    switch (method) {
      case 'UPI':
        return 'UPI';
      case 'CARD':
        return 'Credit / Debit Card';
      case 'NETBANKING':
        return 'Net Banking';
      case 'INSTALLMENT':
        return 'Installment Plan';
      case 'COD':
      default:
        return 'Cash on Delivery';
    }
  }

  Future<void> _showPaymentMethodSelectionDialog(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) async {
    final String? newSelection = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.charcoal60 : AppColors.rawEarth12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Select Payment Method',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _buildPaymentOption(
                context,
                theme,
                isDark,
                'UPI',
                'UPI',
                'Pay securely using any UPI app',
                Icons.account_balance_wallet_rounded,
                AppColors.deepSoilGreen,
              ),
              const SizedBox(height: 12),
              _buildPaymentOption(
                context,
                theme,
                isDark,
                'CARD',
                'Credit / Debit Card',
                'Visa, Mastercard, RuPay & more',
                Icons.credit_card_rounded,
                AppColors.harvestAmber,
              ),
              const SizedBox(height: 12),
              if (isSubscription) ...[
                _buildPaymentOption(
                  context,
                  theme,
                  isDark,
                  'NETBANKING',
                  'Net Banking',
                  'Pay via your bank\'s online portal',
                  Icons.account_balance_rounded,
                  AppColors.rawEarth70,
                ),
                const SizedBox(height: 12),
              ],
              if (!isSubscription) ...[
                _buildPaymentOption(
                  context,
                  theme,
                  isDark,
                  'COD',
                  'Cash on Delivery',
                  'Pay when you receive your order',
                  Icons.money_rounded,
                  AppColors.rawEarth26,
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        );
      },
    );

    if (newSelection != null) {
      HapticFeedback.selectionClick();
      onSelected(newSelection);
    }
  }

  Widget _buildPaymentOption(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    String value,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    final isSelected = selectedPaymentMethod == value;

    return GestureDetector(
      onTap: () => Navigator.pop(context, value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? color
                : (isDark ? AppColors.charcoal87 : AppColors.parchment),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: const Icon(
                  Icons.check,
                  color: AppColors.parchment,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
