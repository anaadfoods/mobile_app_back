import 'dart:ui';
import 'package:grocery_app/common_widgets/global_import.dart';
import 'panchang_supporting_classes.dart';


class PanchangBackground extends StatelessWidget {
  final bool isDark;

  const PanchangBackground({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [AppColors.deepSoilGreen, const Color(0xFF3D6B28)]
                : [
                    Theme.of(context).scaffoldBackgroundColor,
                    Theme.of(context).scaffoldBackgroundColor,
                    Theme.of(context).scaffoldBackgroundColor,
                  ],
          ),
        ),
        child: CustomPaint(painter: BackgroundPatternPainter(isDark: isDark)),
      ),
    );
  }
}

class PanchangHeroHeader extends StatelessWidget {
  final DateTime selectedDate;
  final bool isDark;
  final VoidCallback onDateTap;

  const PanchangHeroHeader({
    super.key,
    required this.selectedDate,
    required this.isDark,
    required this.onDateTap,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppColors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: _buildHeaderBackground(context),
        title: null,
        collapseMode: CollapseMode.parallax,
      ),
      leading: _buildBackButton(context),
    );
  }

  Widget _buildHeaderBackground(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppColors.parchment.withAlpha(50),
                  AppColors.parchment.withAlpha(20),
                ]
              : [
                  AppColors.deepSoilGreen.withAlpha(25),
                  AppColors.deepSoilGreen.withAlpha(10),
                ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            AutoSizeText(
              'Panchang Calendar',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.pureWhite : AppColors.charcoal,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            _buildDateSelector(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector(BuildContext context) {
    return AnimatedScaleButton(
      onTap: onDateTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(
            alpha: 0.1,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: (isDark ? AppColors.pureWhite : AppColors.charcoal)
                .withValues(alpha: 0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: (isDark ? AppColors.pureWhite : AppColors.charcoal)
                  .withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 18,
              color: isDark ? AppColors.pureWhite : AppColors.charcoal,
            ),
            const SizedBox(width: 10),
            AutoSizeText(
              DateFormat('EEEE, d MMMM yyyy').format(selectedDate),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.parchment.withValues(alpha: 0.9)
                    : AppColors.charcoal,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: isDark
                  ? AppColors.pureWhite.withValues(alpha: 0.54)
                  : AppColors.charcoal54,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              context.go("/profile");
            },
            child: Container(
              decoration: BoxDecoration(
                color: (isDark ? AppColors.pureWhite : AppColors.charcoal)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: isDark ? AppColors.pureWhite : AppColors.charcoal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
