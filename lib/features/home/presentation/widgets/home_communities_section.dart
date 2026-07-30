import 'package:flutter/material.dart';
import 'package:grocery_app/core/theme/app_colors.dart';
import '../../domain/entities/community_entity.dart';

class HomeCommunitiesSection extends StatelessWidget {
  final List<CommunityEntity> communities;
  final Widget Function(BuildContext, CommunityEntity, int) buildCard;

  const HomeCommunitiesSection({
    super.key,
    required this.communities,
    required this.buildCard,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (communities.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
        const SizedBox(height: 16),
      ],
    );
  }
}
