import 'package:flutter/material.dart';
import 'package:grocery_app/core/theme/theme.dart';

class NoInternetWidget extends StatelessWidget {
  final VoidCallback onRetry;

  const NoInternetWidget({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.paddingXl,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Friendly wifi icon with warm color
            const Icon(
              Icons.wifi_off_rounded,
              size: 80,
              color: AppColors.charcoal54,
            ),
            AppSpacing.verticalXl,
            Text(
              "Oops! You're Offline 📶",
              style: context.text.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.charcoal54,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.verticalMd,
            Text(
              'Your internet took a coffee break ☕\nCheck your connection and try again.',
              style: context.text.bodyLarge?.copyWith(
                color: Theme.of(context).hintColor,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.verticalLg,
            Text(
              "🐄 A single desi cow can support an entire family's farming needs sustainably!",
              style: AppTextStyles.caption.copyWith(
                color: AppColors.deepSoilGreen,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.verticalXl,
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: FilledButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxl,
                  vertical: AppSpacing.lg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
