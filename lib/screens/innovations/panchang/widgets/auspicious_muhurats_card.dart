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
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : AppColors.pureWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? AppColors.harvestAmber40
              : AppColors.harvestAmber.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.parchment.withValues(alpha: 0.12),
            blurRadius: 10,
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
                  gradient: LinearGradient(
                    colors: isDark
                        ? [AppColors.darkSurface, AppColors.darkSurfaceElevated]
                        : [
                            AppColors.deepSoilGreen,
                            const Color(0xFF3A6B24),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: isDark ? AppColors.pureWhite : AppColors.parchment,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AutoSizeText(
                  'Auspicious Times',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.pureWhite : AppColors.charcoal,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => PanchangInfoDialogs.showAuspiciousInfoDialog(
                  context,
                  isDark,
                ),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.charcoal.withValues(alpha: 0.5)
                        : AppColors.deepSoilGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.info_outline_rounded,
                    color: isDark
                        ? AppColors.harvestAmber
                        : AppColors.deepSoilGreen,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          AutoSizeText(
            'Tap ℹ️ to learn more about auspicious muhurats',
            style: TextStyle(
              fontSize: 12,
              color: (isDark ? AppColors.pureWhite : AppColors.charcoal)
                  .withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 12),
          if (muhurats.abhijit != null)
            _buildMuhuratItem(
              title: 'Abhijit Muhurat',
              subtitle: 'Best time for important work',
              startTime: _formatTime(muhurats.abhijit!.start),
              endTime: _formatTime(muhurats.abhijit!.end),
              icon: Icons.star,
              color: AppColors.harvestAmber,
              theme: theme,
            ),
          if (muhurats.abhijit != null && muhurats.brahma != null)
            const SizedBox(height: 12),
          if (muhurats.brahma != null)
            _buildMuhuratItem(
              title: 'Brahma Muhurat',
              subtitle: 'Ideal for meditation & study',
              startTime: _formatTime(muhurats.brahma!.start),
              endTime: _formatTime(muhurats.brahma!.end),
              icon: Icons.self_improvement,
              color: AppColors.parchment,
              theme: theme,
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
    required Color color,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AutoSizeText(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.pureWhite : AppColors.charcoal,
                  ),
                ),
                AutoSizeText(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: (isDark ? AppColors.pureWhite : AppColors.charcoal)
                        .withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          AutoSizeText(
            '$startTime - $endTime',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
