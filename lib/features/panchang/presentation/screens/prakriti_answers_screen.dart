import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grocery_app/core/theme/app_colors.dart';
import '../cubit/prakriti_quiz_cubit.dart';

class PrakritiAnswersScreen extends StatefulWidget {
  const PrakritiAnswersScreen({Key? key}) : super(key: key);

  @override
  State<PrakritiAnswersScreen> createState() => _PrakritiAnswersScreenState();
}

class _PrakritiAnswersScreenState extends State<PrakritiAnswersScreen> {
  @override
  void initState() {
    super.initState();
    context.read<PrakritiQuizCubit>().loadPreviousAnswers();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.softCream,
      appBar: AppBar(
        title: const Text('Your Prakriti Answers'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: BlocBuilder<PrakritiQuizCubit, PrakritiQuizState>(
        builder: (context, state) {
          if (state is PrakritiQuizLoading || state is PrakritiQuizInitial) {
            return const Center(child: CircularProgressIndicator(color: AppColors.deepSoilGreen));
          } else if (state is PrakritiQuizError) {
            return Center(child: Text('Error: ${state.message}'));
          } else if (state is PrakritiQuizResult) {
            final result = state.result;
            final answers = (result['answers'] as List<dynamic>?) ?? [];
            final prakriti = result['prakriti'] ?? 'Unknown';
            
            if (answers.isEmpty) {
              return const Center(child: Text('No previous answers found.'));
            }

            return Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppColors.spacingL),
                    itemCount: answers.length,
                    separatorBuilder: (context, index) => const SizedBox(height: AppColors.spacingL),
                    itemBuilder: (context, index) {
                      final answerData = answers[index];
                      return _buildAnswerCard(context, answerData, index + 1, isDark);
                    },
                  ),
                ),
                // Bottom Summary
                Container(
                  padding: const EdgeInsets.all(AppColors.spacingXL),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceElevated : AppColors.pureWhite,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        offset: const Offset(0, -4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Your Prakriti:',
                          style: TextStyle(
                            fontSize: 16,
                            color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.7),
                          ),
                        ),
                        Text(
                          prakriti.toString(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildAnswerCard(BuildContext context, Map<String, dynamic> data, int index, bool isDark) {
    final questionText = data['question_text_en'] ?? 'Question text missing';
    final category = data['category'] ?? 'General';
    final options = (data['options'] as List<dynamic>?) ?? [];
    final selectedOptionId = data['selected_option_id'];

    return Container(
      padding: const EdgeInsets.all(AppColors.spacingL),
      decoration: BoxDecoration(
        color: isDark ? AppColors.charcoal : AppColors.pureWhite,
        borderRadius: BorderRadius.circular(AppColors.radiusL),
        border: Border.all(
          color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Q$index',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.6),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(AppColors.radiusRound),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppColors.spacingM),
          Text(
            questionText,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.pureWhite : AppColors.charcoal,
            ),
          ),
          const SizedBox(height: AppColors.spacingL),
          ...options.map((opt) {
            final optId = opt['id'];
            final optText = opt['text_en'] ?? '';
            final isSelected = optId == selectedOptionId;

            return Container(
              margin: const EdgeInsets.only(bottom: AppColors.spacingS),
              padding: const EdgeInsets.all(AppColors.spacingM),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.deepSoilGreen.withValues(alpha: 0.08)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppColors.radiusS),
                border: Border.all(
                  color: isSelected
                      ? AppColors.deepSoilGreen.withValues(alpha: 0.3)
                      : Colors.transparent,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.check_circle : Icons.circle_outlined,
                    color: isSelected
                        ? AppColors.deepSoilGreen
                        : (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.2),
                    size: 20,
                  ),
                  const SizedBox(width: AppColors.spacingM),
                  Expanded(
                    child: Text(
                      optText,
                      style: TextStyle(
                        color: isSelected
                            ? (isDark ? AppColors.pureWhite : AppColors.charcoal)
                            : (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.5),
                        fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
