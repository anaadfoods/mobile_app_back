import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:grocery_app/models/panchang/panchang_guidance_models.dart';
import '../panchang_guidance_screen.dart';

class GuidanceHighlightCard extends StatelessWidget {
  final GuidanceTodayResponse guidance;
  final bool isDark;

  const GuidanceHighlightCard({
    super.key,
    required this.guidance,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final activeRec = guidance.recommendations.firstWhere(
      (r) => r.hasActiveRecommendedWindow,
      orElse: () => guidance.recommendations.firstWhere(
        (r) => r.upcomingRecommendedWindows.isNotEmpty,
        orElse: () => guidance.recommendations.first,
      ),
    );

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PanchangGuidanceScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [AppColors.darkSurface, AppColors.darkSurfaceElevated]
                : [AppColors.deepSoilGreen, const Color(0xFF3A6B24)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: (isDark ? AppColors.parchment : AppColors.deepSoilGreen)
                .withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.parchment.withValues(alpha: 0.15),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.parchment.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.parchment.withValues(alpha: 0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: AppColors.pureWhite,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AutoSizeText(
                        'Today\'s Guidance',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.pureWhite,
                        ),
                      ),
                      AutoSizeText(
                        'Personalized recommendations',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.pureWhite.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.pureWhite,
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.pureWhite.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AutoSizeText(
                          activeRec.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.pureWhite,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AutoSizeText(
                          activeRec.verdict,
                          style: TextStyle(
                            fontSize: 13,
                            color: activeRec.verdict.toLowerCase().contains(
                                  'avoid',
                                )
                                ? AppColors.rawEarth
                                : activeRec.verdict.toLowerCase().contains(
                                      'recommended',
                                    )
                                    ? AppColors.deepSoilGreen
                                    : (isDark
                                        ? AppColors.pureWhite.withValues(
                                            alpha: 0.54,
                                          )
                                        : AppColors.charcoal54),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (activeRec.notesList.isNotEmpty)
                    Icon(
                      Icons.info_outline,
                      color: isDark ? AppColors.pureWhite : AppColors.parchment,
                      size: 20,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
