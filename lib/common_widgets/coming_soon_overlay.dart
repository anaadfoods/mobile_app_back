import 'package:grocery_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:grocery_app/core/theme/theme.dart';

/// A full-card overlay shown when a product has `tag == false`.
/// Drop this as the last child inside any Stack that wraps a product card.
class ComingSoonOverlay extends StatelessWidget {
  const ComingSoonOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppColors.radiusXL - 4),
        child: Container(
          color: AppColors.deepSoilGreen.withValues(alpha: 0.72),
          child: Center(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md + 2,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.deepSoilGreen,
                borderRadius: BorderRadius.circular(AppColors.radiusRound),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.deepSoilGreen.withValues(alpha: 0.55),
                    blurRadius: 14,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    color: AppColors.parchment,
                    size: 15,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Coming Soon',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.parchment,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
