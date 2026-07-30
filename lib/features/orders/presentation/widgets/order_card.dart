import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:grocery_app/features/orders/domain/entities/order_entity.dart';
import 'package:grocery_app/services/api_config.dart';
import 'order_status_helper.dart';

class AnimatedOrderCard extends StatelessWidget {
  final OrderEntity order;
  final int index;
  final AnimationController staggerController;
  final int totalItems;
  final VoidCallback onTap;

  const AnimatedOrderCard({
    super.key,
    required this.order,
    required this.index,
    required this.staggerController,
    required this.totalItems,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final startInterval = (index / totalItems) * 0.6;
    final endInterval = startInterval + 0.4;

    final slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: staggerController,
        curve: Interval(startInterval, endInterval, curve: Curves.easeOutCubic),
      ),
    );

    final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: staggerController,
        curve: Interval(startInterval, endInterval, curve: Curves.easeOut),
      ),
    );

    return AnimatedBuilder(
      animation: staggerController,
      builder: (context, child) {
        return FadeTransition(
          opacity: fadeAnimation,
          child: SlideTransition(position: slideAnimation, child: child),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          children: [
            ModernOrderCard(order: order, onTap: onTap),
            if (index < totalItems - 1) ...[
              const SizedBox(height: 16),
              Divider(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                thickness: 1,
                indent: 16,
                endIndent: 16,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ModernOrderCard extends StatelessWidget {
  final OrderEntity order;
  final VoidCallback onTap;

  const ModernOrderCard({
    super.key,
    required this.order,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final status = OrderStatusHelper.getStatusInfo(order.status);




    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceElevated : AppColors.parchment,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? AppColors.charcoal.withValues(alpha: 0.3)
                  : AppColors.deepSoilGreen.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: -4,
            ),
          ],
        ),
        child: Column(
          children: [
            // Header with status
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: status.color.withValues(alpha: 0.08),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: status.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(status.icon, color: status.color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          status.label,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: status.color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Order #${order.orderNumber}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${order.total.toStringAsFixed(0)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.harvestAmber,
                        ),
                      ),
                      Text(
                        '${order.items.length} items',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Products preview
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildProductsPreview(context, isDark),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: theme.hintColor,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          ApiConfig.showExpectedDeliveryDate
                              ? _formatDate(order.expectedDeliveryDate)
                              : ApiConfig.alternativeDeliveryText,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.hintColor,
                            fontSize: 10,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.visible,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.deepSoilGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'View Details',
                              style: TextStyle(
                                color: AppColors.harvestAmber,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 12,
                              color: AppColors.harvestAmber,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsPreview(BuildContext context, bool isDark) {
    final items = order.items;
    final displayItems = items.take(3).toList();
    final remainingCount = items.length - 3;

    return Row(
      children: [
        SizedBox(
          width: 80 + (displayItems.length - 1) * 20.0,
          height: 50,
          child: Stack(
            children: List.generate(displayItems.length, (index) {
              final item = displayItems[index];
              final imageUrl = item.productDetails.productImages.isNotEmpty
                  ? item.productDetails.productImages[0].image
                  : null;
              return Positioned(
                left: index * 20.0,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkSurfaceElevated
                          : AppColors.parchment,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.charcoal.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: isDark
                                  ? AppColors.darkSurfaceElevated
                                  : AppColors.parchment,
                              child: const Center(
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) =>
                                _buildPlaceholder(isDark),
                          )
                        : _buildPlaceholder(isDark),
                  ),
                ),
              );
            }),
          ),
        ),
        if (remainingCount > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceElevated : AppColors.parchment,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '+$remainingCount',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.parchment70 : AppColors.charcoal60,
              ),
            ),
          ),
        ],
        const Spacer(),
        Expanded(
          flex: 2,
          child: Text(
            items.first.productDetails.productName,
            style: Theme.of(context)
                .textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w500),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder(bool isDark) {
    return Container(
      color: isDark ? AppColors.darkSurfaceElevated : AppColors.parchment,
      child: Icon(
        Icons.image_outlined,
        color: isDark ? AppColors.parchment24 : AppColors.rawEarth26,
        size: 20,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

}
