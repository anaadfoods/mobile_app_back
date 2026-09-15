import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:grocery_app/models/panchang/panchang_day_models.dart';

class SunMoonTimelineCard extends StatelessWidget {
  final PanchangSunMoonTimings timings;
  final bool isDark;

  const SunMoonTimelineCard({
    super.key,
    required this.timings,
    required this.isDark,
  });

  String _formatTime(dynamic time) {
    if (time is String) {
      try {
        final parts = time.split(':');
        if (parts.length >= 2) {
          final hour = int.parse(parts[0]);
          final minute = int.parse(parts[1]);
          final period = hour >= 12 ? 'PM' : 'AM';
          final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
          return '$hour12:${minute.toString().padLeft(2, '0')} $period';
        }
      } catch (_) {
        return time;
      }
      return time;
    }
    if (time is DateTime) {
      final indianTime = time.toLocal();
      final hour = indianTime.hour;
      final minute = indianTime.minute;
      final period = hour >= 12 ? 'PM' : 'AM';
      final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      return '$hour12:${minute.toString().padLeft(2, '0')} $period';
    }
    return '--:--';
  }

  @override
  Widget build(BuildContext context) {
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
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTimeItem(
                  icon: Icons.wb_sunny_rounded,
                  iconColor: AppColors.harvestAmber,
                  label: 'Sunrise (सूर्योदय)',
                  time: _formatTime(timings.sunrise),
                ),
                Container(
                  height: 48,
                  width: 1,
                  color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.1),
                ),
                _buildTimeItem(
                  icon: Icons.nights_stay_rounded,
                  iconColor: AppColors.deepSoilGreen,
                  label: 'Sunset (सूर्यास्त)',
                  time: _formatTime(timings.sunset),
                ),
              ],
            ),
            if (timings.solarNoon != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceElevated : AppColors.softCream,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.06),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.wb_sunny_outlined,
                      color: AppColors.harvestAmber,
                      size: 15,
                    ),
                    const SizedBox(width: 6),
                    AutoSizeText(
                      'Solar Noon: ${_formatTime(timings.solarNoon)}',
                      style: TextStyle(
                        color: isDark ? AppColors.pureWhite : AppColors.charcoal,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String time,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: isDark ? 0.2 : 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        AutoSizeText(
          label,
          style: TextStyle(
            color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.6),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        AutoSizeText(
          time,
          style: TextStyle(
            color: isDark ? AppColors.pureWhite : AppColors.charcoal,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
