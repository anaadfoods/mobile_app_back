import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/rfp_booking.dart';
import '../rfp_theme.dart';

/// Progress card on Dashboard showing batch progress, weeks, and next delivery.
class RfpProgressCard extends StatelessWidget {
  final RfpBooking booking;
  final DateFormat df;

  const RfpProgressCard({super.key, required this.booking, required this.df});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final totalDurationDays =
        booking.endDate.difference(booking.startDate).inDays;
    final totalWeeks = totalDurationDays > 0 ? (totalDurationDays ~/ 7) : 12;

    int currentWeek;
    if (now.isBefore(booking.startDate)) {
      currentWeek = 1;
    } else if (now.isAfter(booking.endDate)) {
      currentWeek = totalWeeks;
    } else {
      currentWeek = (now.difference(booking.startDate).inDays ~/ 7) + 1;
      if (currentWeek > totalWeeks) currentWeek = totalWeeks;
    }

    final weeksRemaining = (totalWeeks - currentWeek).clamp(0, totalWeeks);
    final progressFraction =
        totalWeeks > 0 ? (currentWeek / totalWeeks).clamp(0.05, 1.0) : 0.05;

    final upcomingList =
        booking.deliveries
            .where(
              (d) =>
                  d.status == 'upcoming' ||
                  d.status == 'scheduled' ||
                  d.date.isAfter(now),
            )
            .toList();
    upcomingList.sort((a, b) => a.date.compareTo(b.date));
    final nextDelivery = upcomingList.isNotEmpty ? upcomingList.first : null;

    final nextDeliveryDateStr =
        nextDelivery != null
            ? '${nextDelivery.dayOfWeek}, ${df.format(nextDelivery.date)}'
            : 'Harvest in progress';

    final totalWeight =
        booking.patchConfigs.isNotEmpty
            ? booking.patchConfigs.fold<double>(
              0.0,
              (sum, c) => sum + c.selectedWeight,
            )
            : (nextDelivery?.totalWeight ?? 5.0);

    final nextDeliveryDescStr =
        nextDelivery != null
            ? '${booking.planName} • ${totalWeight.toStringAsFixed(1)} KG'
            : 'All deliveries for cohort scheduled';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: RfpTheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        boxShadow: RfpTheme.shadowSm,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            bottom: -30,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: RfpTheme.surface.withValues(alpha: 0.08),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: RfpTheme.primary,
                      borderRadius: BorderRadius.circular(RfpTheme.radiusFull),
                    ),
                    child: Text(
                      'Batch #${booking.batchNumber}',
                      style: RfpTheme.labelSm.copyWith(
                        color: RfpTheme.inversePrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${df.format(booking.startDate)} - ${df.format(booking.endDate)}',
                    style: TextStyle(
                      color: RfpTheme.onPrimaryContainer.withValues(
                        alpha: 0.85,
                      ),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.verified,
                    color: RfpTheme.onPrimaryContainer,
                    size: 18,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    'Week $currentWeek of $totalWeeks',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '$weeksRemaining weeks remaining',
                    style: TextStyle(
                      color: RfpTheme.onPrimaryContainer.withValues(
                        alpha: 0.90,
                      ),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Progress bar
              Container(
                height: 6,
                width: double.infinity,
                padding: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: RfpTheme.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progressFraction,
                  child: Container(
                    decoration: BoxDecoration(
                      color: RfpTheme.secondaryFixed,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Next delivery highlight
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: RfpTheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: RfpTheme.shadowSm,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: RfpTheme.surfaceContainer,
                      ),
                      child: const Icon(
                        Icons.local_shipping,
                        color: RfpTheme.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Next Delivery',
                            style: TextStyle(
                              color: RfpTheme.onSurfaceVariant,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                          ),
                          Text(
                            nextDeliveryDateStr,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            nextDeliveryDescStr,
                            style: const TextStyle(
                              color: Color(0xFF2D6A4F),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: RfpTheme.primary,
                        borderRadius: BorderRadius.circular(
                          RfpTheme.radiusFull,
                        ),
                      ),
                      child: const Text(
                        'Track',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
