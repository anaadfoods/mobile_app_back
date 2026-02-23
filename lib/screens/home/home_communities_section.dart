import 'package:flutter/material.dart';
import 'dart:ui';
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
                    color: const Color(0xFF6B7B8A), // Cool slate
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Communities taking a break ☕",
                    style: TextStyle(
                      color: const Color(0xFF6B7B8A),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "🐄 Indian farmers have practiced cow-based farming for 5000+ years!",
                    style: TextStyle(
                      color: Colors.green.shade700,
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
                              Colors.transparent,
                              const Color(0xFF3f5e46),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.eco_rounded,
                        size: 14,
                        color: Color(0xFF3f5e46),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 32,
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF3f5e46),
                              Colors.transparent,
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
                    'Join the Movement',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface,
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
                          color: const Color(0xFFB8860B),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Where good food finds good people.',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFB8860B),
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
