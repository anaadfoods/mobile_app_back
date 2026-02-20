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
            // _heading(context, "Join Our Community", null, null),
            const SizedBox(height: AppColors.spacingS),
            ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
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
