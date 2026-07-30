import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:grocery_app/features/orders/domain/entities/order_entity.dart';

class TrackingHistorySheet extends StatelessWidget {
  final OrderTrackingEntity tracking;
  final ThemeData theme;
  final bool isDark;

  const TrackingHistorySheet({
    super.key,
    required this.tracking,
    required this.theme,
    required this.isDark,
  });

  Map<String, List<TrackingEventEntity>> _groupEventsByDate() {
    final Map<String, List<TrackingEventEntity>> grouped = {};
    for (var event in tracking.trackingEvents) {
      final dateStr = DateFormat('EEEE, MMMM d, yyyy').format(event.timestamp);
      if (!grouped.containsKey(dateStr)) {
        grouped[dateStr] = [];
      }
      grouped[dateStr]!.add(event);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final groupedEvents = _groupEventsByDate();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : AppColors.parchment,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.charcoal60 : AppColors.rawEarth12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.harvestAmber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.local_shipping_rounded,
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
                        'Tracking History',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Courier details & updates',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(),
          if (groupedEvents.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'No tracking events logged yet.',
                  style: TextStyle(color: theme.hintColor),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                itemCount: groupedEvents.keys.length,
                itemBuilder: (context, dateIndex) {
                  final date = groupedEvents.keys.elementAt(dateIndex);
                  final events = groupedEvents[date]!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          date,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: AppColors.harvestAmber,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ...events.map((event) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 8, bottom: 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: const BoxDecoration(
                                      color: AppColors.deepSoilGreen,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  Container(
                                    width: 2,
                                    height: 48,
                                    color: AppColors.deepSoilGreen.withValues(alpha: 0.2),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      event.status,
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      event.activity,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.hintColor,
                                      ),
                                    ),
                                    if (event.location.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.location_on_outlined,
                                            size: 12,
                                            color: theme.hintColor,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            event.location,
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: theme.hintColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    const SizedBox(height: 2),
                                    Text(
                                      DateFormat('h:mm a').format(event.timestamp),
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.hintColor.withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
