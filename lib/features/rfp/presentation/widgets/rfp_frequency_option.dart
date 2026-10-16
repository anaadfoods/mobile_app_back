import 'package:flutter/material.dart';
import '../rfp_theme.dart';

/// Frequency selection option tile in Patch Configuration screen.
class RfpFrequencyOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final bool isRecommended;
  final VoidCallback onTap;
  final Widget? trailing;

  const RfpFrequencyOption({
    super.key,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
    this.isRecommended = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(RfpTheme.spaceMd),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? RfpTheme.surfaceContainerHigh
                  : RfpTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(RfpTheme.radiusLg),
          border: Border.all(
            color: isSelected ? RfpTheme.primary : RfpTheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? RfpTheme.primary : RfpTheme.outline,
              size: 24,
            ),
            const SizedBox(width: RfpTheme.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: RfpTheme.bodyMd.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isRecommended) ...[
                        const SizedBox(width: RfpTheme.spaceSm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: RfpTheme.primaryContainer,
                            borderRadius: BorderRadius.circular(
                              RfpTheme.radiusFull,
                            ),
                          ),
                          child: Text(
                            'Recommended',
                            style: RfpTheme.labelSm.copyWith(
                              color: RfpTheme.onPrimaryContainer,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    subtitle,
                    style: RfpTheme.bodySm.copyWith(
                      color: RfpTheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: RfpTheme.spaceSm),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}
