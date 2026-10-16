import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/rfp_batch.dart';
import '../rfp_theme.dart';

/// Card widget representing an active or upcoming farming batch.
class RfpBatchCard extends StatelessWidget {
  final RfpBatch batch;
  final bool isSelected;
  final VoidCallback onTap;

  const RfpBatchCard({
    super.key,
    required this.batch,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd MMM');
    final progressFraction =
        batch.progressPercent > 1.0
            ? (batch.progressPercent / 100.0)
            : batch.progressPercent;
    final progressInt = (progressFraction * 100).toInt();

    if (batch.isActive) {
      final imgUrl =
          (batch.imageUrl != null && batch.imageUrl!.isNotEmpty)
              ? batch.imageUrl!
              : 'https://images.unsplash.com/photo-1500937386664-56d1dfef3854?auto=format&fit=crop&w=800&q=80';

      return GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(RfpTheme.radiusLg),
            boxShadow: RfpTheme.shadowMd,
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.network(
                  imgUrl,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (_, _, _) => Container(color: const Color(0xFF003629)),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF003629).withValues(alpha: 0.82),
                        const Color(0xFF0A261E).withValues(alpha: 0.94),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(RfpTheme.spaceMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: RfpTheme.spaceSm + 2,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color:
                                batch.isFull
                                    ? const Color(0xFFFFECEB)
                                    : const Color(0xFFC9EEA9),
                            borderRadius: BorderRadius.circular(
                              RfpTheme.radiusFull,
                            ),
                          ),
                          child: Text(
                            batch.isFull ? 'Batch Full' : 'My Active Plan',
                            style: RfpTheme.labelSm.copyWith(
                              color:
                                  batch.isFull
                                      ? const Color(0xFFB91C1C)
                                      : const Color(0xFF003629),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: RfpTheme.spaceSm),
                        Text(
                          '${df.format(batch.startDate)} - ${df.format(batch.endDate)}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                        const Spacer(),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle,
                            color: Color(0xFFC9EEA9),
                          ),
                      ],
                    ),
                    const SizedBox(height: RfpTheme.spaceSm + 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Batch #${batch.batchNumber}',
                              style: RfpTheme.headlineMd.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Week ${batch.currentWeek} of ${batch.totalWeeks} • ${batch.weeksRemaining} weeks remaining',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            SizedBox(
                              width: 96,
                              height: 8,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: progressFraction.clamp(0.0, 1.0),
                                  backgroundColor: Colors.white.withValues(
                                    alpha: 0.25,
                                  ),
                                  valueColor: const AlwaysStoppedAnimation(
                                    Color(0xFFC9EEA9),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$progressInt% Complete',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFC9EEA9),
                              ),
                            ),
                          ],
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

    // Upcoming batch card
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(RfpTheme.spaceMd),
        decoration: BoxDecoration(
          color: RfpTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(RfpTheme.radiusLg),
          border: Border.all(color: RfpTheme.outlineVariant),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: RfpTheme.spaceSm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: RfpTheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(
                            RfpTheme.radiusFull,
                          ),
                        ),
                        child: Text(
                          'Upcoming',
                          style: RfpTheme.labelSm.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: RfpTheme.spaceSm),
                      Text(
                        'Starts ${df.format(batch.startDate)}',
                        style: RfpTheme.labelSm.copyWith(
                          color: RfpTheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: RfpTheme.spaceSm),
                  Text(
                    'Batch #${batch.batchNumber}',
                    style: RfpTheme.headlineSm,
                  ),
                  Text(
                    '${batch.seasonLabel ?? ""} • Pre-booking open',
                    style: RfpTheme.bodySm.copyWith(
                      color: RfpTheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                if (isSelected)
                  const Icon(
                    Icons.radio_button_checked,
                    color: RfpTheme.primary,
                  )
                else
                  const Icon(Icons.radio_button_off, color: RfpTheme.outline),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
