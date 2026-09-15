import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:grocery_app/models/panchang/panchang_day_models.dart';

class RecommendationItem {
  final String title;
  final String category;
  final String reason;
  final String bestTime;
  final IconData icon;
  final bool isProduct;

  const RecommendationItem({
    required this.title,
    required this.category,
    required this.reason,
    required this.bestTime,
    required this.icon,
    this.isProduct = false,
  });
}

/// Personalized Recommendations Section for Wellness and Anaad Organic Foods
class PersonalizedRecommendationsCard extends StatelessWidget {
  final PanchangDayResponse day;
  final bool isDark;
  final String? userDosha;
  final List<Map<String, dynamic>>? apiRecommendations;

  const PersonalizedRecommendationsCard({
    super.key,
    required this.day,
    required this.isDark,
    this.userDosha,
    this.apiRecommendations,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dosha = (userDosha ?? 'Vata').toUpperCase();
    final nakshatra = day.corePanchang.nakshatra.isNotEmpty
        ? day.corePanchang.nakshatra
        : 'Swati';
    final masa = day.lunar.masa.isNotEmpty ? day.lunar.masa : 'Shravana';

    final recommendations = apiRecommendations != null && apiRecommendations!.isNotEmpty
        ? apiRecommendations!.map((r) => RecommendationItem(
            title: r['title'] ?? '',
            category: r['category'] ?? '',
            reason: (r['reason'] ?? '').toString().replaceAll('{dosha}', dosha).replaceAll('{nakshatra}', nakshatra).replaceAll('{masa}', masa),
            bestTime: r['best_time'] ?? '',
            icon: Icons.eco_rounded,
            isProduct: r['is_product'] == true,
          )).toList()
        : [
            RecommendationItem(
              title: 'Organic A2 Desi Gir Cow Bilona Ghee',
              category: 'Anaad Organic Product',
              reason: 'Nourishes Ojas, balances $dosha mobility of $nakshatra Nakshatra, and sustains Jatharagni.',
              bestTime: 'With warm lunch',
              icon: Icons.eco_rounded,
              isProduct: true,
            ),
            RecommendationItem(
              title: 'Moong Dal & Coriander Digestive Kitchari',
              category: 'Ayurvedic Recipe',
              reason: 'Light, tridoshic, and easily digested meal suitable for $masa Masa seasonal balance.',
              bestTime: '12:00 PM - 01:30 PM (Solar Noon)',
              icon: Icons.restaurant_menu_rounded,
              isProduct: false,
            ),
            RecommendationItem(
              title: 'Cumin, Coriander & Fennel (CCF) Infusion',
              category: 'Daily Beverage',
              reason: 'Clears Ama (metabolic toxins) and gently regulates Agni while soothing $dosha.',
              bestTime: 'Post-meal or afternoon sipping',
              icon: Icons.coffee_rounded,
              isProduct: false,
            ),
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
                  Icons.shopping_bag_outlined,
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
                      'Personalized Diet & Product Guidance',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      'Synthesized from Panchang • Season • Prakriti',
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
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recommendations.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = recommendations[index];
              return _buildRecommendationTile(context, item, theme);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationTile(BuildContext context, RecommendationItem item, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              item.icon,
              size: 20,
              color: isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (item.isProduct ? AppColors.successGreen : AppColors.rawEarth).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.category,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: item.isProduct ? AppColors.successGreen : AppColors.rawEarth,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.reason,
                  style: theme.textTheme.bodySmall?.copyWith(
                    height: 1.3,
                    color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 12,
                      color: isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Best Time: ${item.bestTime}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
