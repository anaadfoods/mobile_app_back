import 'package:grocery_app/common_widgets/global_import.dart';

class PrakritiAssessmentCard extends StatelessWidget {
  final bool isDark;
  final bool isQuizDone;
  final double vataScore;
  final double pittaScore;
  final double kaphaScore;
  final String? primaryDosha;
  final String? secondaryDosha;
  final VoidCallback? onTakeQuiz;
  final VoidCallback? onViewAnswers;

  const PrakritiAssessmentCard({
    super.key,
    required this.isDark,
    required this.isQuizDone,
    this.vataScore = 0.0,
    this.pittaScore = 0.0,
    this.kaphaScore = 0.0,
    this.primaryDosha,
    this.secondaryDosha,
    this.onTakeQuiz,
    this.onViewAnswers,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.pureWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.psychology_rounded,
                  size: 20,
                  color: isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prakriti Assessment',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      'Ayurvedic Body Constitution',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          if (isQuizDone)
            _buildResultsState(context, theme)
          else
            _buildEmptyState(context, theme),
        ],
      ),
    );
  }

  Widget _buildResultsState(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (primaryDosha != null) ...[
          Text(
            'Your Constitution:',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.hintColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildDoshaChip(primaryDosha!, true, theme),
              if (secondaryDosha != null && secondaryDosha!.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text('+', style: TextStyle(color: theme.hintColor, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                _buildDoshaChip(secondaryDosha!, false, theme),
              ],
            ],
          ),
          const SizedBox(height: 20),
        ],
        _buildProgressBar('Vata', vataScore, isDark ? AppColors.infoTeal : AppColors.infoTeal, theme),
        const SizedBox(height: 12),
        _buildProgressBar('Pitta', pittaScore, AppColors.harvestAmber, theme),
        const SizedBox(height: 12),
        _buildProgressBar('Kapha', kaphaScore, AppColors.deepSoilGreen, theme),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onViewAnswers,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen),
                  foregroundColor: isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text('View Answers'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextButton(
                onPressed: onTakeQuiz,
                style: TextButton.styleFrom(
                  foregroundColor: theme.hintColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Retake Quiz'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDoshaChip(String dosha, bool isPrimary, ThemeData theme) {
    final color = isPrimary 
        ? (isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen) 
        : theme.hintColor;
        
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isPrimary ? 0.1 : 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        dosha.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildProgressBar(String label, double percentage, Color color, ThemeData theme) {
    final clampedPercent = percentage.clamp(0.0, 100.0);
    return Row(
      children: [
        SizedBox(
          width: 50,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: clampedPercent / 100,
              minHeight: 8,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 40,
          child: Text(
            '${clampedPercent.toStringAsFixed(0)}%',
            textAlign: TextAlign.end,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Discover your unique mind-body constitution through our comprehensive 20-question assessment.',
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
        ),
        const SizedBox(height: 14),
        ElevatedButton.icon(
          onPressed: onTakeQuiz,
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen,
            foregroundColor: isDark ? Colors.black : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          icon: const Icon(Icons.play_arrow_rounded, size: 18),
          label: const Text('Begin Prakriti Assessment', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
