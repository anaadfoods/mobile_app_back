import 'package:flutter/material.dart';
import '../rfp_theme.dart';

/// Hero Card for RFP Landing Screen matching Stitch design.
class RfpHeroCard extends StatelessWidget {
  const RfpHeroCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(RfpTheme.spaceLg),
      decoration: BoxDecoration(
        color: RfpTheme.primaryContainer,
        borderRadius: BorderRadius.circular(RfpTheme.radiusXl),
        boxShadow: RfpTheme.shadowMd,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -40,
            bottom: -40,
            child: Container(
              width: 192,
              height: 192,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: RfpTheme.secondaryContainer.withValues(alpha: 0.20),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: RfpTheme.spaceMd,
                  vertical: RfpTheme.spaceXs,
                ),
                decoration: BoxDecoration(
                  color: RfpTheme.surfaceContainerLowest.withValues(
                    alpha: 0.10,
                  ),
                  borderRadius: BorderRadius.circular(RfpTheme.radiusFull),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.spa,
                      size: 18,
                      color: RfpTheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: RfpTheme.spaceXs),
                    Text(
                      'Verified Organic Yields',
                      style: RfpTheme.labelMd.copyWith(
                        color: RfpTheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: RfpTheme.spaceMd),
              Text(
                'Remote\nFarming Plan',
                style: RfpTheme.headlineLg.copyWith(
                  color: RfpTheme.onPrimaryContainer,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: RfpTheme.spaceSm),
              Text(
                'Choose your farm patch, customize your vegetables, and receive fresh produce throughout the farming cycle.',
                style: RfpTheme.bodyMd.copyWith(
                  color: RfpTheme.onPrimaryContainer.withValues(alpha: 0.90),
                ),
              ),
              const SizedBox(height: RfpTheme.spaceMd),
              Row(
                children: [
                  _buildPatchPill('P1'),
                  _buildPatchPill('P2'),
                  _buildPatchPill('P3'),
                  _buildPatchPill('P4'),
                  const SizedBox(width: RfpTheme.spaceSm),
                  Expanded(
                    child: Text(
                      '4 Active Valley Patches Available',
                      style: RfpTheme.labelSm.copyWith(
                        color: RfpTheme.onPrimaryContainer.withValues(
                          alpha: 0.80,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPatchPill(String label) {
    return Container(
      width: 32,
      height: 32,
      margin: const EdgeInsets.only(right: 0),
      transform: Matrix4.translationValues(label == 'P1' ? 0 : -4, 0, 0),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: RfpTheme.surface,
        border: Border.all(color: RfpTheme.primaryContainer, width: 2),
      ),
      child: Center(
        child: Text(
          label,
          style: RfpTheme.labelSm.copyWith(
            color: RfpTheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
