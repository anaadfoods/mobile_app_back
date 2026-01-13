import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../common_widgets/error_state_widget.dart';
import '../../../cubits/panchang/panchang_vrat_cubit.dart';
import '../../../cubits/panchang/panchang_vrat_state.dart';
import '../../../models/panchang/panchang_vrat_models.dart';
import '../../../repositories/panchang_repository.dart';
import '../../../styles/colors.dart';

class PanchangVratCalendarScreen extends StatefulWidget {
  const PanchangVratCalendarScreen({super.key});

  @override
  State<PanchangVratCalendarScreen> createState() =>
      _PanchangVratCalendarScreenState();
}

class _PanchangVratCalendarScreenState extends State<PanchangVratCalendarScreen>
    with SingleTickerProviderStateMixin {
  late final PanchangVratCubit _cubit;
  late final AnimationController _animController;
  int _lastDays = 90;
  DateTimeRange? _lastRange;

  // Theme colors
  static const _gradientStart = Color(0xFF6B46C1);
  static const _gradientEnd = Color(0xFF9333EA);

  @override
  void initState() {
    super.initState();
    _cubit = PanchangVratCubit(repository: PanchangRepository());
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _loadNextDays(90);
  }

  @override
  void dispose() {
    _animController.dispose();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF8F9FC),
        body: BlocConsumer<PanchangVratCubit, PanchangVratState>(
          listener: (context, state) {
            if (state is PanchangVratSuccess) {
              _animController.forward(from: 0);
            }
          },
          builder: (context, state) {
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildSliverAppBar(isDark, state),
                if (state is PanchangVratLoading)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (state is PanchangVratError)
                  SliverFillRemaining(
                    child: ErrorStateWidget(
                      subtitle: state.message,
                      onRetry: _retryLastLoad,
                    ),
                  )
                else if (state is PanchangVratSuccess)
                  ..._buildSuccessContent(state, isDark),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(bool isDark, PanchangVratState state) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      stretch: true,
      backgroundColor: isDark ? const Color(0xFF0A0A0F) : Colors.white,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_gradientStart, _gradientEnd],
            ),
          ),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                top: -50,
                right: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
              Positioned(
                bottom: -30,
                left: -30,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
              // Content
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.self_improvement_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Vrat Calendar',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                if (state is PanchangVratSuccess)
                                  Text(
                                    _getRangeSubtitle(state.calendar),
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.85),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      if (state is PanchangVratSuccess)
                        _buildStatsRow(state.calendar),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => _pickDateRange(isDark),
          tooltip: 'Choose date range',
          icon: const Icon(Icons.date_range_rounded),
        ),
        IconButton(
          onPressed: () {
            HapticFeedback.mediumImpact();
            _loadNextDays(90);
          },
          tooltip: 'Next 90 days',
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    );
  }

  Widget _buildStatsRow(VratCalendarResponse calendar) {
    return Row(
      children: [
        _statChip(
          icon: Icons.event_available_rounded,
          label: '${calendar.count}',
          subtitle: 'Vrats',
        ),
        const SizedBox(width: 12),
        _statChip(
          icon: Icons.calendar_today_rounded,
          label: '${calendar.uniqueDatesCount}',
          subtitle: 'Days',
        ),
        const SizedBox(width: 12),
        _statChip(
          icon: Icons.schedule_rounded,
          label: '${calendar.days}',
          subtitle: 'Range',
        ),
      ],
    );
  }

  Widget _statChip({
    required IconData icon,
    required String label,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getRangeSubtitle(VratCalendarResponse calendar) {
    final start = _tryParseDate(calendar.start);
    final end = _tryParseDate(calendar.end);
    if (start != null && end != null) {
      return '${DateFormat('d MMM').format(start)} – ${DateFormat('d MMM y').format(end)}';
    }
    return '${calendar.start} – ${calendar.end}';
  }

  List<Widget> _buildSuccessContent(PanchangVratSuccess state, bool isDark) {
    final items = state.filteredItems;

    return [
      SliverToBoxAdapter(
        child: _buildFilters(state, isDark),
      ),
      if (items.isEmpty)
        SliverFillRemaining(child: _buildEmpty(isDark))
      else
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return AnimatedBuilder(
                  animation: _animController,
                  builder: (context, child) {
                    final delay = (index * 0.1).clamp(0.0, 0.5);
                    final animValue = Curves.easeOutCubic.transform(
                      ((_animController.value - delay) / (1 - delay)).clamp(0.0, 1.0),
                    );
                    return Transform.translate(
                      offset: Offset(0, 30 * (1 - animValue)),
                      child: Opacity(
                        opacity: animValue,
                        child: _buildVratCard(items[index], isDark, index),
                      ),
                    );
                  },
                );
              },
              childCount: items.length,
            ),
          ),
        ),
    ];
  }

  Widget _buildFilters(PanchangVratSuccess state, bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        children: [
          _buildFilterChip(
            label: 'All',
            icon: Icons.grid_view_rounded,
            selected: state.selectedImportance == null,
            onTap: () => _cubit.filterByImportance(null),
            isDark: isDark,
          ),
          _buildFilterChip(
            label: 'High',
            icon: Icons.priority_high_rounded,
            selected: state.selectedImportance == 'high',
            onTap: () => _cubit.filterByImportance('high'),
            isDark: isDark,
            color: AppColors.error,
          ),
          _buildFilterChip(
            label: 'Medium',
            icon: Icons.remove_rounded,
            selected: state.selectedImportance == 'medium',
            onTap: () => _cubit.filterByImportance('medium'),
            isDark: isDark,
            color: AppColors.warning,
          ),
          _buildFilterChip(
            label: 'Low',
            icon: Icons.keyboard_arrow_down_rounded,
            selected: state.selectedImportance == 'low',
            onTap: () => _cubit.filterByImportance('low'),
            isDark: isDark,
            color: AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
    required bool isDark,
    Color? color,
  }) {
    final chipColor = color ?? _gradientStart;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? chipColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: selected
                    ? Colors.white
                    : (isDark ? Colors.white54 : Colors.black45),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: selected
                      ? Colors.white
                      : (isDark ? Colors.white54 : Colors.black54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVratCard(VratItem vrat, bool isDark, int index) {
    final importanceColor = _importanceColor(vrat.importanceLower);
    final daysUntil = vrat.dateTime.difference(DateTime.now()).inDays;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showDetails(vrat, isDark);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isDark ? const Color(0xFF1A1A24) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: importanceColor.withValues(alpha: isDark ? 0.15 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Gradient accent on left
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        importanceColor,
                        importanceColor.withValues(alpha: 0.5),
                      ],
                    ),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildDateBadge(vrat.dateTime, importanceColor, isDark),
                        const SizedBox(width: 12),
                        if (daysUntil >= 0 && daysUntil <= 30)
                          _buildCountdownBadge(daysUntil, isDark),
                        const Spacer(),
                        _buildImportanceBadge(vrat.importanceLower, importanceColor, isDark),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      vrat.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (vrat.details != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        _metaLine(vrat.details!),
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white54 : Colors.black45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    if ((vrat.info?.description ?? '').isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        vrat.info!.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                    if (vrat.details != null) ...[
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _buildTimingChip(
                            Icons.wb_sunny_rounded,
                            'Sunrise',
                            _formatTime(vrat.details!.sunrise),
                            const Color(0xFFFF9500),
                            isDark,
                          ),
                          const SizedBox(width: 10),
                          _buildTimingChip(
                            Icons.nightlight_round,
                            'Sunset',
                            _formatTime(vrat.details!.sunset),
                            const Color(0xFF5856D6),
                            isDark,
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: importanceColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: importanceColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateBadge(DateTime date, Color color, bool isDark) {
    final isToday = _isToday(date);
    final isTomorrow = _isTomorrow(date);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            DateFormat('d').format(date),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          Text(
            isToday
                ? 'TODAY'
                : isTomorrow
                    ? 'TMRW'
                    : DateFormat('MMM').format(date).toUpperCase(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownBadge(int daysUntil, bool isDark) {
    String text;
    Color bgColor;

    if (daysUntil == 0) {
      text = '🎯 Today';
      bgColor = const Color(0xFF34C759);
    } else if (daysUntil == 1) {
      text = '⏰ Tomorrow';
      bgColor = const Color(0xFFFF9500);
    } else if (daysUntil <= 7) {
      text = '📅 $daysUntil days';
      bgColor = const Color(0xFF5856D6);
    } else {
      text = '$daysUntil days';
      bgColor = isDark ? Colors.white12 : Colors.black12;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: isDark ? 0.25 : 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: bgColor.withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : bgColor,
        ),
      ),
    );
  }

  Widget _buildImportanceBadge(String importance, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        importance.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildTimingChip(
    IconData icon,
    String label,
    String value,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white70 : color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _gradientStart.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.event_busy_rounded,
              size: 48,
              color: _gradientStart.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No Vrats Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or date range',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white54 : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: () => _loadNextDays(90),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reset Filters'),
            style: TextButton.styleFrom(
              foregroundColor: _gradientStart,
            ),
          ),
        ],
      ),
    );
  }

  void _showDetails(VratItem vrat, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _detailsSheet(vrat, isDark),
    );
  }

  Widget _detailsSheet(VratItem vrat, bool isDark) {
    final importanceColor = _importanceColor(vrat.importanceLower);
    final info = vrat.info;
    final observance = info?.observance;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, controller) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A24) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Gradient header
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [importanceColor, importanceColor.withValues(alpha: 0.7)],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.self_improvement_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                vrat.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('EEEE, MMMM d, y').format(vrat.dateTime),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (vrat.details != null) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _sheetTimingChip(Icons.wb_sunny_rounded, 'Sunrise',
                              _formatTime(vrat.details!.sunrise)),
                          const SizedBox(width: 10),
                          _sheetTimingChip(Icons.nightlight_round, 'Sunset',
                              _formatTime(vrat.details!.sunset)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Content
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (vrat.details != null) ...[
                      _buildInfoCard(
                        icon: Icons.calendar_month_rounded,
                        title: 'Details',
                        content: _metaLine(vrat.details!),
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if ((vrat.why ?? '').isNotEmpty) ...[
                      _buildInfoCard(
                        icon: Icons.info_outline_rounded,
                        title: 'Why This Day',
                        content: vrat.why!,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if ((info?.description ?? '').isNotEmpty) ...[
                      _buildInfoCard(
                        icon: Icons.article_outlined,
                        title: 'About',
                        content: info!.description,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if ((observance?.howToDoEn ?? '').isNotEmpty) ...[
                      _buildInfoCard(
                        icon: Icons.checklist_rounded,
                        title: 'How to Observe',
                        content: observance!.howToDoEn!,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if ((observance?.avoidEn ?? const []).isNotEmpty) ...[
                      _buildListCard(
                        icon: Icons.do_not_disturb_alt_rounded,
                        title: 'Things to Avoid',
                        items: observance!.avoidEn,
                        color: AppColors.error,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if ((observance?.allowedEn ?? const []).isNotEmpty) ...[
                      _buildListCard(
                        icon: Icons.check_circle_outline_rounded,
                        title: 'What\'s Allowed',
                        items: observance!.allowedEn,
                        color: AppColors.success,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if ((info?.paranRules?.notesEn ?? '').isNotEmpty) ...[
                      _buildInfoCard(
                        icon: Icons.restaurant_rounded,
                        title: 'Paran Rules',
                        content: info!.paranRules!.notesEn!,
                        isDark: isDark,
                        accentColor: const Color(0xFFFF9500),
                      ),
                      const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sheetTimingChip(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
    required bool isDark,
    Color? accentColor,
  }) {
    final color = accentColor ?? _gradientStart;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListCard({
    required IconData icon,
    required String title,
    required List<String> items,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  void _loadNextDays(int days) {
    _lastDays = days;
    _lastRange = null;
    _cubit.loadVrats(days: days);
  }

  void _loadRange(DateTimeRange range) {
    _lastRange = range;
    _cubit.loadVratsRange(start: range.start, end: range.end);
  }

  void _retryLastLoad() {
    final range = _lastRange;
    if (range != null) {
      _loadRange(range);
      return;
    }
    _loadNextDays(_lastDays);
  }

  Future<void> _pickDateRange(bool isDark) async {
    final now = DateTime.now();
    final current = context.read<PanchangVratCubit>().state;

    DateTimeRange? initialRange;
    if (current is PanchangVratSuccess) {
      final start = _tryParseDate(current.calendar.start);
      final end = _tryParseDate(current.calendar.end);
      if (start != null && end != null) {
        initialRange = DateTimeRange(start: start, end: end);
      }
    }

    initialRange ??= DateTimeRange(
      start: DateTime(now.year, now.month, now.day),
      end: DateTime(now.year, now.month, now.day).add(const Duration(days: 30)),
    );

    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: initialRange,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      builder: (context, child) {
        final base = Theme.of(context);
        return Theme(
          data: base.copyWith(
            colorScheme: base.colorScheme.copyWith(
              primary: _gradientStart,
              onPrimary: Colors.white,
              surface: isDark ? const Color(0xFF1A1A24) : Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;
    _loadRange(picked);
  }

  DateTime? _tryParseDate(String raw) {
    try {
      return DateTime.parse(raw);
    } catch (_) {
      return null;
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day;
  }

  Color _importanceColor(String importanceLower) {
    switch (importanceLower) {
      case 'high':
        return AppColors.error;
      case 'low':
        return AppColors.success;
      case 'medium':
      default:
        return AppColors.warning;
    }
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '--:--';
    return DateFormat('h:mm a').format(dt);
  }

  String _metaLine(VratDetails details) {
    final parts = <String>[];
    if ((details.paksha ?? '').isNotEmpty) parts.add('${details.paksha} Paksha');
    if ((details.masa ?? '').isNotEmpty) parts.add(details.masa!);
    if ((details.tithi ?? '').isNotEmpty) parts.add(details.tithi!);
    return parts.join(' • ');
  }
}

