import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:grocery_app/models/panchang/panchang_day_models.dart';
import 'panchang_supporting_classes.dart';
import 'panchang_info_dialogs.dart';

class PanchangGridCard extends StatelessWidget {
  final PanchangDayResponse day;
  final DateTime selectedDate;
  final PanchangLunarInfo lunar;
  final bool isDark;

  const PanchangGridCard({
    super.key,
    required this.day,
    required this.selectedDate,
    required this.lunar,
    required this.isDark,
  });

  String _formatEndTime(DateTime? end) {
    if (end == null) return '';
    final local = end.toLocal();
    final hour =
        local.hour == 0 ? 12 : (local.hour > 12 ? local.hour - 12 : local.hour);
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return 'Until $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday =
        selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;

    final dateText =
        isToday
            ? 'Today\'s Panchang'
            : 'Panchang - ${DateFormat('d MMM yyyy').format(selectedDate)}';

    final panchangItems = [
      PanchangItemData(
        'Tithi',
        day.corePanchang.tithi,
        Icons.brightness_3,
        AppColors.harvestAmber,
        _formatEndTime(day.corePanchang.tithiEnd),
      ),
      PanchangItemData(
        'Nakshatra',
        day.corePanchang.nakshatra,
        Icons.stars_rounded,
        AppColors.deepSoilGreen,
        _formatEndTime(day.corePanchang.nakshatraEnd),
      ),
      PanchangItemData(
        'Yoga',
        day.corePanchang.yoga,
        Icons.self_improvement_rounded,
        AppColors.rawEarth,
        _formatEndTime(day.corePanchang.yogaEnd),
      ),
      PanchangItemData(
        'Karana',
        day.corePanchang.karana,
        Icons.change_history_rounded,
        AppColors.harvestAmber,
        _formatEndTime(day.corePanchang.karanaEnd),
      ),
      PanchangItemData(
        'Vara',
        day.corePanchang.vara,
        Icons.wb_sunny_rounded,
        AppColors.deepSoilGreen,
        'वार',
      ),
      PanchangItemData(
        'Paksha',
        lunar.paksha,
        Icons.brightness_2_rounded,
        AppColors.rawEarth,
        'पक्ष',
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
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const AutoSizeText(
                    '🕉️',
                    style: TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AutoSizeText(
                        dateText,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.pureWhite : AppColors.charcoal,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          if (lunar.masa.isNotEmpty)
                            GestureDetector(
                              onTap: () => PanchangInfoDialogs.showMasaInfoDialog(
                                context,
                                lunar.masa,
                                isDark,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkSurfaceElevated : AppColors.softCream,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.06),
                                  ),
                                ),
                                child: Text(
                                  '📅 ${lunar.masa}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppColors.harvestAmber : AppColors.charcoal,
                                  ),
                                ),
                              ),
                            ),
                          if (lunar.paksha.isNotEmpty)
                            GestureDetector(
                              onTap: () => PanchangInfoDialogs.showPakshaInfoDialog(
                                context,
                                lunar.paksha,
                                isDark,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkSurfaceElevated : AppColors.softCream,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.06),
                                  ),
                                ),
                                child: Text(
                                  '🌓 ${lunar.paksha}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppColors.harvestAmber : AppColors.charcoal,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => PanchangInfoDialogs.showPanchangInfoDialog(context, isDark),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.info_outline_rounded,
                      color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.6),
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.45,
              ),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: panchangItems.length,
              itemBuilder: (context, index) {
                final item = panchangItems[index];
                return _buildPanchangItem(item, isDark);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPanchangItem(PanchangItemData item, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : AppColors.softCream,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  item.icon,
                  color: item.color,
                  size: 16,
                ),
              ),
              if (item.secondaryLabel.isNotEmpty)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: AutoSizeText(
                      item.secondaryLabel,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      minFontSize: 8,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AutoSizeText(
                item.label,
                maxLines: 1,
                minFontSize: 9,
                style: TextStyle(
                  fontSize: 11,
                  color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              AutoSizeText(
                item.value.isEmpty ? '—' : item.value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.pureWhite : AppColors.charcoal,
                ),
                maxLines: 1,
                minFontSize: 10,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
