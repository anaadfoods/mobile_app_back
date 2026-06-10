import 'package:grocery_app/common_widgets/global_import.dart';

class ViewDetailsButton extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;

  const ViewDetailsButton({
    super.key,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [AppColors.darkSurface, AppColors.darkSurfaceElevated]
                : [AppColors.deepSoilGreen, const Color(0xFF3A6B24)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.parchment.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: (isDark ? AppColors.parchment : AppColors.deepSoilGreen)
                .withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.parchment.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.access_time_filled,
                color: isDark ? AppColors.pureWhite : AppColors.parchment,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AutoSizeText(
                    'View Advanced Timings',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.pureWhite : AppColors.parchment,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AutoSizeText(
                    'Hora, Choghadiya & Transitions',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.pureWhite.withValues(alpha: 0.7)
                          : AppColors.parchment.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: isDark ? AppColors.pureWhite : AppColors.parchment,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
