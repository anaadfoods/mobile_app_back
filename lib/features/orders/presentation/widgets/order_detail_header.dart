import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:grocery_app/features/orders/domain/entities/order_entity.dart';
import 'order_status_helper.dart';

class OrderDetailHeader extends StatelessWidget {
  final OrderEntity order;
  final VoidCallback onBack;
  final VoidCallback onRefresh;

  const OrderDetailHeader({
    super.key,
    required this.order,
    required this.onBack,
    required this.onRefresh,
  });

  String _formatShortDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final status = OrderStatusHelper.getStatusInfo(order.status);

    return SliverToBoxAdapter(
      child: Container(
        constraints: const BoxConstraints(minHeight: 220),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [status.color, status.color.withValues(alpha: 0.8)],
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
          boxShadow: [
            BoxShadow(
              color: status.color.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.parchment.withValues(alpha: 0.1),
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: -30,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.parchment.withValues(alpha: 0.08),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.parchment),
                          onPressed: onBack,
                        ),
                        GestureDetector(
                          onTap: onRefresh,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.parchment.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.refresh_rounded,
                              color: AppColors.harvestAmber,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.parchment.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            status.icon,
                            size: 16,
                            color: AppColors.harvestAmber,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            status.label,
                            style: const TextStyle(
                              color: AppColors.harvestAmber,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Order #${order.orderNumber}',
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    color: AppColors.parchment,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Placed on ${_formatShortDate(order.createdAt)}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppColors.parchment.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: order.orderNumber));
                            HapticFeedback.mediumImpact();
                            SnackBarHelper.showSuccess(context, 'Order ID copied!');
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.parchment.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.copy_rounded,
                              color: AppColors.parchment,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
