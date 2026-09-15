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
        color: isDark ? AppColors.darkCanvas : AppColors.parchment,
        child: CustomPaint(painter: BackgroundPatternPainter(isDark: isDark)),
      ),
    );
  }
}

class PanchangHeroHeader extends StatelessWidget {
  final DateTime selectedDate;
  final bool isDark;
  final VoidCallback onDateTap;
  final VoidCallback? onPreviousDay;
  final VoidCallback? onNextDay;
  final String locationLabel;

  const PanchangHeroHeader({
    super.key,
    required this.selectedDate,
    required this.isDark,
    required this.onDateTap,
    this.onPreviousDay,
    this.onNextDay,
    this.locationLabel = 'New Delhi, India (28.61° N, 77.21° E)',
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: isDark ? AppColors.darkCanvas : AppColors.parchment,
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
      color: isDark ? AppColors.darkCanvas : AppColors.parchment,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AutoSizeText(
                  'Vedic Panchang',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.pureWhite : AppColors.charcoal,
                    letterSpacing: -0.5,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: (isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen).withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        size: 12,
                        color: isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'NASA JPL DE421',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 13,
                  color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.6),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    locationLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildDateSelectorWithArrows(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelectorWithArrows(BuildContext context) {
    return Row(
      children: [
        if (onPreviousDay != null)
          IconButton(
            icon: Icon(
              Icons.chevron_left_rounded,
              color: isDark ? AppColors.pureWhite : AppColors.charcoal,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              onPreviousDay!();
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Previous Day',
          ),
        const SizedBox(width: 6),
        Expanded(
          child: _buildDateSelector(context),
        ),
        const SizedBox(width: 6),
        if (onNextDay != null)
          IconButton(
            icon: Icon(
              Icons.chevron_right_rounded,
              color: isDark ? AppColors.pureWhite : AppColors.charcoal,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              onNextDay!();
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Next Day',
          ),
      ],
    );
  }

  Widget _buildDateSelector(BuildContext context) {
    return AnimatedScaleButton(
      onTap: onDateTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.pureWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.08),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 16,
              color: isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: AutoSizeText(
                DateFormat('EEE, d MMM yyyy').format(selectedDate),
                maxLines: 1,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.pureWhite : AppColors.charcoal,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          context.go("/profile");
        },
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.pureWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? AppColors.pureWhite : AppColors.charcoal,
            size: 20,
          ),
        ),
      ),
    );
  }
}
