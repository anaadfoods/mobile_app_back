import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:grocery_app/core/theme/app_colors.dart';
import 'home_community_card.dart';

class HomeCategoryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imagePath;
  final VoidCallback onTap;
  final IconData icon;

  const HomeCategoryCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.onTap,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TappableCard(
      onTap: onTap,
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          color: AppColors.parchment,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.charcoal.withValues(alpha: 0.15),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Positioned.fill(
                child: imagePath.toLowerCase().endsWith('.svg')
                    ? SvgPicture.asset(imagePath, fit: BoxFit.cover)
                    : Image.asset(imagePath, fit: BoxFit.cover),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.charcoal.withValues(alpha: 0.1),
                        AppColors.charcoal.withValues(alpha: 0.6),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.9,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(icon, color: AppColors.parchment, size: 14),
                    ),
                    const SizedBox(height: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.parchment,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: AppColors.charcoal.withValues(
                                  alpha: 0.5,
                                ),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.parchment.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w500,
                            shadows: [
                              Shadow(
                                color: AppColors.charcoal.withValues(
                                  alpha: 0.5,
                                ),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.parchment.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: theme.colorScheme.primary,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
