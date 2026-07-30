import 'package:grocery_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:grocery_app/service_locator.dart';
import 'package:grocery_app/common_widgets/error_state_widget.dart';
import 'package:grocery_app/features/innovations/presentation/cubit/panchang_vrat_cubit.dart';
import 'package:grocery_app/features/innovations/presentation/cubit/panchang_vrat_state.dart';
import 'package:grocery_app/models/panchang/panchang_vrat_models.dart';
import 'package:grocery_app/repositories/panchang_repository.dart';
import 'package:grocery_app/styles/colors.dart';

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
  late final ScrollController _scrollController;
  int _lastDays = 90;
  DateTimeRange? _lastRange;
  bool _isHindi = false;

  DateTime _focusedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );
  DateTime? _selectedDate;

  // Caches (performance)
  DateTime _cachedMonthStart = DateTime(0);
  List<DateTime> _cachedMonthDays = const [];
  List<String> _cachedMonthDayKeys = const [];

  List<VratItem>? _cachedCountsSourceItems;
  Map<String, int> _cachedVratCounts = <String, int>{};

  List<VratItem>? _cachedFilteredSourceItems;
  String? _cachedFilteredImportance;
  List<VratItem> _cachedFilteredItems = const [];

  List<VratItem>? _cachedItemsByDateSourceItems;
  String? _cachedItemsByDateImportance;
  Map<String, List<VratItem>> _cachedItemsByDate = <String, List<VratItem>>{};

  // Theme colors
  static const _gradientStart = AppColors.deepSoilGreen;
  static const _gradientEnd = Color(0xFF3D6B28); // successGreen variant

  static final DateFormat _dateKeyFormat = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    _cubit = PanchangVratCubit(repository: getIt<PanchangRepository>());
    _scrollController = ScrollController();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _loadNextDays(90);
  }

  @override
  void dispose() {
    _animController.dispose();
    _scrollController.dispose();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.pureBlack : AppColors.parchment,
        body: BlocConsumer<PanchangVratCubit, PanchangVratState>(
          listener: (context, state) {
            if (state is PanchangVratSuccess) {
              _animController.forward(from: 0);
              _ensureSelectedDateInRange(state.calendar);
            }
          },
          builder: (context, state) {
            return CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildSliverAppBar(isDark, state),
                if (state is PanchangVratSuccess)
                  _buildPinnedNextUpcoming(state, isDark),
                if (state is PanchangVratSuccess)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                      child: _buildMonthCalendar(state, isDark),
                    ),
                  ),
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
    const expandedHeight = 200.0;

    return SliverAppBar(
      expandedHeight: expandedHeight,
      pinned: true,
      stretch: true,
      backgroundColor:
          AppColors.deepSoilGreen,
      foregroundColor: AppColors.parchment,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: LayoutBuilder(
          builder: (context, constraints) {
            final maxH = constraints.maxHeight;
            final t = ((maxH - kToolbarHeight) /
                    (expandedHeight - kToolbarHeight))
                .clamp(0.0, 1.0);
            final showSubtitle = t > 0.55;
            final showStats = t > 0.70;
            final topPadding = 14 + (56 - 14) * t;

            return Container(
              decoration: BoxDecoration(
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
                        color: AppColors.parchment.withValues(alpha: 0.1),
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
                        color: AppColors.parchment.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                  // Content (must adapt while collapsing to avoid RenderFlex overflow)
                  SafeArea(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, topPadding, 20, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.parchment.withValues(
                                    alpha: 0.2,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.self_improvement_rounded,
                                  color: isDark ? AppColors.pureWhite : AppColors.parchment,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AutoSizeText(
                                      _isHindi
                                          ? 'व्रत कैलेंडर'
                                          : 'Vrat Calendar',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style:       TextStyle(
                                        color: isDark ? AppColors.pureWhite : AppColors.parchment,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    if (showSubtitle &&
                                        state is PanchangVratSuccess)
                                      AutoSizeText(
                                        _getRangeSubtitle(state.calendar),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: AppColors.parchment.withValues(
                                            alpha: 0.85,
                                          ),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (showStats && state is PanchangVratSuccess) ...[
                            const Spacer(),
                            _buildStatsRow(state.calendar),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      actions: [
        // Language toggle
        Container(
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            color: AppColors.parchment.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _isHindi = !_isHindi);
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: AutoSizeText(
                _isHindi ? 'अ' : 'EN',
                style:       TextStyle(
                  color: isDark ? AppColors.pureWhite : AppColors.parchment,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: () => _pickDateRange(isDark),
          tooltip: 'Choose date range',
          icon: Icon(Icons.date_range_rounded),
        ),
        IconButton(
          onPressed: () {
            HapticFeedback.mediumImpact();
            _loadNextDays(90);
          },
          tooltip: 'Next 90 days',
          icon: Icon(Icons.refresh_rounded),
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
          subtitle: _isHindi ? 'व्रत' : 'Vrats',
        ),
        const SizedBox(width: 12),
        _statChip(
          icon: Icons.calendar_today_rounded,
          label: '${calendar.uniqueDatesCount}',
          subtitle: _isHindi ? 'दिन' : 'Days',
        ),
        const SizedBox(width: 12),
        _statChip(
          icon: Icons.schedule_rounded,
          label: '${calendar.days}',
          subtitle: _isHindi ? 'अवधि' : 'Range',
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
        color: AppColors.parchment.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.parchment.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Theme.of(context).brightness == Brightness.dark ? AppColors.pureWhite : AppColors.parchment, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AutoSizeText(
                label,
                style:       TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark ? AppColors.pureWhite : AppColors.parchment,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              AutoSizeText(
                subtitle,
                style: TextStyle(
                  color: AppColors.parchment.withValues(alpha: 0.7),
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
    final selectedDate = _selectedDate;
    final selectedKey =
        selectedDate == null ? null : _formatDateKey(selectedDate);
    final filteredItems = _getFilteredItems(state);
    final itemsByDate = _getItemsByDate(
      filteredItems,
      state.selectedImportance,
    );
    final items =
        selectedKey == null
            ? filteredItems
            : (itemsByDate[selectedKey] ?? const <VratItem>[]);

    return [
      SliverToBoxAdapter(child: _buildFilters(state, isDark)),
      if (selectedDate != null)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: _buildSelectedDateHeader(
              isDark: isDark,
              date: selectedDate,
              vratCount: items.length,
            ),
          ),
        ),
      if (items.isEmpty)
        SliverFillRemaining(child: _buildEmpty(isDark))
      else
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              return AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  final delay = (index * 0.1).clamp(0.0, 0.5);
                  final animValue = Curves.easeOutCubic.transform(
                    ((_animController.value - delay) / (1 - delay)).clamp(
                      0.0,
                      1.0,
                    ),
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
            }, childCount: items.length),
          ),
        ),
    ];
  }

  SliverPersistentHeader _buildPinnedNextUpcoming(
    PanchangVratSuccess state,
    bool isDark,
  ) {
    final next = _findNextUpcomingVrat(state.calendar.items);

    return SliverPersistentHeader(
      pinned: true,
      delegate: _PinnedHeaderDelegate(
        minExtent: 76,
        maxExtent: 76,
        child: SizedBox(
          height: 76,
          child: Container(
            color:
                (isDark
                    ? AppColors.charcoal
                    : AppColors.parchment),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child:
                      next == null
                          ? _buildTodayHint(isDark)
                          : _buildNextUpcomingCard(next: next, isDark: isDark),
                ),
                const SizedBox(width: 12),
                _buildTodayJumpButton(isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTodayHint(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color:
            isDark
                ? AppColors.parchment.withValues(alpha: 0.05)
                : AppColors.parchment,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isDark
                  ? AppColors.parchment.withValues(alpha: 0.08)
                  : AppColors.charcoal.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_month_rounded,
            size: 18,
            color: isDark ? AppColors.pureWhite.withValues(alpha: 0.54) : AppColors.charcoal54,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AutoSizeText(
              _isHindi ? 'दिन चुनें — व्रत देखें' : 'Pick a day to see vrats',
              style: TextStyle(
                color: isDark ? AppColors.pureWhite.withValues(alpha: 0.54) : AppColors.charcoal54,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayJumpButton(bool isDark) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        final today = DateTime.now();
        setState(() {
          _focusedMonth = DateTime(today.year, today.month, 1);
          _selectedDate = DateTime(today.year, today.month, today.day);
        });
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_gradientStart, _gradientEnd],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _gradientStart.withValues(alpha: 0.25),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.my_location_rounded,
              size: 18,
              color: isDark ? AppColors.pureWhite : AppColors.parchment,
            ),
            const SizedBox(width: 8),
            AutoSizeText(
              _isHindi ? 'आज' : 'Today',
              style:       TextStyle(
                color: isDark ? AppColors.pureWhite : AppColors.parchment,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextUpcomingCard({
    required VratItem next,
    required bool isDark,
  }) {
    final date = next.dateTime;
    final dateLabel = DateFormat('EEE, d MMM').format(date);

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _focusedMonth = DateTime(date.year, date.month, 1);
          _selectedDate = DateTime(date.year, date.month, date.day);
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color:
              isDark
                  ? AppColors.parchment.withValues(alpha: 0.05)
                  : AppColors.parchment,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isDark
                    ? AppColors.parchment.withValues(alpha: 0.08)
                    : AppColors.charcoal.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: _importanceColor(next.importanceLower),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AutoSizeText(
                    _isHindi ? 'अगला व्रत' : 'Next Vrat',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color:
                          isDark ? AppColors.pureWhite.withValues(alpha: 0.60) : AppColors.charcoal45,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  AutoSizeText(
                    _getVratName(next),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color:
                          (isDark
                              ? AppColors.charcoal
                              : AppColors.parchment),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            AutoSizeText(
              dateLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.pureWhite.withValues(alpha: 0.54) : AppColors.charcoal54,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: isDark ? AppColors.pureWhite.withValues(alpha: 0.54) : AppColors.charcoal45,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthCalendar(PanchangVratSuccess state, bool isDark) {
    final monthStart = _ensureMonthGridCache();
    final monthLabel = DateFormat('MMMM y').format(monthStart);
    final days = _cachedMonthDays;
    final dayKeys = _cachedMonthDayKeys;
    final vratCounts = _getVratCounts(state.calendar.items);

    return Container(
      decoration: BoxDecoration(
        color:
            isDark
                ? AppColors.parchment.withValues(alpha: 0.05)
                : AppColors.parchment,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              isDark
                  ? AppColors.parchment.withValues(alpha: 0.08)
                  : AppColors.charcoal.withValues(alpha: 0.05),
        ),
        boxShadow:
            isDark
                ? null
                : [
                  BoxShadow(
                    color: AppColors.charcoal.withValues(alpha: 0.04),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _focusedMonth = DateTime(
                        _focusedMonth.year,
                        _focusedMonth.month - 1,
                        1,
                      );
                    });
                  },
                  icon: Icon(
                    Icons.chevron_left_rounded,
                    color:
                        isDark ? AppColors.pureWhite.withValues(alpha: 0.54) : AppColors.charcoal54,
                  ),
                ),
                Expanded(
                  child: AutoSizeText(
                    monthLabel,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color:
                          (isDark
                              ? AppColors.charcoal
                              : AppColors.parchment),
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _focusedMonth = DateTime(
                        _focusedMonth.year,
                        _focusedMonth.month + 1,
                        1,
                      );
                    });
                  },
                  icon: Icon(
                    Icons.chevron_right_rounded,
                    color:
                        isDark ? AppColors.pureWhite.withValues(alpha: 0.54) : AppColors.charcoal54,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _buildWeekdayRow(isDark),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: days.length,
              itemBuilder: (context, index) {
                final day = days[index];
                final inMonth = day.month == monthStart.month;
                final key = dayKeys[index];
                final vrats = vratCounts[key] ?? 0;
                final isToday = _isToday(day);
                final selectedDate = _selectedDate;
                final isSelected =
                    selectedDate != null && _isSameDate(selectedDate, day);

                return InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      final currentSelected = _selectedDate;
                      if (currentSelected != null &&
                          _isSameDate(currentSelected, day)) {
                        _selectedDate = null;
                      } else {
                        _selectedDate = DateTime(day.year, day.month, day.day);
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient:
                          isSelected
                              ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [_gradientStart, _gradientEnd],
                              )
                              : null,
                      color:
                          !isSelected
                              ? (isDark
                                  ? AppColors.parchment.withValues(alpha: 0.03)
                                  : AppColors.parchment)
                              : null,
                      border: Border.all(
                        color:
                            isToday
                                ? (isSelected
                                    ? AppColors.parchment.withValues(
                                      alpha: 0.65,
                                    )
                                    : _gradientStart.withValues(alpha: 0.55))
                                : (isDark
                                    ? AppColors.parchment.withValues(
                                      alpha: 0.06,
                                    )
                                    : AppColors.charcoal.withValues(
                                      alpha: 0.04,
                                    )),
                        width: isToday ? 1.4 : 1,
                      ),
                    ),
                    child: Opacity(
                      opacity: inMonth ? 1 : 0.35,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AutoSizeText(
                            '${day.day}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color:
                                  isSelected
                                      ? AppColors.parchment
                                      : (isDark
                                          ? AppColors.parchment54
                                          : AppColors.parchment),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (vrats > 0)
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color:
                                        isSelected
                                            ? AppColors.parchment
                                            : AppColors.harvestAmber,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekdayRow(bool isDark) {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Row(
      children: List.generate(7, (i) {
        return Expanded(
          child: Center(
            child: AutoSizeText(
              labels[i],
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.pureWhite.withValues(alpha: 0.54) : AppColors.charcoal45,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSelectedDateHeader({
    required bool isDark,
    required DateTime date,
    required int vratCount,
  }) {
    final label = DateFormat('EEEE, d MMM y').format(date);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color:
            isDark
                ? AppColors.parchment.withValues(alpha: 0.05)
                : AppColors.parchment,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isDark
                  ? AppColors.parchment.withValues(alpha: 0.08)
                  : AppColors.charcoal.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AutoSizeText(
                  _isHindi ? 'चुनी हुई तिथि' : 'Selected date',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color:
                        isDark ? AppColors.pureWhite.withValues(alpha: 0.60) : AppColors.charcoal45,
                  ),
                ),
                const SizedBox(height: 2),
                AutoSizeText(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color:
                        (isDark
                            ? AppColors.charcoal
                            : AppColors.parchment),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.harvestAmber.withValues(
                alpha: isDark ? 0.15 : 0.10,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: AutoSizeText(
              _isHindi ? '$vratCount व्रत' : '$vratCount vrats',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.pureWhite.withValues(alpha: 0.54) : AppColors.harvestAmber,
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedDate = null);
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:
                    isDark
                        ? AppColors.parchment.withValues(alpha: 0.06)
                        : AppColors.parchment,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.close_rounded,
                size: 18,
                color: isDark ? AppColors.pureWhite.withValues(alpha: 0.60) : AppColors.charcoal45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(PanchangVratSuccess state, bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color:
            isDark
                ? AppColors.parchment.withValues(alpha: 0.05)
                : AppColors.parchment,
        borderRadius: BorderRadius.circular(16),
        boxShadow:
            isDark
                ? null
                : [
                  BoxShadow(
                    color: AppColors.charcoal.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
      ),
      child: Row(
        children: [
          _buildFilterChip(
            label: _isHindi ? 'सभी' : 'All',
            icon: Icons.grid_view_rounded,
            selected: state.selectedImportance == null,
            onTap: () => _cubit.filterByImportance(null),
            isDark: isDark,
          ),
          _buildFilterChip(
            label: _isHindi ? 'उच्च' : 'High',
            icon: Icons.priority_high_rounded,
            selected: state.selectedImportance == 'high',
            onTap: () => _cubit.filterByImportance('high'),
            isDark: isDark,
            color: AppColors.rawEarth,
          ),
          _buildFilterChip(
            label: _isHindi ? 'मध्यम' : 'Medium',
            icon: Icons.remove_rounded,
            selected: state.selectedImportance == 'medium',
            onTap: () => _cubit.filterByImportance('medium'),
            isDark: isDark,
            color: AppColors.harvestAmber,
          ),
          _buildFilterChip(
            label: _isHindi ? 'निम्न' : 'Low',
            icon: Icons.keyboard_arrow_down_rounded,
            selected: state.selectedImportance == 'low',
            onTap: () => _cubit.filterByImportance('low'),
            isDark: isDark,
            color: AppColors.deepSoilGreen,
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
            color: selected ? chipColor : AppColors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color:
                    selected
                        ? AppColors.parchment
                        : (isDark
                            ? AppColors.parchment54
                            : AppColors.charcoal45),
              ),
              const SizedBox(height: 4),
              AutoSizeText(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color:
                      selected
                          ? AppColors.parchment
                          : (isDark ? AppColors.pureWhite.withValues(alpha: 0.54) : AppColors.charcoal54),
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
    final details = vrat.details;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showDetails(vrat, isDark);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color:
              (isDark
                  ? AppColors.charcoal
                  : AppColors.parchment),
          boxShadow: [
            BoxShadow(
              color: importanceColor.withValues(alpha: isDark ? 0.15 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            if (!isDark)
              BoxShadow(
                color: AppColors.charcoal.withValues(alpha: 0.03),
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
                        _buildImportanceBadge(
                          vrat.importanceLower,
                          importanceColor,
                          isDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    AutoSizeText(
                      _getVratName(vrat),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color:
                            (isDark
                                ? AppColors.charcoal
                                : AppColors.parchment),
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (details != null) ...[
                      const SizedBox(height: 6),
                      AutoSizeText(
                        _metaLine(details),
                        style: TextStyle(
                          fontSize: 13,
                          color:
                              isDark
                                  ? AppColors.parchment54
                                  : AppColors.charcoal45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    if (_getDescription(vrat.info).isNotEmpty) ...[
                      const SizedBox(height: 10),
                      AutoSizeText(
                        _getDescription(vrat.info),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,

                          color:
                              isDark ? AppColors.pureWhite.withValues(alpha: 0.54) : AppColors.charcoal54,
                        ),
                      ),
                    ],
                    if (details != null) ...[
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _buildTimingChip(
                            Icons.wb_sunny_rounded,
                            'Sunrise',
                            _formatTime(details.sunrise),
                            AppColors.parchment,
                            isDark,
                          ),
                          const SizedBox(width: 10),
                          _buildTimingChip(
                            Icons.nightlight_round,
                            'Sunset',
                            _formatTime(details.sunset),
                            AppColors.parchment,
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
        gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.8)]),
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
          AutoSizeText(
            DateFormat('d').format(date),
            style:       TextStyle(
              color: isDark ? AppColors.pureWhite : AppColors.parchment,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          AutoSizeText(
            isToday
                ? (_isHindi ? 'आज' : 'TODAY')
                : isTomorrow
                ? (_isHindi ? 'कल' : 'TMRW')
                : DateFormat('MMM').format(date).toUpperCase(),
            style: TextStyle(
              color: AppColors.parchment.withValues(alpha: 0.9),
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
      text = _isHindi ? '🎯 आज' : '🎯 Today';
      bgColor = AppColors.parchment;
    } else if (daysUntil == 1) {
      text = _isHindi ? '⏰ कल' : '⏰ Tomorrow';
      bgColor = AppColors.parchment;
    } else if (daysUntil <= 7) {
      text = _isHindi ? '📅 $daysUntil दिन' : '📅 $daysUntil days';
      bgColor = AppColors.parchment;
    } else {
      text = _isHindi ? '$daysUntil दिन' : '$daysUntil days';
      bgColor = isDark ? AppColors.pureWhite : AppColors.charcoal12;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: isDark ? 0.25 : 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: bgColor.withValues(alpha: 0.4)),
      ),
      child: AutoSizeText(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.pureWhite : bgColor,
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
      child: AutoSizeText(
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
          AutoSizeText(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.pureWhite.withValues(alpha: 0.54) : color,
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
          AutoSizeText(
            _isHindi ? 'कोई व्रत नहीं मिला' : 'No Vrats Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.pureWhite : AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 8),
          AutoSizeText(
            _isHindi
                ? 'फ़िल्टर या तिथि सीमा बदलें'
                : 'Try adjusting your filters or date range',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.pureWhite.withValues(alpha: 0.54) : AppColors.charcoal70,
            ),
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: () => _loadNextDays(90),
            icon: Icon(Icons.refresh_rounded),
            label: AutoSizeText(_isHindi ? 'रीसेट करें' : 'Reset Filters'),
            style: TextButton.styleFrom(foregroundColor: _gradientStart),
          ),
        ],
      ),
    );
  }

  void _showDetails(VratItem vrat, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (context) => _detailsSheet(vrat, isDark),
    );
  }

  Widget _detailsSheet(VratItem vrat, bool isDark) {
    final importanceColor = _importanceColor(vrat.importanceLower);
    final info = vrat.info;
    final observance = info?.observance;
    final details = vrat.details;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, controller) {
        return Container(
          decoration: BoxDecoration(
            color:
                (isDark
                    ? AppColors.charcoal
                    : AppColors.parchment),
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
                    colors: [
                      importanceColor,
                      importanceColor.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.parchment.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.parchment.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.self_improvement_rounded,
                            color: isDark ? AppColors.pureWhite : AppColors.parchment,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AutoSizeText(
                                _getVratName(vrat),
                                style:       TextStyle(
                                  color: isDark ? AppColors.pureWhite : AppColors.parchment,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              AutoSizeText(
                                DateFormat(
                                  'EEEE, MMMM d, y',
                                ).format(vrat.dateTime),
                                style: TextStyle(
                                  color: AppColors.parchment.withValues(
                                    alpha: 0.85,
                                  ),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (details != null) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _sheetTimingChip(
                            Icons.wb_sunny_rounded,
                            'Sunrise',
                            _formatTime(details.sunrise),
                          ),
                          const SizedBox(width: 10),
                          _sheetTimingChip(
                            Icons.nightlight_round,
                            'Sunset',
                            _formatTime(details.sunset),
                          ),
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
                    if (details != null) ...[
                      _buildInfoCard(
                        icon: Icons.calendar_month_rounded,
                        title: _isHindi ? 'विवरण' : 'Details',
                        content: _metaLine(details),
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (_getWhy(vrat).isNotEmpty) ...[
                      _buildInfoCard(
                        icon: Icons.info_outline_rounded,
                        title: _isHindi ? 'यह दिन क्यों' : 'Why This Day',
                        content: _getWhy(vrat),
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (_getDescription(info).isNotEmpty) ...[
                      _buildInfoCard(
                        icon: Icons.article_outlined,
                        title: _isHindi ? 'जानकारी' : 'About',
                        content: _getDescription(info),
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (_getHowToDo(observance).isNotEmpty) ...[
                      _buildInfoCard(
                        icon: Icons.checklist_rounded,
                        title: _isHindi ? 'कैसे करें' : 'How to Observe',
                        content: _getHowToDo(observance),
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (_getAvoidList(observance).isNotEmpty) ...[
                      _buildListCard(
                        icon: Icons.do_not_disturb_alt_rounded,
                        title: _isHindi ? 'क्या न करें' : 'Things to Avoid',
                        items: _getAvoidList(observance),
                        color: AppColors.rawEarth,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (_getAllowedList(observance).isNotEmpty) ...[
                      _buildListCard(
                        icon: Icons.check_circle_outline_rounded,
                        title:
                            _isHindi ? 'क्या कर सकते हैं' : 'What\'s Allowed',
                        items: _getAllowedList(observance),
                        color: AppColors.deepSoilGreen,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (_getParanNotes(info?.paranRules).isNotEmpty) ...[
                      _buildInfoCard(
                        icon: Icons.restaurant_rounded,
                        title: _isHindi ? 'पारण नियम' : 'Paran Rules',
                        content: _getParanNotes(info?.paranRules),
                        isDark: isDark,
                        accentColor: AppColors.parchment,
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
          color: AppColors.parchment.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Theme.of(context).brightness == Brightness.dark ? AppColors.pureWhite : AppColors.parchment, size: 18),
            const SizedBox(width: 8),
            AutoSizeText(
              value,
              style:       TextStyle(
                color: Theme.of(context).brightness == Brightness.dark ? AppColors.pureWhite : AppColors.parchment,
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
        color:
            isDark
                ? AppColors.parchment.withValues(alpha: 0.05)
                : AppColors.parchment,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isDark
                  ? AppColors.parchment.withValues(alpha: 0.08)
                  : AppColors.charcoal.withValues(alpha: 0.04),
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
              AutoSizeText(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color:
                      (isDark
                          ? AppColors.charcoal
                          : AppColors.parchment),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AutoSizeText(
            content,
            style: TextStyle(
              fontSize: 14,

              color: isDark ? AppColors.pureWhite.withValues(alpha: 0.54) : AppColors.charcoal54,
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
        color:
            isDark
                ? AppColors.parchment.withValues(alpha: 0.05)
                : AppColors.parchment,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isDark
                  ? AppColors.parchment.withValues(alpha: 0.08)
                  : AppColors.charcoal.withValues(alpha: 0.04),
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
              AutoSizeText(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color:
                      (isDark
                          ? AppColors.charcoal
                          : AppColors.parchment),
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
                    child: AutoSizeText(
                      item,
                      style: TextStyle(
                        fontSize: 14,

                        color:
                            isDark ? AppColors.pureWhite.withValues(alpha: 0.54) : AppColors.charcoal54,
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
              onPrimary: AppColors.parchment,
              surface:
                  isDark ? AppColors.pureWhite : AppColors.charcoal,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
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

  String _formatDateKey(DateTime date) {
    return _dateKeyFormat.format(date);
  }

  DateTime _ensureMonthGridCache() {
    final monthStart = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    if (_cachedMonthDays.isNotEmpty &&
        _isSameDate(_cachedMonthStart, monthStart)) {
      return monthStart;
    }

    final startWeekday = monthStart.weekday; // Mon=1..Sun=7
    final gridStart = monthStart.subtract(Duration(days: startWeekday - 1));
    final days = List<DateTime>.generate(
      42,
      (i) => gridStart.add(Duration(days: i)),
    );
    final keys = List<String>.generate(42, (i) => _formatDateKey(days[i]));

    _cachedMonthStart = monthStart;
    _cachedMonthDays = days;
    _cachedMonthDayKeys = keys;
    return monthStart;
  }

  Map<String, int> _getVratCounts(List<VratItem> items) {
    if (identical(_cachedCountsSourceItems, items)) return _cachedVratCounts;

    final counts = <String, int>{};
    for (final v in items) {
      counts[v.date] = (counts[v.date] ?? 0) + 1;
    }

    _cachedCountsSourceItems = items;
    _cachedVratCounts = counts;
    return counts;
  }

  List<VratItem> _getFilteredItems(PanchangVratSuccess state) {
    final items = state.calendar.items;
    final importance = state.selectedImportance;

    if (identical(_cachedFilteredSourceItems, items) &&
        _cachedFilteredImportance == importance) {
      return _cachedFilteredItems;
    }

    final List<VratItem> filtered;
    if (importance == null) {
      filtered = items;
    } else {
      final tmp = <VratItem>[];
      for (final item in items) {
        if (item.importanceLower == importance) tmp.add(item);
      }
      filtered = tmp;
    }

    _cachedFilteredSourceItems = items;
    _cachedFilteredImportance = importance;
    _cachedFilteredItems = filtered;
    return filtered;
  }

  Map<String, List<VratItem>> _getItemsByDate(
    List<VratItem> filteredItems,
    String? importance,
  ) {
    if (identical(_cachedItemsByDateSourceItems, filteredItems) &&
        _cachedItemsByDateImportance == importance) {
      return _cachedItemsByDate;
    }

    final map = <String, List<VratItem>>{};
    for (final item in filteredItems) {
      (map[item.date] ??= <VratItem>[]).add(item);
    }

    _cachedItemsByDateSourceItems = filteredItems;
    _cachedItemsByDateImportance = importance;
    _cachedItemsByDate = map;
    return map;
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _ensureSelectedDateInRange(VratCalendarResponse calendar) {
    if (calendar.items.isEmpty) return;

    if (_selectedDate == null) {
      final today = DateTime.now();
      final todayKey = _formatDateKey(today);
      final hasToday = calendar.items.any((e) => e.date == todayKey);
      setState(() {
        final selected =
            hasToday
                ? DateTime(today.year, today.month, today.day)
                : calendar.items.first.dateTime;
        _selectedDate = selected;
        final d = selected;
        _focusedMonth = DateTime(d.year, d.month, 1);
      });
      return;
    }

    final first = calendar.items.first.dateTime;
    final last = calendar.items.last.dateTime;
    final d = _selectedDate;
    if (d == null) return;
    if (d.isBefore(first) || d.isAfter(last)) {
      setState(() {
        _selectedDate = first;
        _focusedMonth = DateTime(first.year, first.month, 1);
      });
    }
  }

  VratItem? _findNextUpcomingVrat(List<VratItem> items) {
    if (items.isEmpty) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    for (final v in items) {
      final d = v.dateTime;
      final day = DateTime(d.year, d.month, d.day);
      if (!day.isBefore(today)) return v;
    }
    return items.last;
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
        return AppColors.rawEarth;
      case 'low':
        return AppColors.deepSoilGreen;
      case 'medium':
      default:
        return AppColors.harvestAmber;
    }
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '--:--';
    return DateFormat('h:mm a').format(dt);
  }

  String _metaLine(VratDetails details) {
    final parts = <String>[];
    if ((details.paksha ?? '').isNotEmpty) {
      parts.add('${details.paksha} Paksha');
    }
    if ((details.masa ?? '').isNotEmpty) parts.add(details.masa ?? '');
    if ((details.tithi ?? '').isNotEmpty) parts.add(details.tithi ?? '');
    return parts.join(' • ');
  }

  // Language helpers
  String _getVratName(VratItem vrat) {
    if (_isHindi && (vrat.nameHi ?? '').isNotEmpty) {
      return vrat.nameHi ?? vrat.name;
    }
    return vrat.name;
  }

  String _getDescription(VratInfo? info) {
    if (info == null) return '';
    if (_isHindi && (info.descriptionHi ?? '').isNotEmpty) {
      return info.descriptionHi ?? info.description;
    }
    if ((info.descriptionEn ?? '').isNotEmpty) return info.descriptionEn ?? '';
    return info.description;
  }

  String _getWhy(VratItem vrat) {
    if (_isHindi && (vrat.whyHi ?? '').isNotEmpty) return vrat.whyHi ?? '';
    return vrat.why ?? '';
  }

  String _getHowToDo(VratObservance? observance) {
    if (observance == null) return '';
    if (_isHindi && (observance.howToDoHi ?? '').isNotEmpty) {
      return observance.howToDoHi ?? '';
    }
    return observance.howToDoEn ?? '';
  }

  List<String> _getAvoidList(VratObservance? observance) {
    if (observance == null) return [];
    if (_isHindi && observance.avoidHi.isNotEmpty) return observance.avoidHi;
    return observance.avoidEn;
  }

  List<String> _getAllowedList(VratObservance? observance) {
    if (observance == null) return [];
    if (_isHindi && observance.allowedHi.isNotEmpty) {
      return observance.allowedHi;
    }
    return observance.allowedEn;
  }

  String _getParanNotes(VratParanRules? rules) {
    if (rules == null) return '';
    if (_isHindi && (rules.notesHi ?? '').isNotEmpty) {
      return rules.notesHi ?? '';
    }
    return rules.notesEn ?? '';
  }
}

class _PinnedHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double _minExtent;
  final double _maxExtent;
  final Widget child;

  _PinnedHeaderDelegate({
    required double minExtent,
    required double maxExtent,
    required this.child,
  }) : _minExtent = minExtent,
       _maxExtent = maxExtent;

  @override
  double get minExtent => _minExtent;

  @override
  double get maxExtent => _maxExtent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _PinnedHeaderDelegate oldDelegate) {
    return _minExtent != oldDelegate._minExtent ||
        _maxExtent != oldDelegate._maxExtent ||
        child != oldDelegate.child;
  }
}
