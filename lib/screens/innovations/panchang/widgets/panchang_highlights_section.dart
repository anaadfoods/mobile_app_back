import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:grocery_app/models/panchang/panchang_highlights_models.dart';
import '../panchang_festivals_screen.dart';

class PanchangHighlightsSection extends StatelessWidget {
  final PanchangHighlightsResponse highlights;
  final bool isDark;

  const PanchangHighlightsSection({
    super.key,
    required this.highlights,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final upcomingHighlights =
        highlights.items.where((item) => item.isUpcoming).take(5).toList();

    if (upcomingHighlights.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.parchment.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.celebration_rounded,
                    size: 16,
                    color: isDark ? AppColors.pureWhite : AppColors.deepSoilGreen,
                  ),
                ),
                const SizedBox(width: 10),
                AutoSizeText(
                  'Upcoming Festivals',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.pureWhite : AppColors.charcoal,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PanchangFestivalsScreen(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.deepSoilGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: AutoSizeText(
                  'View All',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.pureWhite : AppColors.deepSoilGreen,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: upcomingHighlights.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              return _buildHighlightItem(context, upcomingHighlights[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHighlightItem(BuildContext context, HighlightItem highlight) {
    final dateParts = highlight.formattedDate.split(' ');
    final day = dateParts.length > 1 ? dateParts[1] : '';
    final month = dateParts.isNotEmpty ? dateParts[0] : '';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PanchangFestivalsScreen()),
        );
      },
      child: Container(
        width: 130,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [AppColors.darkSurface, AppColors.darkSurfaceElevated]
                : [AppColors.deepSoilGreen, const Color(0xFF3A6B24)],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFFFB020).withValues(
              alpha: isDark ? 0.25 : 0.3,
            ),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFB020).withValues(
                alpha: isDark ? 0.08 : 0.12,
              ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [AppColors.darkSurface, AppColors.darkSurfaceElevated]
                          : [
                              AppColors.deepSoilGreen,
                              const Color(0xFF3A6B24),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: AutoSizeText(
                    day,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: isDark ? AppColors.pureWhite : AppColors.parchment,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                AutoSizeText(
                  month,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.pureWhite.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: AutoSizeText(
                highlight.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.pureWhite : AppColors.charcoal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
