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
                  Icons.nightlight_round,
                  color: isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AutoSizeText(
                      'Moon & Rashi Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.pureWhite : AppColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    AutoSizeText(
                      'Lunar Position, Moonrise & Zodiac Signs',
                      style: TextStyle(
                        fontSize: 11,
                        color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => PanchangInfoDialogs.showMoonRashiInfoDialog(context, isDark),
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
                  Icons.wb_sunny_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMoonInfoItem(
                  'Moon Rashi',
                  corePanchang.moonRashi,
                  Icons.nightlight_round,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMoonInfoItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : AppColors.softCream,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen,
            size: 18,
          ),
          const SizedBox(height: 4),
          AutoSizeText(
            label,
            style: TextStyle(
              fontSize: 11,
              color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          AutoSizeText(
            value.isEmpty ? '—' : value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.pureWhite : AppColors.charcoal,
            ),
          ),
        ],
      ),
    );
  }
}
