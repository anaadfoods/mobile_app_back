import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:grocery_app/common_widgets/animated_screen_header.dart';
import 'package:grocery_app/common_widgets/glassmorphic_icon_button.dart';
import 'package:grocery_app/core/theme/app_colors.dart';
import 'package:grocery_app/services/content_config_service.dart';
import 'package:grocery_app/services/token_service.dart';
import 'package:grocery_app/service_locator.dart';
import '../cubit/prakriti_quiz_cubit.dart';

class PrakritiQuizScreen extends StatefulWidget {
  const PrakritiQuizScreen({super.key});

  @override
  State<PrakritiQuizScreen> createState() => _PrakritiQuizScreenState();
}

class _PrakritiQuizScreenState extends State<PrakritiQuizScreen> with SingleTickerProviderStateMixin {
  late AnimationController _headerController;
  Map<String, String> _milestoneBlocks = {};

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
    _loadMilestones();
    context.read<PrakritiQuizCubit>().loadQuestions();
  }

  Future<void> _loadMilestones() async {
    try {
      final token = await getIt<TokenService>().getAccessToken();
      if (token == null) return;
      final blocks = await ContentConfigService()
          .fetchContentBlocks(token: token, screen: 'prakirti_quiz');
      if (blocks.isNotEmpty && mounted) {
        final map = <String, String>{};
        for (final b in blocks) {
          final key = b['block_key'] as String?;
          final content = b['content_en'] as String?;
          if (key != null && content != null) {
            map[key] = content;
          }
        }
        setState(() => _milestoneBlocks = map);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _headerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkSurface : const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            // ── Animated Screen Header (like Cart & Home Screens) ──
            BlocBuilder<PrakritiQuizCubit, PrakritiQuizState>(
              builder: (context, state) {
                String subtitle = "Ayurvedic Constitution Assessment";
                if (state is PrakritiQuizQuestionsLoaded && state.questions.isNotEmpty) {
                  final currentQ = state.questions[state.currentIndex];
                  final cat = currentQ['category'] ?? '';
                  subtitle = "Question ${state.currentIndex + 1} of ${state.questions.length} • ${_formatCategoryName(cat)}";
                }
                return AnimatedScreenHeader(
                  title: "Prakriti Assessment",
                  subtitle: subtitle,
                  icon: Icons.spa_rounded,
                  showBack: true,
                  onBack: () => context.pop(),
                  hasParticles: true,
                  animationController: _headerController,
                  actions: [
                    GlassmorphicIconButton(
                      icon: Icons.refresh_rounded,
                      iconSize: 20,
                      onTap: () => context.read<PrakritiQuizCubit>().loadQuestions(),
                    ),
                  ],
                );
              },
            ),


            // ── Main Body Content ──
            Expanded(
              child: BlocConsumer<PrakritiQuizCubit, PrakritiQuizState>(
                listener: (context, state) {
                  if (state is PrakritiQuizError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.message), backgroundColor: AppColors.softRed),
                    );
                  }
                },
                builder: (context, state) {
                  if (state is PrakritiQuizLoading || state is PrakritiQuizInitial) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: AppColors.harvestAmber),
                          SizedBox(height: 14),
                          Text(
                            'Loading Ayurveda Questions from DB...',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    );
                  } else if (state is PrakritiQuizQuestionsLoaded) {
                    return _buildQuizContent(context, state, isDark);
                  } else if (state is PrakritiQuizSubmitting) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: AppColors.deepSoilGreen),
                          SizedBox(height: 16),
                          Text(
                            'Analyzing & Persisting to Database...',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  } else if (state is PrakritiQuizResult) {
                    return _buildResultContent(state.result, isDark);
                  } else if (state is PrakritiQuizError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline_rounded, color: AppColors.softRed, size: 48),
                            const SizedBox(height: 12),
                            Text(
                              state.message,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.harvestAmber),
                              onPressed: () => context.read<PrakritiQuizCubit>().loadQuestions(),
                              icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
                              label: const Text('Retry', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizContent(BuildContext context, PrakritiQuizQuestionsLoaded state, bool isDark) {
    if (state.questions.isEmpty) {
      return const Center(child: Text('No questions available in database.'));
    }

    final totalQuestions = state.questions.length;
    final currentIndex = state.currentIndex;
    final currentQuestion = state.questions[currentIndex];

    final questionCode = currentQuestion['code'] ?? 'q_$currentIndex';
    final selectedOptionId = state.answers[questionCode];
    final category = currentQuestion['category'] ?? 'Ayurvedic Constitution';
    final questionTextEn = currentQuestion['question_en'] ?? currentQuestion['text_en'] ?? '';
    final questionTextHi = currentQuestion['question_hi'] ?? currentQuestion['text_hi'] ?? '';
    final options = (currentQuestion['options'] as List<dynamic>?) ?? [];
    final progress = (currentIndex + 1) / totalQuestions;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── 1. Top Header Card (Wireframe: 'Header') ──
          Container(
            padding: const EdgeInsets.all(14.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF2C2416), const Color(0xFF1A1A1A)]
                    : [const Color(0xFFFFF8EE), const Color(0xFFFFFFFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: AppColors.harvestAmber.withValues(alpha: 0.35), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.harvestAmber.withValues(alpha: 0.06),
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
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.spa_rounded, color: AppColors.harvestAmber, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'AYUR-VIGYAN PRAKRITI ASSESSMENT',
                            style: TextStyle(
                              fontSize: 10.2,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: AppColors.harvestAmber,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatCategoryName(category),
                            style: TextStyle(
                              fontSize: 13.8,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    backgroundColor: isDark ? Colors.white12 : Colors.black12,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.harvestAmber),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── 2. Progress / Counter Bar (Wireframe: [num] [question out of]) ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: Row(
              children: [
                // [num] Oval Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.harvestAmber,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${currentIndex + 1}'.padLeft(2, '0'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // [question out of]
                Expanded(
                  child: Text(
                    'Question ${currentIndex + 1} of $totalQuestions',
                    style: TextStyle(
                      fontSize: 12.8,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                ),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.harvestAmber),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── 3. Question Card (Wireframe: [Question]) ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  questionTextEn,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                    height: 1.4,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                if (questionTextHi.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    questionTextHi,
                    style: TextStyle(
                      fontSize: 13.0,
                      height: 1.35,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── 4. Options List (Wireframe: (O) [option]) ──
          ...options.map((opt) {
            final optId = opt['id'] ?? '';
            final optTextEn = opt['text_en'] ?? '';
            final optTextHi = opt['text_hi'] ?? '';
            final isSelected = selectedOptionId == optId;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () => context.read<PrakritiQuizCubit>().answerQuestion(questionCode, optId),
                borderRadius: BorderRadius.circular(14),
                child: Row(
                  children: [
                    // Left (O) Circle indicator
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? AppColors.harvestAmber : Colors.transparent,
                        border: Border.all(
                          color: isSelected ? AppColors.harvestAmber : (isDark ? Colors.white30 : Colors.black26),
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Center(child: Icon(Icons.check, size: 18, color: Colors.white))
                          : Center(
                              child: Text(
                                optId.toString().toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white54 : Colors.black54,
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(width: 10),
                    // Right [Option Card]
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.harvestAmber.withValues(alpha: 0.12)
                              : (isDark ? AppColors.darkSurfaceElevated : Colors.white),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.harvestAmber
                                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              optTextEn,
                              style: TextStyle(
                                fontSize: 13.0,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                            if (optTextHi.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                optTextHi,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 10),

          // ── 5. Navigation Row (Wireframe: [pre] [next]) ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // [pre] Button
              if (currentIndex > 0)
                OutlinedButton.icon(
                  onPressed: () => context.read<PrakritiQuizCubit>().goToQuestion(currentIndex - 1),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    side: const BorderSide(color: AppColors.harvestAmber),
                  ),
                  icon: const Icon(Icons.arrow_back_rounded, size: 16, color: AppColors.harvestAmber),
                  label: const Text('Previous', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.harvestAmber)),
                )
              else
                const SizedBox(width: 80),

              // [next] Button
              ElevatedButton.icon(
                onPressed: selectedOptionId != null
                    ? () {
                        if (currentIndex < totalQuestions - 1) {
                          context.read<PrakritiQuizCubit>().goToQuestion(currentIndex + 1);
                        } else {
                          context.read<PrakritiQuizCubit>().submitQuiz();
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.harvestAmber,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: isDark ? Colors.white12 : Colors.black12,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                label: Text(
                  currentIndex < totalQuestions - 1 ? 'Next' : 'Submit Assessment',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                icon: Icon(
                  currentIndex < totalQuestions - 1 ? Icons.arrow_forward_rounded : Icons.check_circle_rounded,
                  size: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── 6. Motivation Banner (Wireframe: 'motivation to move next') ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E3A2F) : const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.deepSoilGreen.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline_rounded, color: AppColors.deepSoilGreen, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getMotivationText(currentIndex, totalQuestions),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFFA5D6A7) : const Color(0xFF2E7D32),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  String _formatCategoryName(String cat) {
    switch (cat.toLowerCase()) {
      case 'body_frame':
        return 'Body Frame & Build';
      case 'skin_hair':
        return 'Skin, Hair & Eyes';
      case 'digestion':
        return 'Digestion & Agni';
      case 'sleep':
        return 'Sleep & Dreams';
      case 'temperament':
        return 'Mind & Temperament';
      case 'weather':
        return 'Climate Preference';
      default:
        return 'Ayurvedic Constitution';
    }
  }

  String _getMotivationText(int index, int total) {
    final qNum = index + 1;
    if (qNum <= 5 && _milestoneBlocks.containsKey('milestone_1')) {
      return _milestoneBlocks['milestone_1']!;
    } else if (qNum <= 10 && _milestoneBlocks.containsKey('milestone_2')) {
      return _milestoneBlocks['milestone_2']!;
    } else if (qNum <= 15 && _milestoneBlocks.containsKey('milestone_3')) {
      return _milestoneBlocks['milestone_3']!;
    } else if (qNum < total && _milestoneBlocks.containsKey('milestone_4')) {
      return _milestoneBlocks['milestone_4']!;
    } else if (qNum == total && _milestoneBlocks.containsKey('milestone_5')) {
      return _milestoneBlocks['milestone_5']!;
    }

    final remaining = total - (index + 1);
    if (remaining == 0) {
      return '✨ Final question! Submit to store answers in DB and reveal your dominant Dosha.';
    } else if (remaining <= 5) {
      return '🌿 Almost there! Just $remaining more questions to complete your Ayur-Vigyan analysis.';
    }
    return '💡 Answer based on your natural, lifelong tendencies rather than recent temporary changes.';
  }


  Widget _buildResultContent(Map<String, dynamic> result, bool isDark) {
    final data = (result['data'] is Map<String, dynamic>) ? result['data'] as Map<String, dynamic> : result;
    final primary = data['primary_dosha'] ?? 'Pitta';
    final secondary = data['secondary_dosha'] ?? 'Vata';
    final prakritiTitle = data['prakriti'] ?? '$primary-$secondary';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(colors: [AppColors.harvestAmber, Color(0xFFE65100)]),
                boxShadow: [
                  BoxShadow(color: AppColors.harvestAmber.withValues(alpha: 0.4), blurRadius: 16, spreadRadius: 2),
                ],
              ),
              child: const Icon(Icons.spa_rounded, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 20),
            const Text(
              'ASSESSMENT COMPLETE & SAVED TO DB',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                color: AppColors.harvestAmber,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Your Prakriti is $prakritiTitle',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Primary Dosha: $primary | Secondary Dosha: $secondary\n'
              'Your 20 responses are saved in the database. Next review due in 40 days.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.8,
                height: 1.4,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.harvestAmber,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('View Updated Health Profile', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
