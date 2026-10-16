import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/rfp_booking.dart';

/// Card widget representing a single customer RFP subscription.
class RfpSubscriptionCard extends StatelessWidget {
  final RfpBooking booking;
  final VoidCallback? onTap;

  const RfpSubscriptionCard({super.key, required this.booking, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final df = DateFormat('dd MMM');
    final dateRange =
        '${df.format(booking.startDate)} — ${df.format(booking.endDate)}';
    final deliveryDaysStr =
        booking.deliveryDays.isNotEmpty
            ? booking.deliveryDays.join(' · ')
            : 'Weekly';
    final planCount =
        booking.patchConfigs.isNotEmpty ? booking.patchConfigs.length : 1;

    // Upcoming delivery determination
    String? nextDeliveryText;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final upcomingList =
        booking.deliveries.where((d) {
          final s = d.status.toLowerCase();
          return s == 'upcoming' ||
              s == 'scheduled' ||
              s == 'pending' ||
              !d.date.isBefore(today);
        }).toList();
    if (upcomingList.isNotEmpty) {
      upcomingList.sort((a, b) => a.date.compareTo(b.date));
      nextDeliveryText = df.format(upcomingList.first.date);
    }

    final rawStatus = booking.status.trim().toUpperCase();
    final statusColor = _statusColor(rawStatus);
    final statusBgColor = statusColor.withValues(alpha: 0.12);

    final title =
        booking.batchName?.isNotEmpty == true
            ? booking.batchName!
            : (booking.planName.isNotEmpty
                ? booking.planName
                : 'BATCH #${booking.batchNumber}');

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Batch / Plan name & Status badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        rawStatus,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                if (booking.batchName != null &&
                    booking.planName.isNotEmpty &&
                    booking.planName != title) ...[
                  const SizedBox(height: 3),
                  Text(
                    booking.planName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.deepSoilGreen.withValues(alpha: 0.9),
                    ),
                  ),
                ],
                const SizedBox(height: 10),

                // Date range & Days
                Text(
                  dateRange,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.textTheme.bodyLarge?.color?.withValues(
                      alpha: 0.85,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  deliveryDaysStr,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textTheme.bodyMedium?.color?.withValues(
                      alpha: 0.65,
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                Divider(
                  height: 1,
                  color: theme.dividerColor.withValues(alpha: 0.12),
                ),
                const SizedBox(height: 12),

                // Plan count & Next delivery
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$planCount ${planCount == 1 ? "Plan" : "Plans"}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                        if (nextDeliveryText != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                'Next delivery: ',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.textTheme.bodyMedium?.color
                                      ?.withValues(alpha: 0.6),
                                ),
                              ),
                              Text(
                                nextDeliveryText,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.deepSoilGreen,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),

                    // View subscription CTA
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View subscription',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.deepSoilGreen,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: AppColors.deepSoilGreen,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'ACTIVE':
        return AppColors.deepSoilGreen;
      case 'PENDING_PAYMENT':
      case 'PENDING':
        return AppColors.harvestAmber;
      case 'COMPLETED':
        return const Color(0xFF2B6CB0);
      case 'CANCELLED':
        return const Color(0xFFE53E3E);
      default:
        return AppColors.charcoal;
    }
  }
}
