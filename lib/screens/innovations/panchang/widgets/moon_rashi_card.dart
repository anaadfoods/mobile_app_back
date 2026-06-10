import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:grocery_app/models/panchang/panchang_day_models.dart';
import 'panchang_info_dialogs.dart';

class MoonRashiCard extends StatelessWidget {
  final PanchangSunMoonTimings timings;
  final PanchangCorePanchang corePanchang;
  final bool isDark;

  const MoonRashiCard({
    super.key,
    required this.timings,
    required this.corePanchang,
    required this.isDark,
  });

  String _formatTime(DateTime? time) {
    if (time == null) return '--:--';
    final localTime = time.toLocal();
    final hour = localTime.hour;
    final minute = localTime.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$hour12:${minute.toString().padLeft(2, '0')} $period';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [AppColors.darkSurface, AppColors.darkSurfaceElevated]
              : [AppColors.deepSoilGreen, const Color(0xFF3A6B24)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isDark ? AppColors.parchment : AppColors.deepSoilGreen)
              .withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.parchment,
                      blurRadius: 14,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.nightlight_round,
                  color: AppColors.pureWhite,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AutoSizeText(
                  'Moon & Rashi Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.pureWhite : AppColors.charcoal,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => PanchangInfoDialogs.showMoonRashiInfoDialog(
                  context,
                  isDark,
                ),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.parchment.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.info_outline_rounded,
                    color: isDark ? AppColors.pureWhite : AppColors.charcoal,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          AutoSizeText(
            'Tap ℹ️ to learn about Moon phases & Rashi',
            style: TextStyle(
              fontSize: 12,
              color: (isDark ? AppColors.pureWhite : AppColors.charcoal)
                  .withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMoonInfoItem(
                  'Moonrise',
                  _formatTime(timings.moonrise),
                  Icons.arrow_upward,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMoonInfoItem(
                  'Moonset',
                  _formatTime(timings.moonset),
                  Icons.arrow_downward,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMoonInfoItem(
                  'Sun Rashi',
                  corePanchang.sunRashi,
                  Icons.wb_sunny,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMoonInfoItem(
                  'Moon Rashi',
                  corePanchang.moonRashi,
                  Icons.nightlight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMoonInfoItem(
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.pureWhite.withValues(
          alpha: 0.1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: AppColors.pureWhite,
            size: 20,
          ),
          const SizedBox(height: 4),
          AutoSizeText(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.pureWhite.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 2),
          AutoSizeText(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.pureWhite,
            ),
          ),
        ],
      ),
    );
  }
}
