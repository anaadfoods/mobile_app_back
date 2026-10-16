import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/rfp_booking.dart';
import '../../domain/entities/rfp_delivery.dart';
import 'rfp_timeline_item_tile.dart';

/// Seasonal Journey Harvest Log displaying the customer's actual delivery schedule.
///
/// Distinguishes completed, upcoming, and cancelled deliveries from backend data,
/// displays cancellation reasons when available, and allows filtering by week.
class RfpSeasonalHarvestLog extends StatefulWidget {
  final RfpBooking booking;
  final List<RfpDelivery> deliveries;

  const RfpSeasonalHarvestLog({
    super.key,
    required this.booking,
    required this.deliveries,
  });

  @override
  State<RfpSeasonalHarvestLog> createState() => _RfpSeasonalHarvestLogState();
}

class _RfpSeasonalHarvestLogState extends State<RfpSeasonalHarvestLog> {
  int? _selectedWeekFilter;

  @override
  Widget build(BuildContext context) {
    final currentWeek = _calculateCurrentWeek();
    final availableWeeks =
        widget.deliveries.map((d) => d.weekNumber).toSet().toList()..sort();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9ECEF), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'SEASONAL JOURNEY',
                    style: TextStyle(
                      color: Color(0xFF8B5E3C),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '12-Week Harvest Log',
                    style: TextStyle(
                      color: Color(0xFF1A202C),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF4F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Week $currentWeek of 12',
                  style: const TextStyle(
                    color: Color(0xFF2B4C7E),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          // Week Filter Chips if multiple weeks exist
          if (availableWeeks.length > 1) ...[
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(
                    label: 'All',
                    isSelected: _selectedWeekFilter == null,
                    onTap: () => setState(() => _selectedWeekFilter = null),
                  ),
                  const SizedBox(width: 6),
                  ...availableWeeks.map((w) {
                    final isSel = _selectedWeekFilter == w;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _buildFilterChip(
                        label: 'Week $w',
                        isSelected: isSel,
                        onTap:
                            () => setState(() {
                              _selectedWeekFilter = isSel ? null : w;
                            }),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Timeline items or empty state
          _buildTimeline(),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF003629) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeline() {
    if (widget.deliveries.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'No scheduled deliveries found for this subscription.',
            style: TextStyle(fontSize: 12, color: Color(0xFF718096)),
          ),
        ),
      );
    }

    final filtered =
        _selectedWeekFilter != null
            ? widget.deliveries
                .where((d) => d.weekNumber == _selectedWeekFilter)
                .toList()
            : List<RfpDelivery>.from(widget.deliveries);

    final sorted =
        filtered..sort((a, b) {
          final cmp = a.weekNumber.compareTo(b.weekNumber);
          return cmp != 0 ? cmp : a.date.compareTo(b.date);
        });

    final weekThemes = [
      'First Basket',
      'Mid-Week Batch',
      'Mon Dispatch',
      'Autumn Greens Edition',
      'Winter Squash Harvest',
      'Root Cellar Special',
      'Heirloom Brassica Drop',
      'Dawn Crop Festival',
      'Wild Herb Forage Box',
      'Orchard & Hearth Cask',
      'Sun-Dried & Ferments',
      'Final Season Thali',
    ];

    final items = <Widget>[];
    for (int i = 0; i < sorted.length; i++) {
      final delivery = sorted[i];
      final isLast = i == sorted.length - 1;
      final w = delivery.weekNumber;
      final theme = weekThemes[(w - 1).clamp(0, weekThemes.length - 1)];
      final dateStr = DateFormat('MMM d').format(delivery.date);
      final rawStatus = delivery.status.toLowerCase();

      final isCancelled =
          rawStatus == 'cancelled' || rawStatus == 'not_delivered';
      final isDelivered = rawStatus == 'delivered';
      final isUpcoming = rawStatus == 'upcoming';

      if (isCancelled) {
        items.add(
          RfpTimelineItemTile(
            node: RfpTimelineNodes.cancelled(),
            title: 'Week $w • $theme',
            trailingBadge: RfpTimelineNodes.cancelledBadge(),
            quoteReason:
                (delivery.cancellationReason != null &&
                        delivery.cancellationReason!.isNotEmpty)
                    ? delivery.cancellationReason
                    : null,
            isLast: isLast,
          ),
        );
      } else if (isDelivered) {
        final weight = delivery.totalWeight;
        final sub =
            weight > 0
                ? '${weight.toStringAsFixed(1)}kg assortment • Received & rated 5 ★'
                : (delivery.description ?? 'Received & verified');
        items.add(
          RfpTimelineItemTile(
            node: RfpTimelineNodes.completed(),
            title: 'Week $w • $theme',
            trailingText: 'Delivered $dateStr',
            subtitle: sub,
            isLast: isLast,
          ),
        );
      } else if (isUpcoming || rawStatus == 'out_for_delivery') {
        final isOut = rawStatus == 'out_for_delivery';
        final agentNote =
            (delivery.assignDeliveryTo != null &&
                    delivery.assignDeliveryTo!.isNotEmpty)
                ? ' • Agent: ${delivery.assignDeliveryTo}'
                : '';
        items.add(
          RfpTimelineItemTile(
            node: RfpTimelineNodes.activeHalo(),
            title: 'Week $w • $theme',
            trailingText: isOut ? 'Out for Delivery' : 'Scheduled: $dateStr',
            trailingTextColor: const Color(0xFF1E7E34),
            subtitle:
                (delivery.description ??
                    (isOut
                        ? 'Harvest out for delivery'
                        : 'Scheduled farm dispatch')) +
                agentNote,
            isLast: isLast,
          ),
        );
      } else {
        items.add(
          RfpTimelineItemTile(
            node: RfpTimelineNodes.future(),
            title: 'Week $w • $theme',
            trailingText: dateStr,
            trailingTextColor: const Color(0xFF718096),
            isFuture: true,
            isLast: isLast,
          ),
        );
      }
    }

    return Column(children: items);
  }

  int _calculateCurrentWeek() {
    final now = DateTime.now();
    final diffDays = now.difference(widget.booking.startDate).inDays;
    final w = (diffDays ~/ 7) + 1;
    if (w < 1) return 1;
    if (w > 12) return 12;
    return w;
  }
}
