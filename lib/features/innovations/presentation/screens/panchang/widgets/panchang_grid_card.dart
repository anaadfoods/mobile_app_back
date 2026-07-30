import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:grocery_app/models/panchang/panchang_day_models.dart';
import 'panchang_supporting_classes.dart';
import 'panchang_info_dialogs.dart';

class PanchangGridCard extends StatefulWidget {
  final PanchangDayResponse day;
  final DateTime selectedDate;
  final PanchangLunarInfo lunar;
  final bool isDark;

  const PanchangGridCard({
    super.key,
    required this.day,
    required this.selectedDate,
    required this.lunar,
    required this.isDark,
  });


  @override
  State<PanchangGridCard> createState() => _PanchangGridCardState();
}

class _PanchangGridCardState extends State<PanchangGridCard>
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

  String _formatEndTime(DateTime? end) {
    if (end == null) return '';
    final local = end.toLocal();
    final hour =
        local.hour == 0 ? 12 : (local.hour > 12 ? local.hour - 12 : local.hour);
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return 'Until $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday = widget.selectedDate.year == now.year &&
        widget.selectedDate.month == now.month &&
        widget.selectedDate.day == now.day;

    final dateText = isToday
        ? 'Today\'s Panchang'
        : 'Panchang - ${DateFormat('d MMM yyyy').format(widget.selectedDate)}';

    final panchangItems = [
      PanchangItemData(
        'Tithi',
        widget.day.corePanchang.tithi,
        Icons.brightness_3,
        widget.isDark ? AppColors.parchment : AppColors.harvestAmber,
        _formatEndTime(widget.day.corePanchang.tithiEnd),
      ),
      PanchangItemData(
        'Nakshatra',
        widget.day.corePanchang.nakshatra,
        Icons.stars_rounded,
        widget.isDark ? AppColors.parchment : AppColors.deepSoilGreen,
        _formatEndTime(widget.day.corePanchang.nakshatraEnd),
      ),
      PanchangItemData(
        'Yoga',
        widget.day.corePanchang.yoga,
        Icons.self_improvement_rounded,
        widget.isDark ? AppColors.parchment : AppColors.rawEarth,
        _formatEndTime(widget.day.corePanchang.yogaEnd),
      ),
      PanchangItemData(
        'Karana',
        widget.day.corePanchang.karana,
        Icons.change_history_rounded,
        widget.isDark ? AppColors.parchment : AppColors.harvestAmber,
        _formatEndTime(widget.day.corePanchang.karanaEnd),
      ),
      PanchangItemData(
        'Vara',
        widget.day.corePanchang.vara,
        Icons.wb_sunny_rounded,
        widget.isDark ? AppColors.parchment : AppColors.deepSoilGreen,
        'वार',
      ),
      PanchangItemData(
        'Paksha',
        widget.day.lunar.paksha,
        Icons.brightness_2_rounded,
        widget.isDark ? AppColors.parchment : AppColors.rawEarth,
        'पक्ष',
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: widget.isDark
                ? AppColors.charcoal.withValues(alpha: 0.4)
                : AppColors.parchment.withValues(alpha: 0.15),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.isDark
                  ? [AppColors.darkSurface, AppColors.darkSurfaceElevated]
                  : [AppColors.deepSoilGreen, const Color(0xFF3A6B24)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -30,
                right: -30,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.parchment.withValues(
                          alpha: widget.isDark ? 0.2 : 0.1,
                        ),
                        AppColors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -20,
                left: -20,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF6B4226).withValues(
                          alpha: widget.isDark ? 0.15 : 0.08,
                        ),
                        AppColors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AnimatedBuilder(
                          animation: _shimmerAnimation,
                          builder: (context, child) {
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.parchment,
                                    AppColors.parchment,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.parchment.withValues(
                                      alpha:
                                          0.4 + (0.2 * _shimmerAnimation.value),
                                    ),
                                    blurRadius: 15,
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                              child: const AutoSizeText(
                                '🕉️',
                                style: TextStyle(fontSize: 24),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AutoSizeText(
                                dateText,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.parchment,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  if (widget.lunar.masa.isNotEmpty)
                                    GestureDetector(
                                      onTap: () =>
                                          PanchangInfoDialogs.showMasaInfoDialog(
                                        context,
                                        widget.lunar.masa,
                                        widget.isDark,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              const Color(0xFF2C4A1E).withValues(
                                                alpha: widget.isDark ? 0.3 : 0.15,
                                              ),
                                              const Color(0xFF6B4226).withValues(
                                                alpha: widget.isDark ? 0.2 : 0.1,
                                              ),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: const Color(0xFF2C4A1E)
                                                .withValues(alpha: 0.3),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            AutoSizeText(
                                              '📅 ${widget.lunar.masa}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: widget.isDark
                                                    ? const Color(0xFFF0D78C)
                                                    : const Color(0xFFC9943A),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(
                                              Icons.touch_app_rounded,
                                              size: 12,
                                              color: widget.isDark
                                                  ? const Color(0xFFF0D78C)
                                                      .withValues(alpha: 0.6)
                                                  : const Color(0xFFC9943A)
                                                      .withValues(alpha: 0.6),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  if (widget.lunar.paksha.isNotEmpty)
                                    GestureDetector(
                                      onTap: () =>
                                          PanchangInfoDialogs.showPakshaInfoDialog(
                                        context,
                                        widget.lunar.paksha,
                                        widget.isDark,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: widget.lunar.paksha
                                                  .toLowerCase()
                                                  .contains('krishna')
                                              ? const Color(0xFF2C4A1E)
                                                  .withValues(
                                                  alpha: widget.isDark ? 0.3 : 0.15,
                                                )
                                              : const Color(0xFFC9943A)
                                                  .withValues(
                                                  alpha: widget.isDark ? 0.3 : 0.15,
                                                ),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: widget.lunar.paksha
                                                    .toLowerCase()
                                                    .contains('krishna')
                                                ? const Color(0xFF2C4A1E)
                                                    .withValues(alpha: 0.3)
                                                : const Color(0xFFC9943A)
                                                    .withValues(alpha: 0.3),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            AutoSizeText(
                                              widget.lunar.paksha
                                                      .toLowerCase()
                                                      .contains('krishna')
                                                  ? '🌑 ${widget.lunar.paksha}'
                                                  : '🌕 ${widget.lunar.paksha}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: widget.lunar.paksha
                                                        .toLowerCase()
                                                        .contains('krishna')
                                                    ? (widget.isDark
                                                        ? const Color(0xFFE8C362)
                                                        : const Color(0xFF2C4A1E))
                                                    : (widget.isDark
                                                        ? const Color(0xFFF0D78C)
                                                        : const Color(0xFF6B4226)),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(
                                              Icons.touch_app_rounded,
                                              size: 12,
                                              color: widget.lunar.paksha
                                                      .toLowerCase()
                                                      .contains('krishna')
                                                  ? (widget.isDark
                                                      ? const Color(0xFFE8C362)
                                                          .withValues(alpha: 0.6)
                                                      : const Color(0xFF2C4A1E)
                                                          .withValues(alpha: 0.6))
                                                  : (widget.isDark
                                                      ? const Color(0xFFF0D78C)
                                                          .withValues(alpha: 0.6)
                                                      : const Color(0xFF6B4226)
                                                          .withValues(alpha: 0.6)),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => PanchangInfoDialogs.showPanchangInfoDialog(
                            context,
                            widget.isDark,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: widget.isDark
                                  ? AppColors.parchment.withValues(alpha: 0.1)
                                  : const Color(0xFF2C4A1E).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.parchment.withValues(alpha: 0.2),
                              ),
                            ),
                            child: const Icon(
                              Icons.info_outline_rounded,
                              color: AppColors.parchment,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1.35,
                      ),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: panchangItems.length,
                      itemBuilder: (context, index) {
                        final item = panchangItems[index];
                        return _buildPanchangItem(item, widget.isDark, index);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPanchangItem(PanchangItemData item, bool isDark, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 80)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    item.color.withValues(alpha: 0.25),
                    item.color.withValues(alpha: 0.1),
                  ]
                : [
                    item.color.withValues(alpha: 0.12),
                    item.color.withValues(alpha: 0.05),
                  ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: item.color.withValues(alpha: isDark ? 0.4 : 0.25),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: item.color.withValues(alpha: isDark ? 0.2 : 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: isDark ? 0.3 : 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    item.icon,
                    color: isDark ? item.color.withValues(alpha: 0.9) : item.color,
                    size: 18,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: AutoSizeText(
                      item.secondaryLabel,
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      minFontSize: 8,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? item.color.withValues(alpha: 0.8)
                            : item.color.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AutoSizeText(
                    item.label,
                    maxLines: 1,
                    minFontSize: 9,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.pureWhite.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AutoSizeText(
                    item.value.isEmpty ? '—' : item.value,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.parchment : AppColors.pureWhite,
                    ),
                    maxLines: 2,
                    minFontSize: 10,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
