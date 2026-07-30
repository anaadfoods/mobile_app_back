import 'package:flutter/material.dart';
import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:grocery_app/features/orders/domain/entities/order_entity.dart';
import 'package:grocery_app/features/misc/presentation/screens/help_screen.dart';
import 'order_detail_card.dart';

class OrderActionsCard extends StatelessWidget {
  final OrderEntity order;
  final bool isCancelling;
  final VoidCallback onDownloadInvoice;
  final VoidCallback onCancelOrder;

  const OrderActionsCard({
    super.key,
    required this.order,
    required this.isCancelling,
    required this.onDownloadInvoice,
    required this.onCancelOrder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final canCancel = order.status != 'DELIVERED' &&
        order.status != 'CANCELLED' &&
        order.status != 'SHIPPED';

    final isDelivered = order.status == 'DELIVERED';

    return OrderDetailCard(
      icon: Icons.touch_app_rounded,
      title: 'Quick Actions',
      color: AppColors.harvestAmber,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Help button
          _buildActionButton(
            theme,
            isDark,
            icon: Icons.support_agent_rounded,
            title: 'Need Help?',
            subtitle: 'Contact support for any issues',
            color: AppColors.harvestAmber,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HelpScreen(orderNumber: order.orderNumber),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          // Download invoice
          Opacity(
            opacity: isDelivered ? 1.0 : 0.5,
            child: _buildActionButton(
              theme,
              isDark,
              icon: Icons.download_rounded,
              title: 'Download Invoice',
              subtitle: isDelivered
                  ? 'Get PDF copy of your order'
                  : 'Wait until you get your product',
              color: AppColors.harvestAmber,
              onTap: isDelivered ? onDownloadInvoice : () {},
            ),
          ),
          if (canCancel) ...[
            const SizedBox(height: 12),
            _buildActionButton(
              theme,
              isDark,
              icon: Icons.cancel_outlined,
              title: 'Cancel Order',
              subtitle: 'Request order cancellation',
              color: isDark ? AppColors.darkSoftRed : AppColors.softRed,
              isDestructive: true,
              isLoading: isCancelling,
              onTap: onCancelOrder,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton(
    ThemeData theme,
    bool isDark, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool isDestructive = false,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: color,
                      ),
                    )
                  : Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDestructive ? color : null,
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
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: color),
          ],
        ),
      ),
    );
  }
}
