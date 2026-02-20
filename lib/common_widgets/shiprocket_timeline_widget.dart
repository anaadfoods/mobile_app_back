import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:grocery_app/models/order_tracking_model.dart';
import 'package:grocery_app/styles/colors.dart';

/// A modern widget displaying Shiprocket order tracking information.
/// Shows status stepper, AWB info, estimated delivery, and tracking events.
class ShiprocketTimelineWidget extends StatefulWidget {
  final OrderTracking tracking;
  final bool isDark;

  const ShiprocketTimelineWidget({
    super.key,
    required this.tracking,
    required this.isDark,
  });

  @override
  State<ShiprocketTimelineWidget> createState() =>
      _ShiprocketTimelineWidgetState();
}

class _ShiprocketTimelineWidgetState extends State<ShiprocketTimelineWidget> {
  bool _showAllEvents = false;

  // Status stages for the stepper
  static const _stages = [
    ('Manifested', Icons.inventory_2_outlined),
    ('Picked Up', Icons.local_shipping_outlined),
    ('In Transit', Icons.route_outlined),
    ('Out for Delivery', Icons.delivery_dining_outlined),
    ('Delivered', Icons.check_circle_outline),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tracking = widget.tracking;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(widget.isDark ? 0.3 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(theme),
          const SizedBox(height: 20),

          // Status Stepper
          _buildStatusStepper(theme, tracking.currentStageIndex),

          // AWB and Delivery Info
          if (tracking.awbNumber != null ||
              tracking.estimatedDelivery != null) ...[
            const SizedBox(height: 20),
            _buildInfoBanner(theme, tracking),
          ],

          // Tracking Events
          if (tracking.trackingEvents.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildTrackingEvents(theme, tracking.trackingEvents),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.local_shipping_rounded,
            color: AppColors.info,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Shipment Tracking',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _getStatusLabel(widget.tracking.orderStatus),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _getStatusColor(widget.tracking.orderStatus),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusStepper(ThemeData theme, int currentIndex) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_stages.length * 2 - 1, (index) {
          if (index.isOdd) {
            // Connector line
            final stageIndex = index ~/ 2;
            final isCompleted = stageIndex < currentIndex;
            return Container(
              width: 24,
              height: 3,
              decoration: BoxDecoration(
                color:
                    isCompleted
                        ? AppColors.success
                        : (widget.isDark ? Colors.grey[700] : Colors.grey[300]),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          } else {
            // Stage icon
            final stageIndex = index ~/ 2;
            final stage = _stages[stageIndex];
            final isCompleted = stageIndex < currentIndex;
            final isCurrent = stageIndex == currentIndex;

            return _buildStageIcon(
              theme,
              icon: stage.$2,
              label: stage.$1,
              isCompleted: isCompleted,
              isCurrent: isCurrent,
            );
          }
        }),
      ),
    );
  }

  Widget _buildStageIcon(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required bool isCompleted,
    required bool isCurrent,
  }) {
    final color =
        isCompleted
            ? AppColors.success
            : (isCurrent ? AppColors.info : Colors.grey);

    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color:
                isCompleted || isCurrent
                    ? color.withOpacity(0.15)
                    : (widget.isDark ? Colors.grey[800] : Colors.grey[100]),
            shape: BoxShape.circle,
            border: Border.all(
              color: isCompleted || isCurrent ? color : Colors.transparent,
              width: 2,
            ),
            boxShadow:
                isCurrent
                    ? [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                    : null,
          ),
          child: Icon(
            isCompleted ? Icons.check_rounded : icon,
            color:
                isCompleted || isCurrent
                    ? color
                    : (widget.isDark ? Colors.grey[600] : Colors.grey[400]),
            size: 20,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color:
                  isCompleted || isCurrent
                      ? theme.textTheme.bodyMedium?.color
                      : theme.hintColor,
              fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBanner(ThemeData theme, OrderTracking tracking) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:
            widget.isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.grey.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // AWB Number
          if (tracking.awbNumber != null)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AWB Number',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => _copyAwb(tracking.awbNumber!),
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            tracking.awbNumber!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontFamily: 'monospace',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.copy_rounded,
                          size: 16,
                          color: AppColors.info,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          if (tracking.awbNumber != null && tracking.estimatedDelivery != null)
            Container(
              width: 1,
              height: 36,
              margin: const EdgeInsets.symmetric(horizontal: 14),
              color: widget.isDark ? Colors.grey[700] : Colors.grey[300],
            ),

          // Estimated Delivery
          if (tracking.estimatedDelivery != null)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Expected Delivery',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat(
                      'MMM d, yyyy',
                    ).format(tracking.estimatedDelivery!),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTrackingEvents(ThemeData theme, List<TrackingEvent> events) {
    // Sort events by timestamp (newest first)
    final sortedEvents = List<TrackingEvent>.from(events)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final displayEvents =
        _showAllEvents ? sortedEvents : sortedEvents.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tracking History',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),

        // Events list
        ...displayEvents.asMap().entries.map((entry) {
          final index = entry.key;
          final event = entry.value;
          final isLast = index == displayEvents.length - 1;
          final isFirst = index == 0;

          return _buildEventItem(
            theme,
            event,
            isLast: isLast,
            isFirst: isFirst,
          );
        }),

        // Show more/less button
        if (sortedEvents.length > 3) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _showAllEvents = !_showAllEvents);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _showAllEvents
                        ? 'Show Less'
                        : 'Show ${sortedEvents.length - 3} More',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.info,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _showAllEvents
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.info,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEventItem(
    ThemeData theme,
    TrackingEvent event, {
    required bool isLast,
    required bool isFirst,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline dot and line
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: isFirst ? AppColors.info : Colors.grey,
                shape: BoxShape.circle,
                boxShadow:
                    isFirst
                        ? [
                          BoxShadow(
                            color: AppColors.info.withOpacity(0.4),
                            blurRadius: 6,
                          ),
                        ]
                        : null,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 50,
                color: widget.isDark ? Colors.grey[700] : Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 14),

        // Event content
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.activity.isNotEmpty ? event.activity : event.status,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: isFirst ? FontWeight.w600 : FontWeight.normal,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: theme.hintColor,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        event.location.isNotEmpty ? event.location : 'N/A',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      width: 4,
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: theme.hintColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(
                      DateFormat('MMM d, h:mm a').format(event.timestamp),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _copyAwb(String awb) {
    Clipboard.setData(ClipboardData(text: awb));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('AWB number copied!'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _getStatusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'MANIFESTED':
        return 'Order Manifested';
      case 'PICKED_UP':
      case 'PICKUP':
        return 'Picked Up by Courier';
      case 'IN_TRANSIT':
      case 'SHIPPED':
        return 'In Transit';
      case 'OUT_FOR_DELIVERY':
        return 'Out for Delivery';
      case 'DELIVERED':
        return 'Delivered';
      case 'CANCELLED':
        return 'Cancelled';
      case 'RTO':
        return 'Returned to Origin';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'DELIVERED':
        return AppColors.success;
      case 'CANCELLED':
      case 'RTO':
        return AppColors.error;
      case 'OUT_FOR_DELIVERY':
        return AppColors.warning;
      default:
        return AppColors.info;
    }
  }
}
