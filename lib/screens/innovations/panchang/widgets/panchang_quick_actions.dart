import 'package:grocery_app/common_widgets/global_import.dart';
import 'panchang_supporting_classes.dart';
import '../panchang_month_screen.dart';
import '../panchang_festivals_screen.dart';
import '../panchang_vrat_calendar_screen.dart';
import '../panchang_guidance_screen.dart';

class PanchangQuickActions extends StatelessWidget {
  final bool isDark;

  const PanchangQuickActions({
    super.key,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 22,
              decoration: BoxDecoration(
                color: isDark ? AppColors.pureWhite : AppColors.deepSoilGreen,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            AutoSizeText(
              'Quick Navigation',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.pureWhite : AppColors.charcoal,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context: context,
                icon: Icons.calendar_view_month_rounded,
                label: 'Month\nCalendar',
                color: isDark ? AppColors.pureWhite : AppColors.deepSoilGreen,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PanchangMonthScreen(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                context: context,
                icon: Icons.celebration_rounded,
                label: 'All\nFestivals',
                color: AppColors.harvestAmber,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PanchangFestivalsScreen(),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context: context,
                icon: Icons.self_improvement_rounded,
                label: 'Vrat\nCalendar',
                color: isDark ? AppColors.pureWhite : AppColors.rawEarth,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PanchangVratCalendarScreen(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                context: context,
                icon: Icons.auto_awesome,
                label: 'Today\'s\nGuidance',
                color: AppColors.warmGold,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PanchangGuidanceScreen(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return AnimatedScaleButton(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        height: 120,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: isDark ? 0.3 : 0.2),
              color.withValues(alpha: isDark ? 0.2 : 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: isDark ? 0.35 : 0.18),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.35),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: color.withValues(alpha: 0.5),
                  size: 14,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Align(
                alignment: Alignment.bottomLeft,
                child: AutoSizeText(
                  label,
                  maxLines: 2,
                  minFontSize: 9,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.pureWhite : AppColors.charcoal,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
