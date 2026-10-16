import 'package:flutter/material.dart';
import '../rfp_theme.dart';

/// Large Benefit Card for RFP Landing Screen.
class RfpBenefitCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;

  const RfpBenefitCard({
    super.key,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(RfpTheme.spaceMd),
      decoration: BoxDecoration(
        color: RfpTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(RfpTheme.radiusLg),
        boxShadow: RfpTheme.shadowSm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(RfpTheme.radiusLg),
            ),
            child: Icon(icon, size: 24, color: iconColor),
          ),
          const SizedBox(width: RfpTheme.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: RfpTheme.headlineSm.copyWith(fontSize: 16)),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: RfpTheme.bodySm.copyWith(
                    color: RfpTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Small Benefit Card for 2-column grid on RFP Landing Screen.
class RfpSmallBenefitCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String title;
  final String subtitle;

  const RfpSmallBenefitCard({
    super.key,
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(RfpTheme.spaceMd),
      decoration: BoxDecoration(
        color: RfpTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(RfpTheme.radiusLg),
        boxShadow: RfpTheme.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(RfpTheme.radiusMd),
            ),
            child: Icon(icon, size: 20, color: RfpTheme.onSecondaryContainer),
          ),
          const SizedBox(height: RfpTheme.spaceSm),
          Text(title, style: RfpTheme.headlineSm.copyWith(fontSize: 14)),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: RfpTheme.bodySm.copyWith(
              color: RfpTheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
