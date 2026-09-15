import 'package:flutter/material.dart';
import 'package:grocery_app/core/theme/app_colors.dart';
import '../../../domain/entities/food_thali_item_entity.dart';

class FoodThaliTabWidget extends StatefulWidget {
  final List<FoodThaliItemEntity> thalis;
  final VoidCallback? onLogThaliPressed;

  const FoodThaliTabWidget({
    super.key,
    required this.thalis,
    this.onLogThaliPressed,
  });

  @override
  State<FoodThaliTabWidget> createState() => _FoodThaliTabWidgetState();
}

class _FoodThaliTabWidgetState extends State<FoodThaliTabWidget> {
  String? _selectedMonth;

  String _getMonthKey(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      final months = [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
      ];
      return "${months[date.month - 1]} ${date.year}";
    } catch (_) {
      return "Unknown";
    }
  }

  int _getWeekNumber(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      final firstDay = DateTime(date.year, date.month, 1);
      final dayOffset = firstDay.weekday - 1;
      return ((date.day + dayOffset - 1) ~/ 7) + 1;
    } catch (_) {
      return 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkSurfaceElevated : AppColors.pureWhite;

    if (widget.thalis.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.restaurant_rounded, size: 48, color: AppColors.harvestAmber.withValues(alpha: 0.6)),
              const SizedBox(height: 12),
              const Text(
                "No Food Thalis Logged Yet",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                "Mention what you eat during your AI chat or snap a thali photo to track your Ayurvedic nutrition.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.8,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final Map<String, List<FoodThaliItemEntity>> groupedByMonth = {};
    for (var thali in widget.thalis) {
      final monthKey = _getMonthKey(thali.loggedAt);
      if (!groupedByMonth.containsKey(monthKey)) {
        groupedByMonth[monthKey] = [];
      }
      groupedByMonth[monthKey]!.add(thali);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Logged Thalis & Nutrition (${widget.thalis.length})",
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              if (widget.onLogThaliPressed != null)
                TextButton.icon(
                  onPressed: widget.onLogThaliPressed,
                  icon: const Icon(Icons.add_photo_alternate_outlined, size: 16, color: AppColors.harvestAmber),
                  label: const Text(
                    "Log Meal",
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.harvestAmber),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          if (_selectedMonth == null) ...[
            _buildMonthGrid(groupedByMonth, cardBg, isDark),
          ] else ...[
            _buildMonthDetails(groupedByMonth[_selectedMonth!] ?? [], cardBg, isDark, context),
          ],
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMonthGrid(Map<String, List<FoodThaliItemEntity>> groupedByMonth, Color cardBg, bool isDark) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: groupedByMonth.keys.length,
      itemBuilder: (context, index) {
        final month = groupedByMonth.keys.elementAt(index);
        final thalisInMonth = groupedByMonth[month]!;
        int totalCals = 0;
        int thalisWithCals = 0;
        for (var t in thalisInMonth) {
          if (t.totalCalories != null) {
            totalCals += t.totalCalories!;
            thalisWithCals++;
          }
        }
        final avgCals = thalisWithCals > 0 ? (totalCals / thalisWithCals).round() : 0;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedMonth = month;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.calendar_month_rounded, size: 36, color: AppColors.harvestAmber),
                const SizedBox(height: 8),
                Text(
                  month,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.harvestAmber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "${thalisInMonth.length} meals",
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.harvestAmber),
                  ),
                ),
                if (avgCals > 0) ...[
                  const SizedBox(height: 6),
                  Text(
                    "~$avgCals kcal/meal",
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMonthDetails(List<FoodThaliItemEntity> thalis, Color cardBg, bool isDark, BuildContext context) {
    Map<int, List<FoodThaliItemEntity>> groupedByWeek = {};
    for (var thali in thalis) {
      final week = _getWeekNumber(thali.loggedAt);
      if (!groupedByWeek.containsKey(week)) {
        groupedByWeek[week] = [];
      }
      groupedByWeek[week]!.add(thali);
    }

    final sortedWeeks = groupedByWeek.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _selectedMonth = null;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.harvestAmber),
                const SizedBox(width: 8),
                const Text(
                  "Back to Months",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.harvestAmber),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _selectedMonth!,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...sortedWeeks.map((week) {
          final weekThalis = groupedByWeek[week]!;
          return ExpansionTile(
            title: Text("Week $week", style: const TextStyle(fontWeight: FontWeight.bold)),
            initiallyExpanded: true,
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(bottom: 16),
            children: weekThalis.map((thali) => _buildCompactThaliCard(thali, cardBg, isDark, context)).toList(),
          );
        }),
      ],
    );
  }

  Widget _buildCompactThaliCard(FoodThaliItemEntity thali, Color cardBg, bool isDark, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (thali.imageUrl.isNotEmpty) {
              _showImagePreviewDialog(context, thali.imageUrl, "${thali.mealTypeDisplay} Thali");
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (thali.imageUrl.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      thali.imageUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => Container(
                        width: 50,
                        height: 50,
                        color: AppColors.harvestAmber.withValues(alpha: 0.1),
                        child: const Icon(Icons.restaurant_menu_rounded, size: 20, color: AppColors.harvestAmber),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.harvestAmber.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_getMealIcon(thali.mealType), size: 12, color: AppColors.harvestAmber),
                                const SizedBox(width: 4),
                                Text(
                                  thali.mealTypeDisplay,
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.harvestAmber,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            thali.loggedDate,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: thali.thaliItems.map((item) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item,
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                      if (thali.description.isNotEmpty)
                        Text(
                          thali.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            height: 1.4,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      if (thali.totalCalories != null) ...[
                        const SizedBox(height: 8),
                        _buildMacroBadge("🔥 ${thali.totalCalories} kcal", isDark),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMacroBadge(String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? Colors.white12 : const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 10.8, fontWeight: FontWeight.w600),
      ),
    );
  }

  IconData _getMealIcon(String type) {
    switch (type.toUpperCase()) {
      case 'BREAKFAST':
        return Icons.wb_sunny_outlined;
      case 'LUNCH':
        return Icons.wb_twilight_rounded;
      case 'DINNER':
        return Icons.nights_stay_outlined;
      default:
        return Icons.fastfood_outlined;
    }
  }

  void _showImagePreviewDialog(BuildContext context, String imageUrl, String title) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: const BoxDecoration(
                  color: Color(0xEE1F2937),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Container(
                  color: Colors.black,
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.7,
                  ),
                  child: InteractiveViewer(
                    panEnabled: true,
                    minScale: 0.8,
                    maxScale: 4.0,
                    child: Center(
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Padding(
                            padding: EdgeInsets.all(40.0),
                            child: CircularProgressIndicator(color: AppColors.harvestAmber),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => const Padding(
                          padding: EdgeInsets.all(40.0),
                          child: Icon(Icons.broken_image_rounded, color: Colors.white60, size: 48),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: const BoxDecoration(
                  color: Color(0xEE1F2937),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                ),
                child: const Center(
                  child: Text(
                    "Pinch or drag to zoom",
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
