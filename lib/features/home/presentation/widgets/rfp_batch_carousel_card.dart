import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:grocery_app/features/rfp/domain/entities/rfp_batch.dart';
import 'package:grocery_app/features/rfp/domain/entities/rfp_plan.dart';
import 'package:grocery_app/features/rfp/presentation/cubit/rfp_batch_cubit.dart';

/// Single carousel card for a farming batch on the Home Screen.
class RfpBatchCarouselCard extends StatelessWidget {
  final RfpBatch batch;
  final bool isActive;
  final bool isDark;

  const RfpBatchCarouselCard({
    super.key,
    required this.batch,
    required this.isActive,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd MMM');
    final dateRange =
        '${df.format(batch.startDate)} - ${df.format(batch.endDate)}';

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.read<RfpBatchCubit>().selectBatch(batch);
        context.push('/rfp/batches');
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors:
                isActive
                    ? const [
                      Color(0xFF003629),
                      Color(0xFF134233),
                      Color(0xFF0A261E),
                    ]
                    : const [Color(0xFF1E3A2F), Color(0xFF142B22)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(
                0xFF003629,
              ).withValues(alpha: isActive ? 0.45 : 0.20),
              blurRadius: isActive ? 28 : 14,
              offset: const Offset(0, 8),
              spreadRadius: isActive ? 2 : 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              if (batch.imageUrl != null && batch.imageUrl!.isNotEmpty) ...[
                Positioned.fill(
                  child: Image.network(
                    batch.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF003629).withValues(alpha: 0.85),
                          const Color(0xFF0A261E).withValues(alpha: 0.95),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row with badge and eco icon
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  _buildStatusBadge(batch),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.14,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.25,
                                        ),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Text(
                                      'BATCH #${batch.batchNumber} • ${batch.totalWeeks} WEEKS',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                (batch.seasonLabel ??
                                        'Harvest Batch #${batch.batchNumber}')
                                    .toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  letterSpacing: 0.4,
                                  height: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withValues(alpha: 0.25),
                                Colors.white.withValues(alpha: 0.10),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1.2,
                            ),
                          ),
                          child: const Icon(
                            Icons.eco_rounded,
                            color: Color(0xFFC9EEA9),
                            size: 24,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 2,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 13,
                              color: Colors.white.withValues(alpha: 0.75),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              dateRange,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        if (batch.slotsRemaining != null && !batch.isFull)
                          Text(
                            '• ${batch.slotsRemaining} SLOTS LEFT',
                            style: const TextStyle(
                              color: Color(0xFFC9EEA9),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),

                    const Spacer(),

                    // Thalis / Plans Bullet Points Panel
                    Builder(
                      builder: (context) {
                        List<RfpPlan> plans = batch.plans;
                        if (plans.isEmpty) {
                          try {
                            final cubit = context.read<RfpBatchCubit>();
                            if (cubit.state.selectedBatch?.id == batch.id &&
                                cubit.state.plans.isNotEmpty) {
                              plans = cubit.state.plans;
                            }
                          } catch (_) {}
                        }
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.18),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'SEASONAL THALIS',
                                      style: TextStyle(
                                        color: Color(0xFFC9EEA9),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.8,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '${batch.totalWeeks} WEEKS',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.6,
                                      ),
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              if (plans.isNotEmpty)
                                ...plans
                                    .take(3)
                                    .map(
                                      (plan) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 2.5,
                                        ),
                                        child: Row(
                                          children: [
                                            const Text(
                                              '• ',
                                              style: TextStyle(
                                                color: Color(0xFFC9EEA9),
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                plan.name,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Text(
                                              plan.isFull
                                                  ? 'FULL'
                                                  : '${plan.slotsRemaining} slots',
                                              style: TextStyle(
                                                color:
                                                    plan.isFull
                                                        ? const Color(
                                                          0xFFFF9776,
                                                        )
                                                        : const Color(
                                                          0xFFC9EEA9,
                                                        ),
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                              else
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 2.5),
                                  child: Row(
                                    children: [
                                      Text(
                                        '• ',
                                        style: TextStyle(
                                          color: Color(0xFFC9EEA9),
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          'Curated Seasonal Harvest Thali',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    // CTA Button
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC9EEA9),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFC9EEA9,
                            ).withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              'Explore Batch & Plans',
                              style: TextStyle(
                                color: Color(0xFF003629),
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                letterSpacing: 0.3,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: Color(0xFF003629),
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(RfpBatch batch) {
    Color bg;
    Color textColor;
    Color dotColor;
    String label;

    if (batch.isFull) {
      bg = const Color(0xFFFFDAD6);
      textColor = const Color(0xFFBA1A1A);
      dotColor = const Color(0xFFBA1A1A);
      label = 'BATCH FULL';
    } else if (batch.isActive) {
      bg = const Color(0xFFC9EEA9);
      textColor = const Color(0xFF003629);
      dotColor = const Color(0xFF1B5E20);
      label = 'ACTIVE';
    } else if (batch.isUpcoming) {
      bg = const Color(0xFFFFE082);
      textColor = const Color(0xFF5D4037);
      dotColor = const Color(0xFFE65100);
      label = 'UPCOMING';
    } else {
      bg = Colors.white.withValues(alpha: 0.2);
      textColor = Colors.white;
      dotColor = Colors.white70;
      label = batch.status.isNotEmpty ? batch.status.toUpperCase() : 'ACTIVE';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}
