import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:grocery_app/features/orders/domain/entities/order_entity.dart';
import 'package:grocery_app/services/api_config.dart';
import 'order_detail_card.dart';
import 'order_tracking_history_sheet.dart';

class TimelineStep {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isCompleted;
  final bool isCurrent;

  const TimelineStep({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isCompleted,
    required this.isCurrent,
  });
}

class OrderTrackingTimeline extends StatelessWidget {
  final OrderEntity order;
  final OrderTrackingEntity? tracking;

  const OrderTrackingTimeline({
    super.key,
    required this.order,
    required this.tracking,
  });

  String _formatShortDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  void _showTrackingHistorySheet(BuildContext context, ThemeData theme, bool isDark) {
    if (tracking == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (context) => TrackingHistorySheet(
        tracking: tracking!,
        theme: theme,
        isDark: isDark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasEvents = tracking != null && tracking!.trackingEvents.isNotEmpty;

    return OrderDetailCard(
      icon: Icons.timeline_rounded,
      title: 'Order Timeline',
      color: AppColors.harvestAmber,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTrackingTimeline(theme, isDark, context),
          if (hasEvents) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => _showTrackingHistorySheet(context, theme, isDark),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.deepSoilGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.history_rounded,
                      size: 18,
                      color: AppColors.harvestAmber,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'See all ${tracking!.trackingEvents.length} updates',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.harvestAmber,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: AppColors.harvestAmber,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTrackingTimeline(ThemeData theme, bool isDark, BuildContext context) {
    final steps = _getTrackingTimelineSteps();

    return Column(
      children: List.generate(steps.length, (index) {
        final step = steps[index];
        final isLast = index == steps.length - 1;
        final isCompleted = step.isCompleted;
        final isCurrent = step.isCurrent;

        return GestureDetector(
          onTap: () {
            if (tracking != null && tracking!.trackingEvents.isNotEmpty) {
              _showTrackingHistorySheet(context, theme, isDark);
            }
          },
          behavior: HitTestBehavior.opaque,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isCompleted || isCurrent
                          ? step.color
                          : (isDark ? AppColors.charcoal87 : AppColors.parchment),
                      shape: BoxShape.circle,
                      boxShadow: isCurrent
                          ? [
                              BoxShadow(
                                color: step.color.withValues(alpha: 0.4),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      isCompleted ? Icons.check_rounded : step.icon,
                      color: isCompleted || isCurrent
                          ? AppColors.parchment
                          : (isDark ? AppColors.rawEarth70 : AppColors.rawEarth26),
                      size: 16,
                    ),
                  ),
                  if (!isLast)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 2,
                      height: 40,
                      color: isCompleted
                          ? step.color.withValues(alpha: 0.5)
                          : (isDark ? AppColors.charcoal87 : AppColors.parchment),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              step.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isCompleted || isCurrent ? null : theme.hintColor,
                              ),
                            ),
                          ),
                          if (tracking != null && tracking!.trackingEvents.isNotEmpty)
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: theme.hintColor.withValues(alpha: 0.5),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        step.subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  List<TimelineStep> _getTrackingTimelineSteps() {
    final rawStatus = tracking?.status.isNotEmpty == true
        ? tracking!.status
        : order.status;
    final status = rawStatus.toUpperCase().replaceAll(' ', '_');
    final steps = <TimelineStep>[];

    steps.add(
      TimelineStep(
        title: 'Order Placed',
        subtitle: _formatShortDate(order.createdAt),
        icon: Icons.shopping_bag_outlined,
        color: AppColors.harvestAmber,
        isCompleted: true,
        isCurrent: status == 'PLACED' || status == 'CREATED',
      ),
    );

    final isShipped = [
      'PACKED',
      'PICKED_UP',
      'PICKUP',
      'MANIFESTED',
      'SHIPPED',
      'IN_TRANSIT',
      'OUT_FOR_DELIVERY',
      'DELIVERED',
    ].contains(status);
    final isCurrentShipped = [
      'PACKED',
      'PICKED_UP',
      'PICKUP',
      'MANIFESTED',
      'SHIPPED',
      'IN_TRANSIT',
    ].contains(status);

    String shippedSubtitle = 'Waiting for shipment';
    if (isShipped && tracking != null && tracking!.trackingEvents.isNotEmpty) {
      final shippedEvent = tracking!.trackingEvents.cast<TrackingEventEntity?>().firstWhere((e) {
        final s = e!.status.toUpperCase().replaceAll(' ', '_');
        return s == 'SHIPPED' || s == 'PICKED_UP' || s == 'IN_TRANSIT';
      }, orElse: () => tracking!.trackingEvents.first);

      if (shippedEvent != null && shippedEvent.timestamp.year != 1970) {
        shippedSubtitle = _formatShortDate(shippedEvent.timestamp);
      } else {
        shippedSubtitle = 'Package is on the way';
      }
    } else if (isShipped) {
      shippedSubtitle = 'Package is on the way';
    }

    steps.add(
      TimelineStep(
        title: 'Shipped',
        subtitle: shippedSubtitle,
        icon: Icons.local_shipping_outlined,
        color: AppColors.harvestAmber,
        isCompleted: isShipped && !isCurrentShipped,
        isCurrent: isCurrentShipped,
      ),
    );

    final isOutForDelivery = ['OUT_FOR_DELIVERY', 'DELIVERED'].contains(status);

    String outForDeliverySubtitle = 'Pending';
    if (isOutForDelivery && tracking != null && tracking!.trackingEvents.isNotEmpty) {
      final ofdEvent = tracking!.trackingEvents.cast<TrackingEventEntity?>().firstWhere((e) {
        final s = e!.status.toUpperCase().replaceAll(' ', '_');
        return s == 'OUT_FOR_DELIVERY' || s.contains('OFD');
      }, orElse: () => null);

      if (ofdEvent != null && ofdEvent.timestamp.year != 1970) {
        outForDeliverySubtitle = _formatShortDate(ofdEvent.timestamp);
      } else {
        outForDeliverySubtitle = 'Package is with the delivery agent';
      }
    } else if (isOutForDelivery) {
      outForDeliverySubtitle = 'Package is with the delivery agent';
    }

    steps.add(
      TimelineStep(
        title: 'Out for Delivery',
        subtitle: outForDeliverySubtitle,
        icon: Icons.delivery_dining_outlined,
        color: AppColors.harvestAmber,
        isCompleted: status == 'DELIVERED',
        isCurrent: status == 'OUT_FOR_DELIVERY',
      ),
    );

    final isDelivered = status == 'DELIVERED';

    String deliveredSubtitle;
    if (isDelivered) {
      if (tracking != null && tracking!.trackingEvents.isNotEmpty) {
        final deliveredEvent = tracking!.trackingEvents.firstWhere(
          (e) => e.status.toUpperCase().contains('DELIVER'),
          orElse: () => tracking!.trackingEvents.first,
        );
        if (deliveredEvent.timestamp.year != 1970) {
          deliveredSubtitle = _formatShortDate(deliveredEvent.timestamp);
        } else {
          deliveredSubtitle = _formatShortDate(order.updatedAt);
        }
      } else {
        deliveredSubtitle = _formatShortDate(order.updatedAt);
      }
    } else {
      if (!ApiConfig.showExpectedDeliveryDate) {
        deliveredSubtitle = ApiConfig.alternativeDeliveryText;
      } else if (tracking?.estimatedDelivery != null && tracking!.estimatedDelivery!.year != 1970) {
        deliveredSubtitle = 'Expected: ${DateFormat('MMM d').format(tracking!.estimatedDelivery!)}';
      } else if (order.expectedDeliveryDate.year != 1970) {
        deliveredSubtitle = 'Expected: ${DateFormat('MMM d').format(order.expectedDeliveryDate)}';
      } else {
        deliveredSubtitle = 'TBD';
      }
    }

    steps.add(
      TimelineStep(
        title: 'Delivered',
        subtitle: deliveredSubtitle,
        icon: Icons.home_outlined,
        color: AppColors.harvestAmber,
        isCompleted: isDelivered,
        isCurrent: isDelivered,
      ),
    );

    return steps;
  }
}


