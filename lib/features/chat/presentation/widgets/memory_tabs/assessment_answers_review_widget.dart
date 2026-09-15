import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:grocery_app/core/theme/app_colors.dart';
import '../../../domain/entities/body_type_entity.dart';

/// Renders the 40-day Ayurveda assessment cycle countdown and
/// the user's recorded question-by-question answers from the database.
class AssessmentAnswersReviewWidget extends StatelessWidget {
  final AssessmentLifecycleEntity lifecycle;
  final List<AssessmentAnswerEntity> answeredQuestions;

  const AssessmentAnswersReviewWidget({
    super.key,
    required this.lifecycle,
    required this.answeredQuestions,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkSurfaceElevated : AppColors.pureWhite;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 40-Day Cycle Countdown Banner ──
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: lifecycle.isDue
                  ? (isDark
                      ? [const Color(0xFF3E2723), const Color(0xFF212121)]
                      : [const Color(0xFFFFF3E0), const Color(0xFFFFFFFF)])
                  : (isDark
                      ? [const Color(0xFF1E3A2F), const Color(0xFF1E1E1E)]
                      : [const Color(0xFFE8F5E9), const Color(0xFFFFFFFF)]),
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: lifecycle.isDue ? AppColors.harvestAmber : const Color(0xFF2E7D32),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: (lifecycle.isDue ? AppColors.harvestAmber : const Color(0xFF2E7D32)).withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (lifecycle.isDue ? AppColors.harvestAmber : const Color(0xFF2E7D32)).withValues(alpha: 0.15),
                ),
                child: Center(
                  child: Text(
                    lifecycle.isDue ? "0" : "${lifecycle.daysRemaining}d",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: lifecycle.isDue ? AppColors.harvestAmber : const Color(0xFF2E7D32),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          lifecycle.isDue ? "ASSESSMENT DUE NOW" : "40-DAY AYURVEDA CYCLE ACTIVE",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: lifecycle.isDue ? AppColors.harvestAmber : const Color(0xFF2E7D32),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      lifecycle.isDue
                          ? "Take your 40-day Prakriti review to track Vikriti shifts."
                          : "${lifecycle.daysRemaining} days remaining until next scheduled assessment.",
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => context.push('/prakriti-quiz'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: lifecycle.isDue ? AppColors.harvestAmber : const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: Text(
                  lifecycle.isDue ? "Start" : "Retake",
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Question-by-Question Recorded Answers Header ──
        Row(
          children: [
            const Icon(Icons.history_edu_rounded, size: 18, color: AppColors.harvestAmber),
            const SizedBox(width: 8),
            Text(
              "Your Assessment Responses (${answeredQuestions.length}/20)",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // If no answers yet in DB
        if (answeredQuestions.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: Column(
              children: [
                const Icon(Icons.quiz_outlined, size: 36, color: AppColors.harvestAmber),
                const SizedBox(height: 8),
                const Text(
                  "No Assessment Answers Recorded in DB Yet",
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  "Complete the 20-question Prakriti assessment to store your individual constitutional answers and track Agni changes.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => context.push('/prakriti-quiz'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.harvestAmber,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: const Text("Take 20-Q Assessment", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          )
        else
          ...answeredQuestions.map((ans) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.harvestAmber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "Q${ans.order > 0 ? ans.order : ans.questionCode}",
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.harvestAmber,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        ans.category.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    ans.questionEn,
                    style: TextStyle(
                      fontSize: 12.8,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  if (ans.questionHi.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      ans.questionHi,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E3A2F) : const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF2E7D32)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            "Option ${ans.selectedOptionId.toUpperCase()}: ${ans.selectedText.isNotEmpty ? ans.selectedText : 'Selected'}",
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFFA5D6A7) : const Color(0xFF1B5E20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}
