import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/rfp_plan.dart';
import '../cubit/rfp_batch_cubit.dart';
import '../rfp_theme.dart';
import 'rfp_plan_vegetable_card.dart';
import 'rfp_vegetable_dialog.dart';

/// Section showing available vegetables for a plan and handling selection/swaps.
class RfpPlanVegetableSelection extends StatelessWidget {
  final RfpPlan plan;
  final VoidCallback onSelectionChanged;

  const RfpPlanVegetableSelection({
    super.key,
    required this.plan,
    required this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RfpBatchCubit, RfpBatchState>(
      builder: (context, state) {
        final selectedCount = state.selectedVegetableIds.length;
        final limit = plan.selectionLimit;
        final isAtLimit = limit > 0 && selectedCount >= limit;
        final remainingDeselects = plan.getRemainingDeselects(
          state.selectedVegetableIds,
        );
        final isCuratedFixed = plan.isCuratedFixed;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('SELECT VEGETABLES', style: RfpTheme.headlineSm),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: RfpTheme.spaceSm,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isCuratedFixed
                                ? const Color(0xFFE2E8F0)
                                : (remainingDeselects > 0
                                    ? const Color(0xFFDCFCE7)
                                    : const Color(0xFFFFECEB)),
                        borderRadius: BorderRadius.circular(
                          RfpTheme.radiusFull,
                        ),
                      ),
                      child: Text(
                        isCuratedFixed
                            ? 'Fixed Curation'
                            : 'Swaps: $remainingDeselects/${plan.maxDeselectableCount}',
                        style: RfpTheme.labelSm.copyWith(
                          color:
                              isCuratedFixed
                                  ? const Color(0xFF475569)
                                  : (remainingDeselects > 0
                                      ? const Color(0xFF15803D)
                                      : const Color(0xFFB91C1C)),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: RfpTheme.spaceSm,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: RfpTheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(
                          RfpTheme.radiusFull,
                        ),
                      ),
                      child: Text(
                        limit > 0
                            ? 'Selected: $selectedCount / $limit'
                            : 'Selected: $selectedCount',
                        style: RfpTheme.labelMd.copyWith(
                          color: RfpTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: RfpTheme.spaceSm),
            Text(
              isCuratedFixed
                  ? 'Expertly curated seasonal harvest from the dawn harvest cycle.'
                  : 'Default curated vegetables with up to ${plan.maxDeselectableCount} customizable swaps.',
              style: RfpTheme.bodyMd.copyWith(color: RfpTheme.onSurfaceVariant),
            ),
            if (state.deselectionWarning != null) ...[
              const SizedBox(height: RfpTheme.spaceSm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: RfpTheme.spaceMd,
                  vertical: RfpTheme.spaceSm,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFECEB),
                  borderRadius: BorderRadius.circular(RfpTheme.radiusMd),
                  border: Border.all(color: const Color(0xFFFFCDD2)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Color(0xFFC62828),
                      size: 16,
                    ),
                    const SizedBox(width: RfpTheme.spaceSm),
                    Expanded(
                      child: Text(
                        state.deselectionWarning!,
                        style: RfpTheme.bodySm.copyWith(
                          color: const Color(0xFFC62828),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap:
                          () =>
                              context
                                  .read<RfpBatchCubit>()
                                  .clearDeselectionWarning(),
                      child: const Icon(
                        Icons.close,
                        color: Color(0xFFC62828),
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (isAtLimit) ...[
              const SizedBox(height: RfpTheme.spaceSm),
              Text(
                'Maximum selection reached. Tap a selected item to swap.',
                style: RfpTheme.bodySm.copyWith(color: RfpTheme.secondary),
              ),
            ],
            const SizedBox(height: RfpTheme.spaceMd),
            if (plan.availableVegetables.isEmpty)
              Container(
                padding: const EdgeInsets.all(RfpTheme.spaceMd),
                decoration: BoxDecoration(
                  color: RfpTheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(RfpTheme.radiusMd),
                  border: Border.all(color: RfpTheme.outlineVariant),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: RfpTheme.secondary),
                    const SizedBox(width: RfpTheme.spaceSm),
                    Expanded(
                      child: Text(
                        'This plan includes standard farm curation. No vegetable selection needed.',
                        style: RfpTheme.bodyMd.copyWith(
                          color: RfpTheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: RfpTheme.spaceSm,
                  mainAxisSpacing: RfpTheme.spaceSm,
                  childAspectRatio: 0.84,
                ),
                itemCount: plan.availableVegetables.length,
                itemBuilder: (context, index) {
                  final veg = plan.availableVegetables[index];
                  final isSelected = state.selectedVegetableIds.contains(
                    veg.id,
                  );
                  final canDeselect =
                      isSelected
                          ? plan.canDeselectVegetable(
                            veg.id,
                            state.selectedVegetableIds,
                          )
                          : true;
                  final isDefault =
                      veg.isDefaultSelected ||
                      plan.defaultVegetableIds.contains(veg.id);

                  return RfpPlanVegetableCard(
                    vegetable: veg,
                    isSelected: isSelected,
                    canDeselect: canDeselect,
                    isDefault: isDefault,
                    isAtLimit: isAtLimit,
                    onTap: () {
                      if (isSelected) {
                        if (!canDeselect) {
                          RfpVegetableDialog.showSwapLimitReached(
                            context,
                            planName: plan.name,
                            maxSwaps: plan.maxDeselectableCount,
                            isCuratedFixed: isCuratedFixed,
                          );
                          return;
                        }
                        context.read<RfpBatchCubit>().toggleVegetable(veg.id);
                        onSelectionChanged();
                      } else {
                        if (isAtLimit) {
                          RfpVegetableDialog.showSelectionLimitReached(
                            context,
                            planName: plan.name,
                            limit: limit,
                            vegetableName: veg.name,
                          );
                          return;
                        }
                        context.read<RfpBatchCubit>().toggleVegetable(veg.id);
                        onSelectionChanged();
                      }
                    },
                  );
                },
              ),
          ],
        );
      },
    );
  }
}
