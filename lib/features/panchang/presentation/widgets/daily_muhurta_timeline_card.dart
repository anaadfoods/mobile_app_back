import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:grocery_app/models/panchang/panchang_day_models.dart';

enum TimelineEventType { auspicious, inauspicious, neutral, solar }

class TimelineEventItem {
  final String title;
  final String category;
  final DateTime time;
  final DateTime? endTime;
  final TimelineEventType type;
  final IconData icon;
  final String note;

  const TimelineEventItem({
    required this.title,
    required this.category,
    required this.time,
    this.endTime,
    required this.type,
    required this.icon,
    required this.note,
  });
}

/// Interactive Chronological Daily Timeline Component
class DailyMuhurtaTimelineCard extends StatefulWidget {
  final PanchangDayResponse day;
  final bool isDark;

  const DailyMuhurtaTimelineCard({
    super.key,
    required this.day,
    required this.isDark,
  });

  @override
  State<DailyMuhurtaTimelineCard> createState() => _DailyMuhurtaTimelineCardState();
}

class _DailyMuhurtaTimelineCardState extends State<DailyMuhurtaTimelineCard> {
  int? _selectedEventIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final events = _extractEvents(widget.day);
    if (events.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.darkSurface : AppColors.pureWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (widget.isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: widget.isDark ? 0.2 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (widget.isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.timeline_rounded,
                  size: 20,
                  color: widget.isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Muhurta Timeline',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      'Chronological solar & traditional auspicious windows',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: events.length,
            separatorBuilder: (context, index) => const SizedBox(height: 0),
            itemBuilder: (context, index) => _buildTimelineNode(
              context,
              events[index],
              index == events.length - 1,
              _selectedEventIndex == index,
              index,
            ),
          ),
        ],
      ),
    );
  }

  List<TimelineEventItem> _extractEvents(PanchangDayResponse day) {
    final list = <TimelineEventItem>[];
    final timings = day.sunMoonTimings;
    final aus = day.auspiciousMuhurats;
    final inaus = day.inauspiciousTimings;

    if (aus?.brahma?.start != null) {
      list.add(TimelineEventItem(
        title: 'Brahma Muhurta',
        category: 'Auspicious Creation Window',
        time: aus!.brahma!.start!.toLocal(),
        endTime: aus.brahma!.end?.toLocal(),
        type: TimelineEventType.auspicious,
        icon: Icons.self_improvement_rounded,
        note: 'Ideal for meditation, yoga, spiritual contemplation, and planning the day.',
      ));
    }
    if (timings.sunrise != null) {
      list.add(TimelineEventItem(
        title: 'Sunrise (Surya Udaya)',
        category: 'Solar Anchor',
        time: timings.sunrise!.toLocal(),
        type: TimelineEventType.solar,
        icon: Icons.wb_sunny_rounded,
        note: 'The start of the Vedic day and dynamic prana awakening.',
      ));
    }
    if (inaus?.yamaganda?.start != null) {
      list.add(TimelineEventItem(
        title: 'Yamaganda Kalam',
        category: 'Inauspicious Window',
        time: inaus!.yamaganda!.start!.toLocal(),
        endTime: inaus.yamaganda!.end?.toLocal(),
        type: TimelineEventType.inauspicious,
        icon: Icons.warning_amber_rounded,
        note: 'Traditional recommendation: Avoid initiating vital business agreements.',
      ));
    }
    if (aus?.abhijit?.start != null) {
      list.add(TimelineEventItem(
        title: 'Abhijit Muhurta',
        category: 'High Auspicious Window',
        time: aus!.abhijit!.start!.toLocal(),
        endTime: aus.abhijit!.end?.toLocal(),
        type: TimelineEventType.auspicious,
        icon: Icons.verified_rounded,
        note: 'Most powerful auspicious window of the day; overcomes most doshas.',
      ));
    }
    if (timings.solarNoon != null) {
      list.add(TimelineEventItem(
        title: 'Solar Noon (Madhyahna)',
        category: 'Solar Anchor',
        time: timings.solarNoon!.toLocal(),
        type: TimelineEventType.solar,
        icon: Icons.wb_sunny,
        note: 'Peak solar energy and strongest digestive fire (Jatharagni) for principal meal.',
      ));
    }
    if (inaus?.gulika?.start != null) {
      list.add(TimelineEventItem(
        title: 'Gulika Kalam',
        category: 'Neutral / Saturnian Window',
        time: inaus!.gulika!.start!.toLocal(),
        endTime: inaus.gulika!.end?.toLocal(),
        type: TimelineEventType.neutral,
        icon: Icons.schedule_rounded,
        note: 'Actions started in Gulika tend to repeat; suitable for repetitive tasks.',
      ));
    }
    if (inaus?.rahuKaal?.start != null) {
      list.add(TimelineEventItem(
        title: 'Rahu Kalam',
        category: 'Inauspicious Window',
        time: inaus!.rahuKaal!.start!.toLocal(),
        endTime: inaus.rahuKaal!.end?.toLocal(),
        type: TimelineEventType.inauspicious,
        icon: Icons.block_rounded,
        note: 'Traditional recommendation: Avoid auspicious beginnings, major purchases, or journeys.',
      ));
    }
    if (timings.sunset != null) {
      list.add(TimelineEventItem(
        title: 'Sunset (Surya Astamaya)',
        category: 'Solar Anchor',
        time: timings.sunset!.toLocal(),
        type: TimelineEventType.solar,
        icon: Icons.nights_stay_rounded,
        note: 'Sandhya transition into night; favor light foods and quiet reflection.',
      ));
    }
    list.sort((a, b) => a.time.compareTo(b.time));
    return list;
  }

  Widget _buildTimelineNode(
    BuildContext context,
    TimelineEventItem event,
    bool isLast,
    bool isSelected,
    int index,
  ) {
    final theme = Theme.of(context);
    final color = _getColor(event.type);
    final timeStr = _formatTime(event.time);
    final endStr = event.endTime != null ? ' - ${_formatTime(event.endTime!)}' : '';

    return InkWell(
      onTap: () => setState(() => _selectedEventIndex = isSelected ? null : index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 65,
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  timeStr,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ),
            Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                  ),
                  child: Icon(event.icon, size: 12, color: color),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: isSelected ? 80 : 36,
                    color: (widget.isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.1),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            event.title,
                            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        _buildTypeBadge(event.type),
                      ],
                    ),
                    if (endStr.isNotEmpty)
                      Text(
                        '$timeStr$endStr',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                        ),
                      ),
                    if (isSelected) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: color.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          event.note,
                          style: theme.textTheme.bodySmall?.copyWith(fontSize: 12, height: 1.3),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColor(TimelineEventType type) {
    switch (type) {
      case TimelineEventType.auspicious:
        return AppColors.successGreen;
      case TimelineEventType.inauspicious:
        return AppColors.softRed;
      case TimelineEventType.solar:
        return AppColors.harvestAmber;
      case TimelineEventType.neutral:
        return AppColors.rawEarth;
    }
  }

  Widget _buildTypeBadge(TimelineEventType type) {
    final (label, color) = switch (type) {
      TimelineEventType.auspicious => ('Auspicious', AppColors.successGreen),
      TimelineEventType.inauspicious => ('Avoid', AppColors.softRed),
      TimelineEventType.solar => ('Solar', AppColors.harvestAmber),
      TimelineEventType.neutral => ('Neutral', AppColors.rawEarth),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
