import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:grocery_app/models/panchang/panchang_day_models.dart';

/// Personal Ayurvedic Guidance Card
class AyurvedicGuidanceCard extends StatelessWidget {
  final PanchangDayResponse day;
  final bool isDark;
  final List<String>? foodsToFavor;
  final List<String>? foodsToAvoid;

  const AyurvedicGuidanceCard({
    super.key,
    required this.day,
    required this.isDark,
    this.foodsToFavor,
    this.foodsToAvoid,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final masa = day.lunar.masa;
    final rashi = day.corePanchang.moonRashi;

    final favorItems = foodsToFavor ?? [
      'Warm Moong Khichdi',
      'Pure A2 Cow Ghee',
      'Cooked seasonal squash',
      'Warm ginger infusion',
    ];

    final avoidItems = foodsToAvoid ?? [
      'Cold iced beverages',
      'Raw uncooked salads',
      'Heavy night-time curd',
      'Excess pungent spices',
    ];

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
                  Icons.spa_rounded,
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
                      'Today\'s Ayurvedic Guidance',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      'Traditional Chronobiology • Seasonal Ritucharya',
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

          // Context summary
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.wb_twilight_rounded,
                  size: 18,
                  color: isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Lunar Month: $masa • Moon in $rashi (Air Element / Vata affinity)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Favor vs Avoid Grid
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildDoshaList(
                  title: 'Foods to Favor',
                  items: favorItems,
                  icon: Icons.check_circle_outline_rounded,
                  color: AppColors.successGreen,
                  theme: theme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDoshaList(
                  title: 'Foods to Avoid',
                  items: avoidItems,
                  icon: Icons.highlight_off_rounded,
                  color: AppColors.softRed,
                  theme: theme,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Disclaimer badge
          Text(
            '*Traditional Ayurvedic wellness wisdom for lifestyle alignment. Not intended as medical diagnosis or treatment.',
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 10,
              fontStyle: FontStyle.italic,
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoshaList({
    required String title,
    required List<String> items,
    required IconData icon,
    required Color color,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                Expanded(
                  child: Text(
                    item,
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 11, height: 1.2),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
