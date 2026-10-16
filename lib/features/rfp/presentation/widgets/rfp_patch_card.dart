import 'package:flutter/material.dart';
import '../../domain/entities/rfp_patch.dart';
import '../rfp_theme.dart';

/// Farm Patch card widget for RFP patch selection with weight chips and price.
class RfpPatchCard extends StatelessWidget {
  final RfpPatch patch;
  final bool isSelected;
  final double? selectedWeight;
  final VoidCallback onTap;

  const RfpPatchCard({
    super.key,
    required this.patch,
    required this.isSelected,
    this.selectedWeight,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(RfpTheme.spaceMd),
        decoration: BoxDecoration(
          color: RfpTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(RfpTheme.radiusLg),
          border: Border.all(
            color: isSelected ? RfpTheme.primary : RfpTheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(RfpTheme.radiusMd),
                    color: RfpTheme.surfaceContainerHigh,
                  ),
                  child: Icon(
                    Icons.grass,
                    color: RfpTheme.primary.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(width: RfpTheme.spaceMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Patch ${patch.label}',
                            style: RfpTheme.headlineSm.copyWith(fontSize: 16),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: RfpTheme.spaceSm),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: RfpTheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(
                                  RfpTheme.radiusFull,
                                ),
                              ),
                              child: Text(
                                'Selected',
                                style: RfpTheme.labelSm.copyWith(
                                  color: RfpTheme.onSecondaryContainer,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        '${patch.vegetableCount} Vegetables Variety',
                        style: RfpTheme.bodySm.copyWith(
                          color: RfpTheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: RfpTheme.primary,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: RfpTheme.onPrimary,
                      size: 18,
                    ),
                  )
                else
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: RfpTheme.outlineVariant,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.add,
                      color: RfpTheme.outline,
                      size: 18,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: RfpTheme.spaceSm),
            Row(
              children: [
                ...patch.availableWeights.map((w) {
                  final isWeightSelected = selectedWeight == w;
                  return Padding(
                    padding: const EdgeInsets.only(right: RfpTheme.spaceXs),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isWeightSelected
                                ? RfpTheme.primaryContainer
                                : RfpTheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(
                          RfpTheme.radiusFull,
                        ),
                      ),
                      child: Text(
                        '${w == w.toInt() ? w.toInt().toString() : w.toString()} KG',
                        style: RfpTheme.labelSm.copyWith(
                          color:
                              isWeightSelected
                                  ? RfpTheme.onPrimaryContainer
                                  : RfpTheme.onSurface,
                        ),
                      ),
                    ),
                  );
                }),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Starting',
                      style: RfpTheme.labelSm.copyWith(
                        color: RfpTheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '₹${patch.startingPrice.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                      style: RfpTheme.headlineSm.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
