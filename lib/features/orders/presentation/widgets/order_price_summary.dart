import 'package:flutter/material.dart';
import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:grocery_app/features/orders/domain/entities/order_entity.dart';
import 'order_detail_card.dart';

class OrderPriceSummary extends StatelessWidget {
  final OrderEntity order;

  const OrderPriceSummary({
    super.key,
    required this.order,
  });

  Color _getPaymentStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PAID':
        return AppColors.deepSoilGreen;
      case 'PENDING':
        return AppColors.harvestAmber;
      case 'FAILED':
        return AppColors.rawEarth;
      default:
        return AppColors.rawEarth54;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return OrderDetailCard(
      icon: Icons.receipt_rounded,
      title: 'Payment Summary',
      color: AppColors.deepSoilGreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPriceRow(theme, 'Subtotal', order.subtotal),
          const SizedBox(height: 12),
          _buildPriceRow(
            theme,
            'Discount included',
            -order.discount,
            isDiscount: true,
          ),
          const SizedBox(height: 12),
          _buildPriceRow(theme, 'Delivery', order.deliveryCharges),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.harvestAmber.withValues(alpha: 0.1),
                  AppColors.harvestAmber.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Amount',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '₹${order.total.toStringAsFixed(2)}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.harvestAmber,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Payment status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _getPaymentStatusColor(order.paymentStatus).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getPaymentStatusColor(order.paymentStatus).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  order.paymentStatus == 'PAID'
                      ? Icons.check_circle_rounded
                      : Icons.pending_rounded,
                  color: _getPaymentStatusColor(order.paymentStatus),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment ${order.paymentStatus}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _getPaymentStatusColor(order.paymentStatus),
                        ),
                      ),
                      Text(
                        'via ${order.paymentMethod}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(
    ThemeData theme,
    String label,
    double value, {
    bool isDiscount = false,
  }) {
    final valueText = value >= 0
        ? '₹${value.toStringAsFixed(2)}'
        : '-₹${value.abs().toStringAsFixed(2)}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDiscount ? AppColors.harvestAmber : theme.hintColor,
          ),
        ),
        Text(
          valueText,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDiscount ? AppColors.harvestAmber : null,
          ),
        ),
      ],
    );
  }
}
