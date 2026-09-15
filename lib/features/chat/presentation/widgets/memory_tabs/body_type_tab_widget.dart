import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:grocery_app/core/theme/app_colors.dart';
import '../../../domain/entities/body_type_entity.dart';
import '../aahar_vigyan_welcome_sheet.dart';
import 'assessment_answers_review_widget.dart';

class BodyTypeTabWidget extends StatelessWidget {
  final BodyTypeEntity bodyType;
  final ValueChanged<String>? onDoshaChanged;

  const BodyTypeTabWidget({
    super.key,
    required this.bodyType,
    this.onDoshaChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkSurfaceElevated : AppColors.pureWhite;

    if (!bodyType.hasAssessment) {
      return _buildOnboardingRequiredView(context, isDark);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Primary Header Card ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF2C2416), const Color(0xFF1E1E1E)]
                    : [const Color(0xFFFFF8EE), const Color(0xFFFFFDF9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.harvestAmber.withValues(alpha: 0.4), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.harvestAmber.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.harvestAmber.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.spa_rounded, color: AppColors.harvestAmber, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "AYURVEDIC CONSTITUTION",
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                              color: AppColors.harvestAmber,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            bodyType.title,
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── Dosha Score Gauges ──
                _buildDoshaBar("Pitta (Fire/Water)", bodyType.pittaScore, const Color(0xFFE65100), isDark),
                const SizedBox(height: 8),
                _buildDoshaBar("Vata (Air/Ether)", bodyType.vataScore, const Color(0xFF0288D1), isDark),
                const SizedBox(height: 8),
                _buildDoshaBar("Kapha (Earth/Water)", bodyType.kaphaScore, const Color(0xFF2E7D32), isDark),
                const SizedBox(height: 12),

                // ── Retake Assessment Action ──
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => context.push('/prakriti-quiz'),
                    icon: const Icon(Icons.assignment_outlined, size: 15, color: AppColors.harvestAmber),
                    label: const Text(
                      "Take 20-Q Prakriti Assessment",
                      style: TextStyle(fontSize: 11.8, fontWeight: FontWeight.bold, color: AppColors.harvestAmber),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Section 1: What Is It? ──
          _buildInfoSection(
            context: context,
            title: "What Is It?",
            icon: Icons.psychology_rounded,
            iconColor: const Color(0xFF7B1FA2),
            content: bodyType.whatIsIt,
            cardBg: cardBg,
            isDark: isDark,
          ),
          const SizedBox(height: 14),

          // ── Section 2: Why Is It? ──
          _buildInfoSection(
            context: context,
            title: "Why Is It?",
            icon: Icons.analytics_outlined,
            iconColor: const Color(0xFF00897B),
            content: bodyType.whyIsIt,
            cardBg: cardBg,
            isDark: isDark,
          ),
          const SizedBox(height: 14),

          if (bodyType.whyIsItRequired.isNotEmpty) ...[
            _buildInfoSection(
              context: context,
              title: "Why Understanding Your Body Type Matters",
              icon: Icons.lightbulb_outline_rounded,
              iconColor: const Color(0xFFFF8F00),
              content: bodyType.whyIsItRequired,
              cardBg: cardBg,
              isDark: isDark,
            ),
            const SizedBox(height: 14),
          ],

          // ── Section 3: Vedic Kundli Astrological Alignment ──
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: AppColors.harvestAmber, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "Kundli-Ahara Astrological Alignment",
                      style: TextStyle(fontSize: 14.2, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildPill("Lagna Rising", bodyType.lagnaAscendant, isDark),
                    _buildPill("Moon Sign", bodyType.janmaRashi, isDark),
                    _buildPill("Nakshatra", bodyType.janmaNakshatra, isDark),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Section 4: Balancing Ahara Guidelines ──
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.restaurant_menu_rounded, color: AppColors.deepSoilGreen, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "Constitutional Dietary Guidelines",
                      style: TextStyle(fontSize: 14.2, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  "Foods & Nutrition to Favor:",
                  style: TextStyle(fontSize: 12.2, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                ...bodyType.keyFoods.map((food) => Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("• ", style: TextStyle(color: AppColors.deepSoilGreen, fontWeight: FontWeight.bold)),
                          Expanded(
                            child: Text(
                              food,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 10),
                const Text(
                  "Daily Lifestyle & Timing Guidelines:",
                  style: TextStyle(fontSize: 12.2, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                ...bodyType.lifestyleGuidelines.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("• ", style: TextStyle(color: AppColors.harvestAmber, fontWeight: FontWeight.bold)),
                          Expanded(
                            child: Text(
                              item,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Section 5: 40-Day Lifecycle & Recorded Answers from DB ──
          AssessmentAnswersReviewWidget(
            lifecycle: bodyType.lifecycle,
            answeredQuestions: bodyType.answeredQuestions,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDoshaBar(String label, int percent, Color color, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 11.8, fontWeight: FontWeight.w600)),
            Text("$percent%", style: TextStyle(fontSize: 11.8, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent / 100.0,
            minHeight: 6,
            backgroundColor: isDark ? Colors.white12 : Colors.black12,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color iconColor,
    required String content,
    required Color cardBg,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 14.2, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 12.8,
              height: 1.45,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPill(String label, String value, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("$label: ", style: const TextStyle(fontSize: 11.2, fontWeight: FontWeight.w600)),
          Text(
            value,
            style: const TextStyle(fontSize: 11.2, fontWeight: FontWeight.bold, color: AppColors.harvestAmber),
          ),
        ],
      ),
    );
  }

  Widget _buildOnboardingRequiredView(BuildContext context, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.forest.withValues(alpha: 0.12),
            ),
            child: const Icon(
              Icons.spa_rounded,
              size: 48,
              color: AppColors.forest,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Welcome to Aahar Vigyan",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Your personalised food intelligence — built from your body, your stars, and today's cosmic rhythm.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: isDark ? Colors.white70 : AppColors.charcoal70,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceElevated : AppColors.pureWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.08),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.forest.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        "Step 1",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.forest,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "Ayurvedic Prakriti",
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "A 7-question body type test reveals your Prakriti — your constitutional blueprint since birth. This shapes your food forever.",
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: isDark ? Colors.white60 : AppColors.charcoal60,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => AaharVigyanWelcomeSheet.show(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forest,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.spa_rounded, size: 18),
              label: const Text(
                'Start My Journey →',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Takes about 7 minutes · Free to start',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white38 : AppColors.charcoal38,
            ),
          ),
        ],
      ),
    );
  }
}
