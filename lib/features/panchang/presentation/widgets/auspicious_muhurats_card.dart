import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:grocery_app/models/panchang/panchang_day_models.dart';
import 'panchang_info_dialogs.dart';

class AuspiciousMuhuratsCard extends StatelessWidget {
  final PanchangAuspiciousMuhurats muhurats;
  final bool isDark;

  const AuspiciousMuhuratsCard({
    super.key,
    required this.muhurats,
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
                  color: AppColors.deepSoilGreen.withValues(alpha: isDark ? 0.25 : 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.deepSoilGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AutoSizeText(
                      'Auspicious Muhurats (शुभ मुहूर्त)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.pureWhite : AppColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    AutoSizeText(
                      'Best windows for success & prosperity',
                      style: TextStyle(
                        fontSize: 11,
                        color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => PanchangInfoDialogs.showAuspiciousInfoDialog(context, isDark),
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
          if (muhurats.abhijit != null)
            _buildMuhuratItem(
              title: 'Abhijit Muhurat',
              subtitle: 'Ideal for important activities and new ventures',
              startTime: _formatTime(muhurats.abhijit!.start),
              endTime: _formatTime(muhurats.abhijit!.end),
              icon: Icons.star_rounded,
              accentColor: AppColors.harvestAmber,
            ),
          if (muhurats.abhijit != null && muhurats.brahma != null)
            const SizedBox(height: 10),
          if (muhurats.brahma != null)
            _buildMuhuratItem(
              title: 'Brahma Muhurat',
              subtitle: 'Ideal for meditation, yoga & spiritual study',
              startTime: _formatTime(muhurats.brahma!.start),
              endTime: _formatTime(muhurats.brahma!.end),
              icon: Icons.self_improvement_rounded,
              accentColor: AppColors.deepSoilGreen,
            ),
        ],
      ),
    );
  }

  Widget _buildMuhuratItem({
    required String title,
    required String subtitle,
    required String startTime,
    required String endTime,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
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
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: isDark ? 0.2 : 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: accentColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AutoSizeText(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.pureWhite : AppColors.charcoal,
                  ),
                ),
                const SizedBox(height: 2),
                AutoSizeText(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.deepSoilGreen.withValues(alpha: isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: AutoSizeText(
              '$startTime – $endTime',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.deepSoilGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
