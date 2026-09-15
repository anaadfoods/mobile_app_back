import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:grocery_app/models/panchang/panchang_day_models.dart';
import 'panchang_info_dialogs.dart';

class InauspiciousTimingsCard extends StatelessWidget {
  final PanchangInauspiciousTimings timings;
  final bool isDark;

  const InauspiciousTimingsCard({
    super.key,
    required this.timings,
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
    final hasRahuKaal = timings.rahuKaal != null;
    final hasGulika = timings.gulika != null;
    final hasYamaganda = timings.yamaganda != null;

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
                  color: AppColors.softRed.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.softRed,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AutoSizeText(
                      'Inauspicious Timings (अशुभ समय)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.pureWhite : AppColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    AutoSizeText(
                      'Periods to avoid for starting auspicious deeds',
                      style: TextStyle(
                        fontSize: 11,
                        color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => PanchangInfoDialogs.showInauspiciousInfoDialog(context, isDark),
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
          if (hasRahuKaal) ...[
            _buildInauspiciousTimeItem(
              title: 'Rahu Kaal',
              hindiName: 'राहुकाल',
              startTime: _formatTime(timings.rahuKaal!.start),
              endTime: _formatTime(timings.rahuKaal!.end),
            ),
            if (hasGulika || hasYamaganda) const SizedBox(height: 10),
          ],
          if (hasGulika) ...[
            _buildInauspiciousTimeItem(
              title: 'Gulika Kaal',
              hindiName: 'गुलिक काल',
              startTime: _formatTime(timings.gulika!.start),
              endTime: _formatTime(timings.gulika!.end),
            ),
            if (hasYamaganda) const SizedBox(height: 10),
          ],
          if (hasYamaganda)
            _buildInauspiciousTimeItem(
              title: 'Yamaganda Kaal',
              hindiName: 'यमगण्ड काल',
              startTime: _formatTime(timings.yamaganda!.start),
              endTime: _formatTime(timings.yamaganda!.end),
            ),
        ],
      ),
    );
  }

  Widget _buildInauspiciousTimeItem({
    required String title,
    required String hindiName,
    required String startTime,
    required String endTime,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : AppColors.softCream,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.softRed,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.pureWhite : AppColors.charcoal,
                    ),
                  ),
                  TextSpan(
                    text: ' ($hindiName)',
                    style: TextStyle(
                      fontSize: 11,
                      color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.softRed.withValues(alpha: isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: AutoSizeText(
              '$startTime – $endTime',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.softRed,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
