import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:grocery_app/core/theme/app_colors.dart';
import 'package:grocery_app/cubits/auth/auth_cubit.dart';
import 'package:grocery_app/cubits/auth/auth_state.dart';
import 'package:grocery_app/screens/dashboard/dashboard_screen.dart';
import 'package:grocery_app/screens/home/home_category_card.dart';

class HomeCategoryShowcase extends StatelessWidget {
  const HomeCategoryShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.85),
            isDark
                ? theme.colorScheme.primary.withValues(alpha: 0.7)
                : AppColors.deepSoilGreen,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative Background Elements
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.parchment.withValues(alpha: 0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            left: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.parchment.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            top: 60,
            left: 30,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.parchment.withValues(alpha: 0.3),
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: 80,
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.parchment.withValues(alpha: 0.25),
              ),
            ),
          ),

          // Main Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Icon
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.parchment.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.eco_rounded,
                        color: AppColors.parchment,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Rejuvenating Earth",
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: AppColors.parchment,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
                          Text(
                            "Nourishing Lives",
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppColors.parchment.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.parchment.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.shopping_bag_outlined,
                        color: AppColors.parchment,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Shop by Category",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.parchment,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: HomeCategoryCard(
                        title: "The Ancestral Pantry",
                        subtitle:
                            "Stock up on heirloom grains, flours and staples",
                        imagePath: "assets/images/showcase_1.svg",
                        onTap: () {
                          final dashboardState =
                              context
                                  .findAncestorStateOfType<
                                    DashboardScreenState
                                  >();
                          dashboardState?.switchToTab(1);
                        },
                        icon: Icons.grass_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: HomeCategoryCard(
                        title: "Start Remote Farming",
                        subtitle:
                            "Don't just buy vegetables. Own the land they grow on",
                        imagePath: "assets/images/showcase_2.svg",
                        onTap: () {
                          final authState = context.read<AuthCubit>().state;
                          final isRfp =
                              authState is Authenticated &&
                              authState.user.isRfp;
                          context.push(
                            isRfp ? '/delivery' : '/contract-farming',
                          );
                        },
                        icon: Icons.spa_rounded,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
