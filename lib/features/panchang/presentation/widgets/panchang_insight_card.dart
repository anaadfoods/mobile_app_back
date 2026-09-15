import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:grocery_app/models/panchang/panchang_day_models.dart';

/// Modern AI Explanation & Panchang Insight Card
class PanchangInsightCard extends StatelessWidget {
  final PanchangDayResponse day;
  final bool isDark;
  final String? customInsightText;

  const PanchangInsightCard({
    super.key,
    required this.day,
    required this.isDark,
    this.customInsightText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final core = day.corePanchang;
    final nakshatra = core.nakshatra;
    final yoga = core.yoga;

    final insightText = (customInsightText != null && customInsightText!.trim().isNotEmpty)
        ? customInsightText!
        : _generateInsightText(nakshatra, yoga, core.tithi);

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
                  color: (isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.auto_awesome,
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
                      'Today\'s Astrological Insight',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      'Derived from Sidereal Panchang & Ayurvedic Chronobiology',
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
          Text(
            insightText,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified_outlined,
                  size: 14,
                  color: isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Calculated via NASA JPL Ephemeris • Traditional Ayurvedic Guidance',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _generateInsightText(String nakshatra, String yoga, String tithi) {
    if (nakshatra.toLowerCase().contains('swati')) {
      return 'Swati Nakshatra is ruled by Rahu and symbolised by a tender plant shoot bending in the wind. '
          'It is traditionally associated with adaptability, freedom, prana balance, and mental clarity. '
          'Combined with $yoga Yoga, today favors independent study, nourishing warm fluids, gentle respiratory yoga (Pranayama), '
          'and avoiding dry, excessively cold foods.';
    } else if (nakshatra.toLowerCase().contains('punarvasu')) {
      return 'Punarvasu Nakshatra represents renewal, restoration, and the return of light. '
          'Ruled by Jupiter, it is excellent for rejuvenating wellness therapies, starting herbal routines, '
          'and consuming pure A2 ghee and restorative kitchari.';
    } else if (nakshatra.toLowerCase().contains('ashwini')) {
      return 'Ashwini Nakshatra carries the healing prana of the celestial physicians (Ashwini Kumaras). '
          'It energizes rapid digestion, vitality, physical activity, and morning Surya Namaskar.';
    } else {
      return '$nakshatra Nakshatra with $yoga Yoga on $tithi creates a harmonious lunar cycle for mind-body balance. '
          'Align your meal timings with solar noon to support optimal Jatharagni (digestive fire).';
    }
  }
}
