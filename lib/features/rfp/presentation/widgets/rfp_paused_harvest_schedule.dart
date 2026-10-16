import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/rfp_delivery.dart';

/// Harvest Schedule timeline showing real delivery drops with [DONE], [PAUSED], and [Pending] items.
class RfpPausedHarvestSchedule extends StatelessWidget {
  final List<RfpDelivery> deliveries;

  const RfpPausedHarvestSchedule({super.key, this.deliveries = const []});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'Harvest Schedule',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 8, color: Color(0xFFC62828)),
                SizedBox(width: 4),
                Text(
                  'Action required',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFC62828),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (deliveries.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'No deliveries scheduled yet.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          )
        else
          ..._buildDeliveryCards(),
      ],
    );
  }

  List<Widget> _buildDeliveryCards() {
    final sorted = List<RfpDelivery>.from(deliveries)..sort((a, b) {
      final cmp = a.weekNumber.compareTo(b.weekNumber);
      return cmp != 0 ? cmp : a.date.compareTo(b.date);
    });

    final weekThemes = [
      'Early Harvest',
      'Brassica Box',
      'Orchard & Roots',
      'Winter Squash Special',
      'Cold-Frame Greens',
      'Root Cellar Special',
      'Heirloom Brassica Drop',
      'Dawn Crop Festival',
      'Wild Herb Forage Box',
      'Orchard & Hearth Cask',
      'Sun-Dried & Ferments',
      'Final Season Thali',
    ];

    final widgets = <Widget>[];
    bool hasFoundPaused = false;

    for (int i = 0; i < sorted.length; i++) {
      final d = sorted[i];
      final w = d.weekNumber;
      final theme = weekThemes[(w - 1).clamp(0, weekThemes.length - 1)];
      final dateStr = DateFormat('MMM d').format(d.date);
      final rawStatus = d.status.toLowerCase();

      final isDelivered = rawStatus == 'delivered';
      final isCancelled =
          rawStatus == 'cancelled' || rawStatus == 'not_delivered';
      final isPaused =
          rawStatus == 'paused' ||
          (!hasFoundPaused && !isDelivered && !isCancelled);

      if (isPaused) {
        hasFoundPaused = true;
      }

      if (isDelivered) {
        widgets.add(
          _buildScheduleCard(
            icon: _buildDoneCircle(),
            title: 'Week $w: $theme',
            badgeText: 'DONE',
            badgeBg: const Color(0xFFDCFCE7),
            badgeColor: const Color(0xFF15803D),
            subtitle:
                'Arrived $dateStr • ${d.totalWeight > 0 ? "${d.totalWeight.toStringAsFixed(1)} kg received" : "Basket received"}',
            trailingIcon: Icons.eco_outlined,
            trailingIconColor: const Color(0xFF15803D),
          ),
        );
      } else if (isCancelled) {
        widgets.add(
          _buildScheduleCard(
            icon: _buildPausedCircle(),
            title: 'Week $w: $theme',
            badgeText: 'CANCELLED',
            badgeBg: const Color(0xFFFFECEC),
            badgeColor: const Color(0xFFC62828),
            subtitle: d.cancellationReason ?? 'Delivery cancelled',
            trailingIcon: Icons.cancel_outlined,
            trailingIconColor: const Color(0xFFC62828),
          ),
        );
      } else if (isPaused) {
        widgets.add(
          _buildScheduleCard(
            icon: _buildPausedCircle(),
            title: 'Week $w: $theme',
            badgeText: 'PAUSED',
            badgeBg: const Color(0xFFFFCDD2),
            badgeColor: const Color(0xFFB71C1C),
            subtitle: 'Scheduled $dateStr • Awaiting clearance',
            trailingIcon: Icons.lock_outline,
            trailingIconColor: const Color(0xFFC62828),
            isPausedHighlight: true,
          ),
        );
      } else {
        widgets.add(
          _buildScheduleCard(
            icon: _buildPendingCircle(),
            title: 'Week $w: $theme',
            badgeText: 'Pending',
            badgeBg: const Color(0xFFF1F5F9),
            badgeColor: const Color(0xFF94A3B8),
            subtitle: 'Scheduled $dateStr • Locked',
            trailingIcon: Icons.lock_outline,
            trailingIconColor: const Color(0xFF94A3B8),
            isPendingLock: true,
          ),
        );
      }

      if (i < sorted.length - 1) {
        widgets.add(const SizedBox(height: 8));
      }
    }

    return widgets;
  }

  Widget _buildScheduleCard({
    required Widget icon,
    required String title,
    required String badgeText,
    required Color badgeBg,
    required Color badgeColor,
    required String subtitle,
    required IconData trailingIcon,
    required Color trailingIconColor,
    bool isPausedHighlight = false,
    bool isPendingLock = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color:
            isPausedHighlight
                ? const Color(0xFFFFF4F4)
                : (isPendingLock ? const Color(0xFFF8FAFC) : Colors.white),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isPausedHighlight
                  ? const Color(0xFFFFCDD2)
                  : const Color(0xFFE2E8F0),
          width: isPausedHighlight ? 1.2 : 0.8,
        ),
      ),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color:
                            isPendingLock
                                ? const Color(0xFF64748B)
                                : const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          color: badgeColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color:
                        isPausedHighlight
                            ? const Color(0xFFB71C1C)
                            : const Color(0xFF64748B),
                    fontWeight:
                        isPausedHighlight ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          Icon(trailingIcon, size: 16, color: trailingIconColor),
        ],
      ),
    );
  }

  Widget _buildDoneCircle() {
    return Container(
      width: 18,
      height: 18,
      decoration: const BoxDecoration(
        color: Color(0xFF166534),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.check, size: 12, color: Colors.white),
    );
  }

  Widget _buildPausedCircle() {
    return Container(
      width: 18,
      height: 18,
      decoration: const BoxDecoration(
        color: Color(0xFFB71C1C),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.pause, size: 12, color: Colors.white),
    );
  }

  Widget _buildPendingCircle() {
    return Container(
      width: 16,
      height: 16,
      decoration: const BoxDecoration(
        color: Color(0xFFCBD5E1),
        shape: BoxShape.circle,
      ),
    );
  }
}
