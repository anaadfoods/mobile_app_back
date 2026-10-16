import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:grocery_app/features/rfp/presentation/cubit/rfp_batch_cubit.dart';
import 'package:grocery_app/features/rfp/domain/entities/rfp_batch.dart';

/// Dynamic RFP Batch Showcase on the Home Screen.
///
/// Observes [RfpBatchCubit] and displays active/upcoming batches
/// with their name, dates, slots, and status. Tapping a batch
/// selects it and navigates to the Batch Builder Storefront.
class RfpHomeBanner extends StatefulWidget {
  const RfpHomeBanner({super.key});

  @override
  State<RfpHomeBanner> createState() => _RfpHomeBannerState();
}

class _RfpHomeBannerState extends State<RfpHomeBanner> {
  @override
  void initState() {
    super.initState();
    // Trigger batch loading if not already loaded
    final cubit = context.read<RfpBatchCubit>();
    if (cubit.state.batches.isEmpty && !cubit.state.isLoading) {
      cubit.loadBatchData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RfpBatchCubit, RfpBatchState>(
      builder: (context, state) {
        if (state.isLoading && state.batches.isEmpty) {
          return _buildLoadingBanner();
        }
        if (state.batches.isEmpty) {
          return _buildStaticBanner(context);
        }
        return _buildDynamicBanner(context, state);
      },
    );
  }

  Widget _buildLoadingBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      height: 160,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF003629), Color(0xFF1B4D3E), Color(0xFF0A261E)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: Color(0xFF8ABDA9)),
      ),
    );
  }

  Widget _buildStaticBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF003629), Color(0xFF1B4D3E), Color(0xFF0A261E)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF003629).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/rfp'),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRfpTagRow(null),
                const SizedBox(height: 14),
                const Text(
                  'Book Your Personal\nFarming Patch',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select organic vegetables, track 12-week farm growth.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                _buildExploreButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicBanner(BuildContext context, RfpBatchState state) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF003629), Color(0xFF1B4D3E), Color(0xFF0A261E)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF003629).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRfpTagRow(_getActiveBatch(state)),
            const SizedBox(height: 14),
            const Text(
              'Book Your Personal\nFarming Patch',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            _buildBatchCards(context, state),
            const SizedBox(height: 14),
            _buildExploreButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBatchCards(BuildContext context, RfpBatchState state) {
    // Show up to 2 batches as compact cards
    final displayBatches = state.batches.take(2).toList();
    return Column(
      children:
          displayBatches.map((batch) {
            return _buildBatchMiniCard(context, batch, state);
          }).toList(),
    );
  }

  Widget _buildBatchMiniCard(
    BuildContext context,
    RfpBatch batch,
    RfpBatchState state,
  ) {
    final isSelected = state.selectedBatch?.id == batch.id;
    final dateFormat = DateFormat('dd MMM');
    final dateRange =
        '${dateFormat.format(batch.startDate)} - ${dateFormat.format(batch.endDate)}';

    return GestureDetector(
      onTap: () {
        context.read<RfpBatchCubit>().selectBatch(batch);
        context.push('/rfp/batches');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border:
              isSelected
                  ? Border.all(
                    color: const Color(0xFF8ABDA9).withValues(alpha: 0.6),
                    width: 1,
                  )
                  : null,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF8ABDA9).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.eco, size: 18, color: Color(0xFF8ABDA9)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    batch.seasonLabel ?? 'Batch #${batch.batchNumber}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    dateRange,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            _buildStatusBadge(batch),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(RfpBatch batch) {
    String label;
    Color bgColor;
    Color textColor;

    if (batch.isFull) {
      label = 'Batch Full';
      bgColor = const Color(0xFFFFDAD6);
      textColor = const Color(0xFFBA1A1A);
    } else if (batch.isActive) {
      label = 'ACTIVE • ${batch.slotsRemaining ?? 50} slots';
      bgColor = const Color(0xFFC9EEA9);
      textColor = const Color(0xFF003629);
    } else if (batch.isUpcoming) {
      label = 'UPCOMING';
      bgColor = const Color(0xFFFFE082);
      textColor = const Color(0xFF5D4037);
    } else {
      label = batch.status.isNotEmpty ? batch.status.toUpperCase() : 'ACTIVE';
      bgColor = const Color(0xFFBAEED9);
      textColor = const Color(0xFF002117);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildRfpTagRow(RfpBatch? activeBatch) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF8ABDA9).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF8ABDA9).withValues(alpha: 0.4),
              width: 0.8,
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.eco, size: 14, color: Color(0xFF8ABDA9)),
              SizedBox(width: 5),
              Text(
                'REMOTE FARMING PLAN',
                style: TextStyle(
                  color: Color(0xFF8ABDA9),
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        if (activeBatch != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFC9EEA9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              activeBatch.isFull
                  ? 'Batch Full'
                  : 'Batch #${activeBatch.batchNumber} Open',
              style: const TextStyle(
                color: Color(0xFF2E4817),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildExploreButton(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/rfp/batches'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFC9EEA9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Explore Patches & Plans',
              style: TextStyle(
                color: Color(0xFF1B4D3E),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(width: 6),
            Icon(
              Icons.arrow_forward_rounded,
              size: 16,
              color: Color(0xFF1B4D3E),
            ),
          ],
        ),
      ),
    );
  }

  RfpBatch? _getActiveBatch(RfpBatchState state) {
    final active = state.batches.where((b) => b.isActive);
    return active.isNotEmpty ? active.first : state.batches.firstOrNull;
  }
}
