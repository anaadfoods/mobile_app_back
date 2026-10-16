import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../cubit/rfp_batch_cubit.dart';
import '../rfp_theme.dart';

/// Subscription plan summary card shown in Checkout.
class RfpSubscriptionSummary extends StatelessWidget {
  final RfpBatchState batchState;

  const RfpSubscriptionSummary({super.key, required this.batchState});

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd MMM');
    return Container(
      padding: const EdgeInsets.all(RfpTheme.spaceLg),
      decoration: BoxDecoration(
        color: RfpTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(RfpTheme.radiusLg),
        boxShadow: RfpTheme.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SUBSCRIPTION PLAN',
                    style: RfpTheme.labelSm.copyWith(
                      color: RfpTheme.onSurfaceVariant,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Batch #${batchState.selectedBatch?.batchNumber ?? ""}',
                    style: RfpTheme.headlineSm,
                  ),
                ],
              ),
              if (batchState.selectedBatch != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: RfpTheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(RfpTheme.radiusFull),
                  ),
                  child: Text(
                    '${df.format(batchState.selectedBatch!.startDate)} - ${df.format(batchState.selectedBatch!.endDate)}',
                    style: RfpTheme.labelSm.copyWith(
                      color: RfpTheme.onSecondaryContainer,
                    ),
                  ),
                ),
            ],
          ),
          if (batchState.selectedPlan != null) ...[
            const SizedBox(height: RfpTheme.spaceMd),
            Container(
              padding: const EdgeInsets.all(RfpTheme.spaceMd),
              decoration: BoxDecoration(
                color: RfpTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(RfpTheme.radiusMd),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: RfpTheme.primaryContainer,
                    ),
                    child: const Icon(
                      Icons.spa,
                      color: RfpTheme.onPrimaryContainer,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: RfpTheme.spaceMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          batchState.selectedPlan!.name,
                          style: RfpTheme.bodyMd.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          batchState.selectedPlan!.description,
                          style: RfpTheme.bodySm.copyWith(
                            color: RfpTheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '₹${batchState.selectedPlan!.totalPrice.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                    style: RfpTheme.headlineSm.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (batchState.selectedPatchIds.isNotEmpty) ...[
            const SizedBox(height: RfpTheme.spaceMd),
            Wrap(
              spacing: RfpTheme.spaceSm,
              runSpacing: RfpTheme.spaceSm,
              children:
                  batchState.selectedPatches.map((patch) {
                    final config = batchState.patchConfigs[patch.id];
                    return Container(
                      padding: const EdgeInsets.all(RfpTheme.spaceSm),
                      decoration: BoxDecoration(
                        color: RfpTheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(RfpTheme.radiusMd),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Patch ${patch.label}',
                                style: RfpTheme.labelMd.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: RfpTheme.secondaryContainer,
                                  borderRadius: BorderRadius.circular(
                                    RfpTheme.radiusFull,
                                  ),
                                ),
                                child: Text(
                                  'Active',
                                  style: RfpTheme.labelSm.copyWith(
                                    fontSize: 9,
                                    color: RfpTheme.onSecondaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (config != null) ...[
                            Text(
                              '${config.selectedWeight} KG •',
                              style: RfpTheme.labelSm.copyWith(
                                color: RfpTheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              config.deliveryFrequency == 'twice_a_week'
                                  ? 'Twice/week'
                                  : 'Once/week',
                              style: RfpTheme.labelSm.copyWith(
                                color: RfpTheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              '${config.exclusionCount} exclusion${config.exclusionCount != 1 ? "s" : ""} applied',
                              style: RfpTheme.labelSm.copyWith(
                                color: RfpTheme.secondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
