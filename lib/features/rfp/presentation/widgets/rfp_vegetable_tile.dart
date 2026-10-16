import 'package:flutter/material.dart';
import '../../domain/entities/rfp_vegetable.dart';
import '../rfp_theme.dart';

/// Interactive vegetable item tile in Patch Configuration screen.
class RfpVegetableTile extends StatelessWidget {
  final RfpVegetable vegetable;
  final bool isExcluded;
  final VoidCallback onToggle;

  const RfpVegetableTile({
    super.key,
    required this.vegetable,
    required this.isExcluded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: RfpTheme.spaceMd,
        vertical: RfpTheme.spaceSm + 2,
      ),
      decoration: BoxDecoration(
        color:
            isExcluded
                ? RfpTheme.errorContainer.withValues(alpha: 0.3)
                : RfpTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(RfpTheme.radiusLg),
        border: Border.all(
          color:
              isExcluded
                  ? RfpTheme.error.withValues(alpha: 0.3)
                  : RfpTheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Vegetable icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  isExcluded
                      ? RfpTheme.error.withValues(alpha: 0.1)
                      : RfpTheme.surfaceContainerHigh,
            ),
            child: Icon(
              isExcluded ? Icons.close : Icons.spa,
              size: 20,
              color: isExcluded ? RfpTheme.error : RfpTheme.primary,
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
                      vegetable.name,
                      style: RfpTheme.bodyMd.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (isExcluded) ...[
                      const SizedBox(width: RfpTheme.spaceSm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: RfpTheme.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            RfpTheme.radiusFull,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.close,
                              size: 12,
                              color: RfpTheme.error,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              'Excluded',
                              style: RfpTheme.labelSm.copyWith(
                                color: RfpTheme.error,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  vegetable.description,
                  style: RfpTheme.bodySm.copyWith(
                    color: RfpTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // Checkbox
          GestureDetector(
            onTap: onToggle,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color:
                    isExcluded
                        ? RfpTheme.surfaceContainerHigh
                        : RfpTheme.primaryContainer,
                border:
                    isExcluded
                        ? Border.all(color: RfpTheme.outlineVariant)
                        : null,
              ),
              child:
                  isExcluded
                      ? null
                      : const Icon(
                        Icons.check,
                        color: RfpTheme.onPrimaryContainer,
                        size: 18,
                      ),
            ),
          ),
        ],
      ),
    );
  }
}
