import 'package:grocery_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:grocery_app/styles/colors.dart';
import 'package:grocery_app/models/cummunity_model.dart';

class HomeCommunitiesSection extends StatelessWidget {
  final Future<List<Community>> communitiesFuture;
  final Widget Function(BuildContext, Community, int) buildCard;

  const HomeCommunitiesSection({
    super.key,
    required this.communitiesFuture,
    required this.buildCard,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<List<Community>>(
      future: communitiesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.all(AppColors.spacingXL),
            child: Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(AppColors.spacingL),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.people_outline_rounded,
                    size: 32,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Communities taking a break ☕",
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "🐄 Indian farmers have practiced cow-based farming for 5000+ years!",
                    style: TextStyle(
                      color: theme.colorScheme.primary.withValues(alpha: 0.7),
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final communities = snapshot.data!;

        return Column(
          children: [
            // ── Section Header ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Decorative top rule with leaf accent
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.transparent,
                              theme.colorScheme.onSurface.withValues(
                                alpha: 0.2,
                              ),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.eco_rounded,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 32,
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.onSurface.withValues(
                                alpha: 0.2,
                              ),
                              AppColors.transparent,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Main title
                  Text(
                    'एक ही थाली के चट्टे-बट्टे',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                      letterSpacing: 0.4,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Golden tagline
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 3,
                        height: 14,
                        decoration: BoxDecoration(
                          color: AppColors.harvestAmber,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Birds of a feather, flock together!',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                          letterSpacing: 0.3,

                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // ────────────────────────────────────────────────────────
            ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              cacheExtent: 300,
              itemCount: communities.length,
              itemBuilder: (context, index) {
                final community = communities[index];
                return buildCard(context, community, index);
              },
            ),
            const SizedBox(height: AppColors.spacingL),
          ],
        );
      },
    );
  }
}
