import 'package:flutter/material.dart';
import 'package:grocery_app/core/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../domain/entities/summary_dossier_entity.dart';
import '../../../domain/entities/body_type_entity.dart';
import '../aahar_vigyan_welcome_sheet.dart';
import 'dossier_document_viewer_screen.dart';

class SummaryDossierTabWidget extends StatelessWidget {
  final SummaryDossierEntity summary;
  final bool isGenerating;
  final VoidCallback onRegeneratePressed;

  const SummaryDossierTabWidget({
    super.key,
    required this.summary,
    this.isGenerating = false,
    required this.onRegeneratePressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkSurfaceElevated : AppColors.pureWhite;
    final bodyType = summary.bodyType;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── SECTION 1: Body Type & Constitution Breakdown ──
          if (bodyType != null) ...[
            _buildBodyTypeSection(context, bodyType, cardBg, isDark),
            const SizedBox(height: 14),

            // ── SECTION 2: Constitutional Dietary & Lifestyle Guidelines ──
            _buildDietaryGuidelinesSection(context, bodyType, cardBg, isDark),
            const SizedBox(height: 14),
          ],

          // ── SECTION 3: Food Thali Nutrition Overview ──
          _buildFoodThaliSummarySection(context, cardBg, isDark),
          const SizedBox(height: 14),

          // ── SECTION 4: Medical Diagnostic OCR Overview ──
          _buildMedicalSummarySection(context, cardBg, isDark),
          const SizedBox(height: 14),

          // ── SECTION 5: Health Score & Executive Vitality Index ──
          _buildVitalityIndexCard(context, isDark),
          const SizedBox(height: 14),

          // ── SECTION 6: S3 Official Health Dossier Document ──
          _buildOfficialDossierCard(context, cardBg, isDark),
          const SizedBox(height: 14),

          // ── SECTION 7: Executive Key Findings ──
          _buildExecutiveFindingsCard(context, cardBg, isDark),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // Section 1: Body Type (Prakriti, What It Is, Why Required)
  // ══════════════════════════════════════════════════════════════════
  Widget _buildBodyTypeSection(
    BuildContext context,
    BodyTypeEntity bodyType,
    Color cardBg,
    bool isDark,
  ) {
    if (!bodyType.hasAssessment) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.harvestAmber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.spa_rounded, color: AppColors.harvestAmber, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Ayurvedic Prakriti Assessment",
                        style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 2),
                      Text(
                        "Assessment not yet taken",
                        style: TextStyle(fontSize: 11.5, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              "Take the 7-question clinical assessment to reveal your constitutional Prakriti, dosha scores, and personalized dietary guidelines.",
              style: TextStyle(fontSize: 12.0, height: 1.4),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => AaharVigyanWelcomeSheet.show(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.forest,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                ),
                icon: const Icon(Icons.spa_rounded, size: 16),
                label: const Text("Start Assessment →", style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.harvestAmber.withValues(alpha: isDark ? 0.35 : 0.5),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.harvestAmber.withValues(alpha: 0.05),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.harvestAmber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.spa_rounded, color: AppColors.harvestAmber, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "AYURVEDIC CONSTITUTION (PRAKRITI)",
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppColors.harvestAmber,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      bodyType.title,
                      style: const TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Dosha percentage score bars
          _buildDoshaBar("Pitta (Fire/Water)", bodyType.pittaScore, const Color(0xFFE65100), isDark),
          const SizedBox(height: 7),
          _buildDoshaBar("Vata (Air/Ether)", bodyType.vataScore, const Color(0xFF0288D1), isDark),
          const SizedBox(height: 7),
          _buildDoshaBar("Kapha (Earth/Water)", bodyType.kaphaScore, const Color(0xFF2E7D32), isDark),
          const SizedBox(height: 14),

          // What Is It?
          if (bodyType.whatIsIt.isNotEmpty) ...[
            const Text(
              "What Is It?",
              style: TextStyle(fontSize: 13.0, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              bodyType.whatIsIt,
              style: TextStyle(
                fontSize: 12.2,
                height: 1.45,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Why Understanding Your Body Type Matters (Required section)
          if (bodyType.whyIsItRequired.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2C2416)
                    : const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFFFB300).withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.lightbulb_rounded, color: Color(0xFFFFA000), size: 16),
                      SizedBox(width: 6),
                      Text(
                        "Why Understanding Your Body Type Matters",
                        style: TextStyle(
                          fontSize: 12.0,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFFA000),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    bodyType.whyIsItRequired,
                    style: TextStyle(
                      fontSize: 11.8,
                      height: 1.42,
                      color: isDark ? const Color(0xFFE0D8C8) : const Color(0xFF4E342E),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // Section 2: Constitutional Dietary & Lifestyle Guidelines
  // ══════════════════════════════════════════════════════════════════
  Widget _buildDietaryGuidelinesSection(
    BuildContext context,
    BodyTypeEntity bodyType,
    Color cardBg,
    bool isDark,
  ) {
    if (!bodyType.hasAssessment) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.deepSoilGreen.withValues(alpha: isDark ? 0.35 : 0.3),
        ),
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
                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Tastes to Favor
          if (bodyType.tastesToFavor.isNotEmpty) ...[
            const Text(
              "Tastes to Favor (Shad Rasa):",
              style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: bodyType.tastesToFavor.map((taste) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withValues(alpha: isDark ? 0.25 : 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    "✓ $taste",
                    style: const TextStyle(
                      fontSize: 11.2,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
          ],

          // Tastes to Minimize
          if (bodyType.tastesToMinimize.isNotEmpty) ...[
            const Text(
              "Tastes to Minimize:",
              style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: bodyType.tastesToMinimize.map((taste) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD32F2F).withValues(alpha: isDark ? 0.2 : 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFD32F2F).withValues(alpha: 0.25)),
                  ),
                  child: Text(
                    "✕ $taste",
                    style: TextStyle(
                      fontSize: 11.2,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFFEF9A9A) : const Color(0xFFC62828),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],

          // Key Foods to Favor
          if (bodyType.keyFoods.isNotEmpty) ...[
            const Text(
              "Key Balancing Foods:",
              style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            ...bodyType.keyFoods.map((food) => Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("🌱 ", style: TextStyle(fontSize: 11)),
                      Expanded(
                        child: Text(
                          food,
                          style: TextStyle(
                            fontSize: 12.0,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 8),
          ],

          // Lifestyle (Dinacharya) Guidelines
          if (bodyType.lifestyleGuidelines.isNotEmpty) ...[
            const Divider(height: 16),
            const Text(
              "Daily Dinacharya Recommendations:",
              style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            ...bodyType.lifestyleGuidelines.map((guideline) => Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("⏰ ", style: TextStyle(fontSize: 11)),
                      Expanded(
                        child: Text(
                          guideline,
                          style: TextStyle(
                            fontSize: 12.0,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // Section 3: Food Thali Nutrition Overview (Compressed)
  // ══════════════════════════════════════════════════════════════════
  Widget _buildFoodThaliSummarySection(
    BuildContext context,
    Color cardBg,
    bool isDark,
  ) {
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
              const Icon(Icons.dinner_dining_rounded, color: AppColors.harvestAmber, size: 20),
              const SizedBox(width: 8),
              const Text(
                "Food Thali Dietary Rhythm",
                style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.harvestAmber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "${summary.totalThalis} meals logged",
                  style: const TextStyle(fontSize: 11.0, fontWeight: FontWeight.bold, color: AppColors.harvestAmber),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            summary.totalThalis > 0
                ? "Nutritional intake is balanced with unpolished whole grains, seasonal sabzis, and A2 Ghee to maintain steady digestive fire (Agni)."
                : "No meals logged yet. Log your daily food thalis to track macro balance, glycemic load, and dosha alignment.",
            style: TextStyle(
              fontSize: 12.0,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // Section 4: Medical Diagnostic OCR Overview (Compressed)
  // ══════════════════════════════════════════════════════════════════
  Widget _buildMedicalSummarySection(
    BuildContext context,
    Color cardBg,
    bool isDark,
  ) {
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
              const Icon(Icons.biotech_rounded, color: Color(0xFF00897B), size: 20),
              const SizedBox(width: 8),
              const Text(
                "Medical Diagnostics & Biomarkers",
                style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF00897B).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "${summary.totalReports} reports",
                  style: const TextStyle(fontSize: 11.0, fontWeight: FontWeight.bold, color: Color(0xFF00897B)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            summary.totalReports > 0
                ? "Key diagnostic panels indexed with optical character recognition for clinical biomarker trend synthesis."
                : "No diagnostic lab reports uploaded. Upload blood tests, lipid panels, or CBC reports in the Medical OCR tab.",
            style: TextStyle(
              fontSize: 12.0,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // Section 5: Health Score & Executive Vitality Index
  // ══════════════════════════════════════════════════════════════════
  Widget _buildVitalityIndexCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E3A2F), const Color(0xFF16251E)]
              : [const Color(0xFFE8F5E9), const Color(0xFFF1F8E9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.deepSoilGreen.withValues(alpha: 0.3), width: 1.2),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 58,
                height: 58,
                child: CircularProgressIndicator(
                  value: summary.healthScore / 100.0,
                  strokeWidth: 6,
                  backgroundColor: isDark ? Colors.white12 : Colors.black12,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.deepSoilGreen),
                ),
              ),
              Text(
                "${summary.healthScore}",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.deepSoilGreen),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "HOLISTIC VITALITY INDEX",
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: AppColors.deepSoilGreen,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  "Ayur-Vigyan 360° Synthesis",
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  "Generated: ${summary.generatedAt}",
                  style: TextStyle(
                    fontSize: 11.2,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // Section 6: S3 Official Health Dossier Document Card
  // ══════════════════════════════════════════════════════════════════
  Widget _buildOfficialDossierCard(BuildContext context, Color cardBg, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.harvestAmber.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: AppColors.harvestAmber.withValues(alpha: 0.05),
            blurRadius: 8,
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
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.harvestAmber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.cloud_done_rounded, color: AppColors.harvestAmber, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Official Health Dossier Document",
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Stored securely in S3 Media Storage",
                      style: TextStyle(fontSize: 11.0, color: AppColors.harvestAmber, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.harvestAmber,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.visibility_rounded, size: 16),
                  label: const Text("View Full Dossier", style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DossierDocumentViewerScreen(
                          markdownContent: summary.summaryMarkdown,
                          documentUrl: summary.documentUrl,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              if (summary.documentUrl.isNotEmpty)
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    side: const BorderSide(color: AppColors.harvestAmber),
                  ),
                  child: const Icon(Icons.download_rounded, size: 18, color: AppColors.harvestAmber),
                  onPressed: () => _openExternalUrl(summary.documentUrl),
                ),
            ],
          ),
          const SizedBox(height: 10),
          // Sync & Regenerate Live Action
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.sync_rounded,
                  size: 16,
                  color: isGenerating ? AppColors.harvestAmber : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isGenerating
                        ? "Syncing chat history & regenerating..."
                        : "Syncs chats, thalis & reports since last sync",
                    style: TextStyle(
                      fontSize: 11.0,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: isGenerating ? null : onRegeneratePressed,
                  icon: isGenerating
                      ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.harvestAmber))
                      : const Icon(Icons.refresh_rounded, size: 14, color: AppColors.harvestAmber),
                  label: Text(
                    isGenerating ? "Syncing..." : "Sync & Regenerate",
                    style: const TextStyle(fontSize: 11.5, color: AppColors.harvestAmber, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // Section 7: Key Synthesized Findings
  // ══════════════════════════════════════════════════════════════════
  Widget _buildExecutiveFindingsCard(BuildContext context, Color cardBg, bool isDark) {
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
          const Row(
            children: [
              Icon(Icons.check_circle_outline_rounded, color: AppColors.deepSoilGreen, size: 18),
              SizedBox(width: 8),
              Text("Executive Health Summary", style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          ...summary.keyFindings.map((finding) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("• ", style: TextStyle(color: AppColors.deepSoilGreen, fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Text(
                        finding,
                        style: TextStyle(
                          fontSize: 12.4,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildDoshaBar(String label, int value, Color color, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
            Text(
              "$value%",
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (value / 100.0).clamp(0.0, 1.0),
            backgroundColor: isDark ? Colors.white12 : Colors.black12,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 5.5,
          ),
        ),
      ],
    );
  }

  Future<void> _openExternalUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }
}
