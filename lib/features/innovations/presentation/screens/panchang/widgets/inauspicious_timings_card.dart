import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:grocery_app/models/panchang/panchang_day_models.dart';
import 'panchang_info_dialogs.dart';

class InauspiciousTimingsCard extends StatefulWidget {
  final PanchangInauspiciousTimings timings;
  final bool isDark;

  const InauspiciousTimingsCard({
    super.key,
    required this.timings,
    required this.isDark,
  });

  @override
  State<InauspiciousTimingsCard> createState() => _InauspiciousTimingsCardState();
}

class _InauspiciousTimingsCardState extends State<InauspiciousTimingsCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;
  late final Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);

    _shimmerAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

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
    final hasRahuKaal = widget.timings.rahuKaal != null;
    final hasGulika = widget.timings.gulika != null;
    final hasYamaganda = widget.timings.yamaganda != null;

    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.rawEarth.withValues(
                  alpha: 0.3 * _shimmerAnimation.value,
                ),
                blurRadius: 15 + (10 * _shimmerAnimation.value),
                spreadRadius: 0,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: widget.isDark
                    ? [AppColors.darkSurface, AppColors.darkSurfaceElevated]
                    : [AppColors.deepSoilGreen, const Color(0xFF3A6B24)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.rawEarth.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.rawEarth,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.rawEarth.withValues(alpha: 0.5),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.warning_rounded,
                        color: widget.isDark
                            ? AppColors.pureWhite
                            : AppColors.parchment,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AutoSizeText(
                        'Inauspicious Timings ⚠️',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: widget.isDark
                              ? AppColors.pureWhite
                              : AppColors.parchment,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () =>
                          PanchangInfoDialogs.showInauspiciousInfoDialog(
                        context,
                        widget.isDark,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.rawEarth.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.info_outline_rounded,
                          color: AppColors.rawEarth,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                AutoSizeText(
                  'Tap ℹ️ to learn more • Avoid starting new work',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.pureWhite.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 16),
                if (hasRahuKaal) ...[
                  _buildInauspiciousTimeItem(
                    title: 'Rahu Kaal',
                    icon: Icons.dangerous_rounded,
                    startTime: _formatTime(widget.timings.rahuKaal!.start),
                    endTime: _formatTime(widget.timings.rahuKaal!.end),
                  ),
                  if (hasGulika || hasYamaganda) const SizedBox(height: 12),
                ],
                if (hasGulika) ...[
                  _buildInauspiciousTimeItem(
                    title: 'Gulika Kaal',
                    icon: Icons.block_rounded,
                    startTime: _formatTime(widget.timings.gulika!.start),
                    endTime: _formatTime(widget.timings.gulika!.end),
                  ),
                  if (hasYamaganda) const SizedBox(height: 12),
                ],
                if (hasYamaganda)
                  _buildInauspiciousTimeItem(
                    title: 'Yamaganda Kaal',
                    icon: Icons.report_problem_rounded,
                    startTime: _formatTime(widget.timings.yamaganda!.start),
                    endTime: _formatTime(widget.timings.yamaganda!.end),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInauspiciousTimeItem({
    required String title,
    required IconData icon,
    required String startTime,
    required String endTime,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.rawEarth,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: AutoSizeText(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.pureWhite,
            ),
          ),
        ),
        AutoSizeText(
          '$startTime - $endTime',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.rawEarth,
          ),
        ),
      ],
    );
  }

  /// Kept/preserved legacy unused method as per user instructions.
  Widget _buildRahuKaalCard(PanchangTimeWindow rahuKaal, bool isDark) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.rawEarth.withValues(
                  alpha: 0.3 * _shimmerAnimation.value,
                ),
                blurRadius: 15 + (10 * _shimmerAnimation.value),
                spreadRadius: 0,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [AppColors.darkSurface, AppColors.darkSurfaceElevated]
                    : [AppColors.deepSoilGreen, const Color(0xFF3A6B24)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.rawEarth.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.rawEarth,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.rawEarth.withValues(alpha: 0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.warning_rounded,
                    color: isDark ? AppColors.pureWhite : AppColors.parchment,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AutoSizeText(
                        'Rahu Kaal ⚠️',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.pureWhite : AppColors.rawEarth,
                        ),
                      ),
                      const SizedBox(height: 4),
                      AutoSizeText(
                        'Avoid starting new work',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.pureWhite.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      AutoSizeText(
                        '${_formatTime(rahuKaal.start)} - ${_formatTime(rahuKaal.end)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.rawEarth,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
