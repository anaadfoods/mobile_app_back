import 'package:flutter/material.dart';
import 'package:grocery_app/core/theme/app_colors.dart';

class MerchantInfoBanner extends StatelessWidget {
  final String url;

  const MerchantInfoBanner({
    super.key,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.parchment : AppColors.parchment,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.deepSoilGreen : AppColors.deepSoilGreen,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.verified_rounded,
                size: 16,
                color: AppColors.deepSoilGreen,
              ),
              const SizedBox(width: 6),
              Text(
                'Anaad Foods Pvt. Ltd.',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.deepSoilGreen : AppColors.deepSoilGreen,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.deepSoilGreen,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.lock_rounded,
                      size: 12,
                      color: AppColors.parchment,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Secure',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.parchment,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.link_rounded,
                size: 14,
                color: isDark ? AppColors.rawEarth26 : AppColors.rawEarth70,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  url,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? AppColors.rawEarth26 : AppColors.rawEarth70,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
