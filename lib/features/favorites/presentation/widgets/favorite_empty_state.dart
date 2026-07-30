import 'package:flutter/material.dart';
import 'package:grocery_app/styles/colors.dart';

class FavoriteEmptyState extends StatelessWidget {
  final Animation<double> pulseAnimation;

  const FavoriteEmptyState({
    super.key,
    required this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: 0.9 + (pulseAnimation.value - 1) * 0.5,
                  child: child,
                );
              },
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.harvestAmber.withValues(alpha: 0.15),
                      AppColors.rawEarth.withValues(alpha: 0.1),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite_border_rounded,
                  size: 80,
                  color: AppColors.harvestAmber,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Favorites Yet',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Explore our fresh organic selection and tap the heart icon to save products here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.secondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
