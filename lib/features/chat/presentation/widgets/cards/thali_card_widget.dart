import 'package:flutter/material.dart';
import 'package:grocery_app/core/theme/app_colors.dart';

/// Dedicated Thali/meal-plan card widget.
class ThaliCardWidget extends StatelessWidget {
  final Map<String, dynamic> thaliData;

  const ThaliCardWidget({Key? key, required this.thaliData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final name =
        thaliData['thali_name']?.toString() ??
        thaliData['name']?.toString() ??
        'Meal Plan';
    final mealType = thaliData['meal_type']?.toString() ?? 'Meal';
    final items = thaliData['items'] as List<dynamic>? ?? [];
    final benefits =
        thaliData['nutritional_highlights'] as List<dynamic>? ??
        thaliData['benefits'] as List<dynamic>? ??
        [];
    final recommendedFor = thaliData['recommended_for'] as List<dynamic>? ?? [];
    final calories = thaliData['total_calories']?.toString();

    return Container(
      margin: const EdgeInsets.only(top: 10.0, bottom: 4.0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isDark
                  ? AppColors.darkSurface
                  : AppColors.deepSoilGreen.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.deepSoilGreen.withValues(
                alpha: isDark ? 0.2 : 0.05,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.restaurant_menu,
                  color:
                      isDark
                          ? AppColors.darkSuccessGreen
                          : AppColors.deepSoilGreen,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.charcoal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.harvestAmber.withValues(
                                alpha: 0.2,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              mealType.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.harvestAmber,
                              ),
                            ),
                          ),
                          if (calories != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              "• $calories kcal",
                              style: TextStyle(
                                fontSize: 11,
                                color:
                                    isDark
                                        ? Colors.white60
                                        : AppColors.charcoal54,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Items
                if (items.isNotEmpty) ...[
                  Text(
                    "Included Items",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : AppColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        items.map((item) {
                          return Chip(
                            label: Text(
                              item.toString(),
                              style: const TextStyle(fontSize: 12),
                            ),
                            backgroundColor:
                                isDark
                                    ? AppColors.darkSurface
                                    : AppColors.parchment,
                            side: BorderSide.none,
                            padding: EdgeInsets.zero,
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // Benefits
                if (benefits.isNotEmpty) ...[
                  Text(
                    "Nutritional Highlights",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : AppColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...benefits
                      .map(
                        (benefit) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.check,
                                size: 14,
                                color: AppColors.deepSoilGreen,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  benefit.toString(),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color:
                                        isDark
                                            ? Colors.white70
                                            : AppColors.charcoal54,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  const SizedBox(height: 16),
                ],

                // Recommended For
                if (recommendedFor.isNotEmpty) ...[
                  Text(
                    "Recommended For",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : AppColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children:
                        recommendedFor.map((cond) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.deepSoilGreen.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: AppColors.deepSoilGreen.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            child: Text(
                              cond.toString(),
                              style: TextStyle(
                                fontSize: 11,
                                color:
                                    isDark
                                        ? AppColors.darkSuccessGreen
                                        : AppColors.deepSoilGreen,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
