// lib/features/panchang/presentation/widgets/kundli/kundli_dasha_timeline.dart
import 'package:flutter/material.dart';
import '../../../domain/entities/kundli_entities.dart';

class KundliDashaTimeline extends StatelessWidget {
  final List<DashaPeriod> timeline;
  final DashaPeriod? activeDasha;

  const KundliDashaTimeline({
    super.key,
    required this.timeline,
    this.activeDasha,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: const Color(0xFFE5DECC)),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.timeline_rounded, color: Color(0xFF2E6B34), size: 20),
                const SizedBox(width: 8),
                Text(
                  'Vimshottari Dasha Periods',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1B2E1D),
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (activeDasha != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF7EE),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD4AF37)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Color(0xFFD4AF37), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Currently Active: ${activeDasha!.lord} Mahadasha (${activeDasha!.startDate} to ${activeDasha!.endDate})',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B2E1D),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: timeline.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF0EBE1)),
              itemBuilder: (context, index) {
                final d = timeline[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: d.isActive ? const Color(0xFF2E6B34) : Colors.grey.shade400,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${d.lord} Mahadasha',
                          style: TextStyle(
                            fontWeight: d.isActive ? FontWeight.bold : FontWeight.w500,
                            color: d.isActive ? const Color(0xFF2E6B34) : const Color(0xFF2C3E50),
                          ),
                        ),
                      ),
                      Text(
                        '${d.startDate} - ${d.endDate}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
