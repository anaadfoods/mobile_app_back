import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/rfp_batch.dart';
import '../../domain/entities/rfp_batch_group.dart';
import '../cubit/rfp_batch_cubit.dart';
import '../rfp_theme.dart';

/// Information cards and status badges for the selected RFP batch.
class RfpBatchInfoSection extends StatelessWidget {
  final RfpBatch batch;
  final RfpBatchState state;

  const RfpBatchInfoSection({
    super.key,
    required this.batch,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (batch.imageUrl != null && batch.imageUrl!.isNotEmpty) ...[
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              batch.imageUrl!,
              width: double.infinity,
              height: 180,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        ],
        const SizedBox(height: 16),
        _buildCapacitySection(batch),
        if (batch.groups.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildGroupsInfo(batch.groups),
        ],
        if (batch.isFull) ...[
          const SizedBox(height: 16),
          _buildBatchFullBanner(),
        ],
        if (batch.bookingStartDate != null && batch.bookingEndDate != null) ...[
          const SizedBox(height: 12),
          _buildBookingWindowInfo(batch),
        ],
        if (state.batches.length > 1) ...[
          const SizedBox(height: 20),
          _buildBatchPicker(context, state),
        ],
      ],
    );
  }

  Widget _buildCapacitySection(RfpBatch batch) {
    final slots = batch.slotsRemaining;
    final hasSlotInfo = slots != null && slots > 0;
    final isFull = batch.isFull;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: (isFull
                      ? const Color(0xFFFF9776)
                      : const Color(0xFFC9EEA9))
                  .withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isFull ? Icons.group_off_rounded : Icons.groups_rounded,
              size: 16,
              color: isFull ? const Color(0xFFFF9776) : const Color(0xFFC9EEA9),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isFull
                      ? 'BATCH FULL'
                      : hasSlotInfo
                      ? '$slots FAMILY ${slots == 1 ? "SLOT" : "SLOTS"} REMAINING'
                      : 'OPEN FOR BOOKING',
                  style: RfpTheme.labelSm.copyWith(
                    color:
                        isFull
                            ? const Color(0xFFFF9776)
                            : const Color(0xFFC9EEA9),
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (batch.status.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Status: ${batch.status.toUpperCase()}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupsInfo(List<RfpBatchGroup> groups) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CAPACITY GROUPS',
            style: RfpTheme.labelSm.copyWith(
              color: Colors.white.withValues(alpha: 0.5),
              letterSpacing: 1.0,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...groups.map(
            (group) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          group.isFull
                              ? const Color(0xFFFF9776)
                              : const Color(0xFFC9EEA9),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      group.name,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    group.isFull
                        ? 'Full'
                        : '${group.slotsRemaining} slots left',
                    style: TextStyle(
                      color:
                          group.isFull
                              ? const Color(0xFFFF9776)
                              : const Color(0xFFC9EEA9),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatchFullBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFF9776).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFF9776).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFFF9776).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              size: 16,
              color: Color(0xFFFF9776),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This batch is fully booked',
                  style: TextStyle(
                    color: Color(0xFFFF9776),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'All available slots have been claimed. Check back for upcoming seasons.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingWindowInfo(RfpBatch batch) {
    final df = DateFormat('d MMM yyyy');
    final bookingStart = df.format(batch.bookingStartDate!);
    final bookingEnd = df.format(batch.bookingEndDate!);
    final now = DateTime.now();
    final isBookingOpen =
        now.isAfter(batch.bookingStartDate!) &&
        now.isBefore(batch.bookingEndDate!);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isBookingOpen ? Icons.lock_open_rounded : Icons.schedule_rounded,
            size: 16,
            color:
                isBookingOpen
                    ? const Color(0xFFC9EEA9)
                    : Colors.white.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isBookingOpen
                  ? 'Booking open until $bookingEnd'
                  : 'Booking window: $bookingStart — $bookingEnd',
              style: TextStyle(
                color:
                    isBookingOpen
                        ? const Color(0xFFC9EEA9).withValues(alpha: 0.9)
                        : Colors.white.withValues(alpha: 0.55),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatchPicker(BuildContext context, RfpBatchState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AVAILABLE BATCHES',
          style: RfpTheme.labelSm.copyWith(
            color: Colors.white.withValues(alpha: 0.5),
            letterSpacing: 1.0,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 64,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: state.batches.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final b = state.batches[index];
              final isSelected = b.id == state.selectedBatch?.id;
              final df = DateFormat('MMM');
              final label =
                  b.seasonLabel ??
                  '${df.format(b.startDate)}–${df.format(b.endDate)}';

              return GestureDetector(
                onTap: () => context.read<RfpBatchCubit>().selectBatch(b),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? const Color(0xFFC9EEA9).withValues(alpha: 0.15)
                            : Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          isSelected
                              ? const Color(0xFFC9EEA9).withValues(alpha: 0.5)
                              : Colors.white.withValues(alpha: 0.1),
                      width: isSelected ? 1.5 : 0.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color:
                              isSelected
                                  ? const Color(0xFFC9EEA9)
                                  : Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        b.isFull
                            ? 'Full'
                            : b.slotsRemaining != null
                            ? '${b.slotsRemaining} slots'
                            : b.status.toUpperCase(),
                        style: TextStyle(
                          color:
                              b.isFull
                                  ? const Color(
                                    0xFFFF9776,
                                  ).withValues(alpha: 0.7)
                                  : Colors.white.withValues(alpha: 0.45),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
