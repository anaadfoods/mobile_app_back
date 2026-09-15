import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:grocery_app/models/panchang/panchang_guidance_models.dart';
import '../screens/panchang_guidance_screen.dart';

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
      orElse:
          () => guidance.recommendations.firstWhere(
            (r) => r.upcomingRecommendedWindows.isNotEmpty,
            orElse: () => guidance.recommendations.first,
          ),
    );

    final isFastingDay = guidance.source.tithi.toLowerCase().contains('ekadashi') ||
        guidance.source.tithi.toLowerCase().contains('purnima') ||
        guidance.source.tithi.toLowerCase().contains('amavasya') ||
        guidance.source.tithi.toLowerCase().contains('pradosh');

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isDark ? AppColors.charcoal : AppColors.deepSoilGreen)
                .withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [AppColors.darkSurface, AppColors.darkSurfaceElevated]
                  : [AppColors.deepSoilGreen, const Color(0xFF386624)],
            ),
            border: Border.all(
              color: (isDark ? AppColors.parchment : AppColors.pureWhite)
                  .withValues(alpha: 0.2),
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (isDark ? AppColors.parchment : AppColors.pureWhite)
                          .withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppColors.pureWhite,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const AutoSizeText(
                              'Ayur Guidance',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AppColors.pureWhite,
                                letterSpacing: -0.2,
                              ),
                            ),
                            if (isFastingDay) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.harvestAmber.withValues(alpha: 0.85),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'VRAT / FASTING',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.pureWhite,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        AutoSizeText(
                          '${guidance.source.tithi} • ${guidance.source.vara}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.pureWhite.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const PanchangGuidanceScreen()),
                      );
                    },
                    icon: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: AppColors.pureWhite,
                      size: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Highlighted Recommendation Box
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PanchangGuidanceScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.pureWhite.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.pureWhite.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: AutoSizeText(
                              activeRec.title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.pureWhite,
                              ),
                              maxLines: 1,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: activeRec.hasActiveRecommendedWindow
                                  ? const Color(0xFF4CAF50).withValues(alpha: 0.9)
                                  : AppColors.pureWhite.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              activeRec.hasActiveRecommendedWindow
                                  ? 'ACTIVE NOW'
                                  : 'RECOMMENDED',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.pureWhite,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      AutoSizeText(
                        activeRec.verdict,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.pureWhite.withValues(alpha: 0.88),
                          height: 1.3,
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Bottom Actions Row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const PanchangGuidanceScreen()),
                        );
                      },
                      icon: const Icon(Icons.menu_book_rounded,
                          size: 16, color: AppColors.pureWhite),
                      label: const Text(
                        'Full Guidance',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.pureWhite,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: AppColors.pureWhite.withValues(alpha: 0.35),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        context.push('/ai-chat');
                      },
                      icon: const Icon(Icons.chat_bubble_outline_rounded,
                          size: 16, color: AppColors.deepSoilGreen),
                      label: const Text(
                        'Ask Ayur AI',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.deepSoilGreen,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.pureWhite,
                        foregroundColor: AppColors.deepSoilGreen,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
