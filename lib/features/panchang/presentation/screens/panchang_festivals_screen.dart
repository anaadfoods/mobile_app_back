import 'package:grocery_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grocery_app/core/theme/app_colors.dart';
import 'package:intl/intl.dart';

import 'package:grocery_app/service_locator.dart';
import 'package:grocery_app/common_widgets/error_state_widget.dart';
import 'package:grocery_app/features/panchang/presentation/cubit/panchang_festivals_cubit.dart';
import 'package:grocery_app/features/panchang/presentation/cubit/panchang_festivals_state.dart';
import 'package:grocery_app/models/panchang/panchang_festival_models.dart';
import 'package:grocery_app/repositories/panchang_repository.dart';

class PanchangFestivalsScreen extends StatefulWidget {
  const PanchangFestivalsScreen({super.key});

  @override
  State<PanchangFestivalsScreen> createState() =>
      _PanchangFestivalsScreenState();
}

class _PanchangFestivalsScreenState extends State<PanchangFestivalsScreen>
    with TickerProviderStateMixin {
  late final PanchangFestivalsCubit _cubit;
  late final AnimationController _entranceController;
  late final AnimationController _searchController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _slideAnimation;

  final TextEditingController _searchTextController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  bool _isSearchMode = false;
  FestivalType _selectedFilter = FestivalType.all;
  DateRangeMode _dateRangeMode = DateRangeMode.currentMonth;

  @override
  void initState() {
    super.initState();
    _cubit = PanchangFestivalsCubit(repository: getIt<PanchangRepository>());

    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _searchController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
    );

    _slideAnimation = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
    );

    _entranceController.forward();
    _cubit.loadCurrentMonth();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _searchController.dispose();
    _searchTextController.dispose();
    _searchFocusNode.dispose();
    _cubit.close();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearchMode = !_isSearchMode;
      if (_isSearchMode) {
        _searchController.forward();
        _searchFocusNode.requestFocus();
      } else {
        _searchController.reverse();
        _searchTextController.clear();
        _searchFocusNode.unfocus();
        _cubit.clearSearch();
      }
    });
    HapticFeedback.lightImpact();
  }

  void _onSearch(String query) {
    if (query.trim().isEmpty) {
      _cubit.clearSearch();
    } else {
      // API requires year parameter - pass current year
      final currentYear = DateTime.now().year;
      _cubit.searchFestivals(query, year: currentYear);
    }
  }

  void _onFilterChanged(FestivalType type) {
    setState(() {
      _selectedFilter = type;
    });
    HapticFeedback.lightImpact();
    _cubit.applyFilter(type == FestivalType.all ? null : type.value);
  }

  void _onDateRangeModeChanged(DateRangeMode mode) {
    setState(() {
      _dateRangeMode = mode;
    });
    HapticFeedback.lightImpact();

    switch (mode) {
      case DateRangeMode.currentMonth:
        _cubit.loadCurrentMonth();
        break;
      case DateRangeMode.upcoming:
        _cubit.loadUpcoming();
        break;
      case DateRangeMode.currentYear:
        _cubit.loadFullYear(DateTime.now().year);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.pureBlack : AppColors.parchment,
        body: Stack(
          children: [
            _buildAnimatedBackground(isDark),
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(context, theme, isDark),
                  if (!_isSearchMode) ...[
                    _buildDateRangeSelector(isDark),
                    _buildFilterChips(isDark),
                  ],
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _entranceController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _fadeAnimation.value,
                          child: Transform.translate(
                            offset: Offset(0, _slideAnimation.value),
                            child: child,
                          ),
                        );
                      },
                      child: BlocBuilder<
                        PanchangFestivalsCubit,
                        PanchangFestivalsState
                      >(
                        builder: (context, state) {
                          if (state is PanchangFestivalsLoading ||
                              state is PanchangFestivalsSearching ||
                              state is PanchangFestivalsInitial) {
                            return _buildLoadingState(theme, isDark);
                          }

                          if (state is PanchangFestivalsError) {
                            return Center(
                              child: ErrorStateWidget(
                                subtitle: state.message,
                                onRetry: () => _cubit.refresh(),
                              ),
                            );
                          }

                          if (state is PanchangFestivalsSearchSuccess) {
                            return _buildSearchResults(state, isDark);
                          }

                          if (state is PanchangFestivalsSuccess) {
                            return _buildFestivalsList(state, isDark);
                          }

                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground(bool isDark) {
    return Positioned.fill(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors:
                isDark
                    ? [AppColors.deepSoilGreen, const Color(0xFF3D6B28)]
                    : [AppColors.parchment, AppColors.lightGold],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        children: [
          Row(
            children: [
              // Back button
              Container(
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? AppColors.parchment.withValues(alpha: 0.1)
                          : AppColors.charcoal.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Material(
                  color: AppColors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color:
                            (isDark
                                ? AppColors.parchment
                                : AppTheme
                                    .lightTheme
                                    .textTheme
                                    .bodyLarge
                                    ?.color),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AutoSizeText(
                      'Festivals',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color:
                            (isDark
                                ? AppColors.parchment
                                : AppTheme
                                    .lightTheme
                                    .textTheme
                                    .bodyLarge
                                    ?.color),
                      ),
                    ),
                    AutoSizeText(
                      'Hindu Calendar Festivals',
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            isDark
                                ? AppColors.parchment60
                                : AppColors.charcoal54,
                      ),
                    ),
                  ],
                ),
              ),
              // Search button
              Container(
                decoration: BoxDecoration(
                  color:
                      _isSearchMode
                          ? AppColors.parchment.withValues(alpha: 0.2)
                          : (isDark
                              ? AppColors.parchment.withValues(alpha: 0.1)
                              : AppColors.charcoal.withValues(alpha: 0.05)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Material(
                  color: AppColors.transparent,
                  child: InkWell(
                    onTap: _toggleSearch,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Icon(
                        _isSearchMode
                            ? Icons.close_rounded
                            : Icons.search_rounded,
                        color:
                            _isSearchMode
                                ? AppColors.parchment
                                : (isDark
                                    ? AppColors.pureWhite
                                    : AppColors.charcoal),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Search bar
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child:
                _isSearchMode
                    ? Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: _buildSearchBar(isDark),
                    )
                    : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color:
            isDark
                ? AppColors.parchment.withValues(alpha: 0.1)
                : AppColors.parchment.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isDark
                  ? AppColors.parchment.withValues(alpha: 0.1)
                  : AppColors.charcoal.withValues(alpha: 0.1),
        ),
      ),
      child: TextField(
        controller: _searchTextController,
        focusNode: _searchFocusNode,
        onChanged: _onSearch,
        style: TextStyle(
          color: isDark ? AppColors.parchment : AppColors.charcoal,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: 'Search festivals...',
          hintStyle: TextStyle(
            color:
                isDark
                    ? AppColors.pureWhite.withValues(alpha: 0.54)
                    : AppColors.charcoal54,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color:
                isDark
                    ? AppColors.pureWhite.withValues(alpha: 0.54)
                    : AppColors.charcoal54,
          ),
          suffixIcon:
              _searchTextController.text.isNotEmpty
                  ? IconButton(
                    icon: Icon(
                      Icons.clear_rounded,
                      color:
                          isDark
                              ? AppColors.pureWhite.withValues(alpha: 0.54)
                              : AppColors.charcoal54,
                    ),
                    onPressed: () {
                      _searchTextController.clear();
                      _cubit.clearSearch();
                    },
                  )
                  : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildDateRangeSelector(bool isDark) {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildDateRangeChip(
            'This Month',
            DateRangeMode.currentMonth,
            Icons.calendar_today_rounded,
            isDark,
          ),
          const SizedBox(width: 8),
          _buildDateRangeChip(
            'Upcoming',
            DateRangeMode.upcoming,
            Icons.upcoming_rounded,
            isDark,
          ),
          const SizedBox(width: 8),
          _buildDateRangeChip(
            'This Year',
            DateRangeMode.currentYear,
            Icons.calendar_month_rounded,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeChip(
    String label,
    DateRangeMode mode,
    IconData icon,
    bool isDark,
  ) {
    final isSelected = _dateRangeMode == mode;
    return GestureDetector(
      onTap: () => _onDateRangeModeChanged(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient:
              isSelected
                  ? LinearGradient(
                    colors: [
                      isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen,
                      (isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen).withValues(alpha: 0.85),
                    ],
                  )
                  : null,
          color:
              isSelected
                  ? null
                  : (isDark
                      ? AppColors.darkSurfaceElevated
                      : AppColors.pureWhite),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected
                    ? (isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen)
                    : (isDark
                        ? AppColors.pureWhite.withValues(alpha: 0.08)
                        : AppColors.charcoal.withValues(alpha: 0.08)),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: (isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen).withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color:
                  isSelected
                      ? (isDark ? AppColors.charcoal : AppColors.pureWhite)
                      : (isDark ? AppColors.pureWhite.withValues(alpha: 0.7) : AppColors.charcoal),
            ),
            const SizedBox(width: 6),
            AutoSizeText(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color:
                    isSelected
                        ? (isDark ? AppColors.charcoal : AppColors.pureWhite)
                        : (isDark ? AppColors.pureWhite.withValues(alpha: 0.7) : AppColors.charcoal),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips(bool isDark) {
    return Container(
      height: 44,
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 12),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children:
            FestivalType.values.map((type) {
              final isSelected = _selectedFilter == type;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => _onFilterChanged(type),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? Color(type.colorValue).withValues(alpha: isDark ? 0.25 : 0.15)
                              : (isDark
                                  ? AppColors.darkSurfaceElevated
                                  : AppColors.pureWhite),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color:
                            isSelected
                                ? Color(type.colorValue)
                                : (isDark
                                    ? AppColors.pureWhite.withValues(alpha: 0.08)
                                    : AppColors.charcoal.withValues(
                                      alpha: 0.08,
                                    )),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: Color(type.colorValue),
                              shape: BoxShape.circle,
                            ),
                          ),
                        AutoSizeText(
                          type.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                            color:
                                isSelected
                                    ? Color(type.colorValue)
                                    : (isDark
                                        ? AppColors.pureWhite.withValues(alpha: 0.7)
                                        : AppColors.charcoal),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: (isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen,
              ),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 16),
          AutoSizeText(
            'Fetching Vedic festivals...',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFestivalsList(PanchangFestivalsSuccess state, bool isDark) {
    if (state.response.festivals.isEmpty) {
      return _buildEmptyState(isDark);
    }

    return RefreshIndicator(
      onRefresh: () => _cubit.refresh(),
      color: isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        itemCount: state.response.festivals.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildStatsCard(state, isDark);
          }
          final dateGroup = state.response.festivals[index - 1];
          return _buildDateGroup(dateGroup, isDark);
        },
      ),
    );
  }

  Widget _buildStatsCard(PanchangFestivalsSuccess state, bool isDark) {
    final metadata = state.response.metadata;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              isDark
                  ? [
                    AppColors.darkSurfaceElevated,
                    AppColors.darkSurface,
                  ]
                  : [
                    AppColors.deepSoilGreen,
                    AppColors.successGreen,
                  ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.1),
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.celebration_rounded,
                  color: isDark ? AppColors.harvestAmber : Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AutoSizeText(
                      '${metadata.totalFestivals} Festivals',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.pureWhite : Colors.white,
                      ),
                    ),
                    AutoSizeText(
                      'Across ${metadata.totalDays} days in Vedic calendar',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: (isDark ? AppColors.pureWhite : Colors.white).withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (metadata.startDate != null && metadata.endDate != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.date_range_rounded,
                    color: isDark ? AppColors.harvestAmber : Colors.white,
                    size: 15,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: AutoSizeText(
                      '${_formatDateShort(metadata.startDate!)} - ${_formatDateShort(metadata.endDate!)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? AppColors.pureWhite : Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDateGroup(FestivalDateGroup dateGroup, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          // Date header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.03),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(
                bottom: BorderSide(
                  color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.06),
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.calendar_today_rounded,
                    size: 18,
                    color: isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AutoSizeText(
                        _formatDateHeader(dateGroup.date),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.pureWhite : AppColors.charcoal,
                        ),
                      ),
                      if (dateGroup.dayOfWeek.isNotEmpty ||
                          dateGroup.tithi.isNotEmpty)
                        AutoSizeText(
                          '${dateGroup.dayOfWeek}${dateGroup.dayOfWeek.isNotEmpty && dateGroup.tithi.isNotEmpty ? " • " : ""}${dateGroup.tithi}',
                          style: TextStyle(
                            fontSize: 12,
                            color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.6),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: (isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: AutoSizeText(
                    '${dateGroup.festivals.length}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Festivals list
          ...dateGroup.festivals.map((festival) {
            return _buildFestivalItem(festival, isDark);
          }),
        ],
      ),
    );
  }

  Widget _buildFestivalItem(FestivalEntry festival, bool isDark) {
    final typeColor = Color(FestivalType.fromString(festival.type).colorValue);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.05),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 38,
            decoration: BoxDecoration(
              color: typeColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AutoSizeText(
                  festival.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.pureWhite : AppColors.charcoal,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: isDark ? 0.25 : 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: AutoSizeText(
                        festival.type.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: typeColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    if (festival.isNationalHoliday)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: (isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.flag_rounded,
                              size: 11,
                              color: isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen,
                            ),
                            const SizedBox(width: 4),
                            AutoSizeText(
                              'HOLIDAY',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                if (festival.description != null) ...[
                  const SizedBox(height: 5),
                  AutoSizeText(
                    festival.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.3),
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(
    PanchangFestivalsSearchSuccess state,
    bool isDark,
  ) {
    if (state.response.results.isEmpty) {
      return _buildEmptySearchState(isDark);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      itemCount: state.response.results.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildSearchStatsCard(state, isDark);
        }
        final result = state.response.results[index - 1];
        return _buildSearchResultCard(result, isDark);
      },
    );
  }

  Widget _buildSearchStatsCard(
    PanchangFestivalsSearchSuccess state,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : AppColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.search_rounded,
              color: isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: 'Found ',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.pureWhite : AppColors.charcoal,
                ),
                children: [
                  TextSpan(
                    text: '${state.response.metadata.totalResults} results',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen,
                    ),
                  ),
                  const TextSpan(text: ' for '),
                  TextSpan(
                    text: '"${state.query}"',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultCard(FestivalSearchResult result, bool isDark) {
    final typeColor = Color(FestivalType.fromString(result.type).colorValue);
    final DateTime? festivalDate = result.dateTime;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date Badge
                if (festivalDate != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          typeColor,
                          typeColor.withValues(alpha: 0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: typeColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        AutoSizeText(
                          DateFormat(
                            'MMM',
                          ).format(festivalDate).toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        AutoSizeText(
                          DateFormat('d').format(festivalDate),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                        AutoSizeText(
                          DateFormat('y').format(festivalDate),
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.white.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AutoSizeText(
                        result.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.pureWhite : AppColors.charcoal,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: typeColor.withValues(alpha: isDark ? 0.25 : 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: AutoSizeText(
                              result.type.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: typeColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.source_rounded,
                                  size: 10,
                                  color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.6),
                                ),
                                const SizedBox(width: 4),
                                AutoSizeText(
                                  result.source,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (festivalDate != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 13,
                              color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 6),
                            AutoSizeText(
                              DateFormat(
                                'EEEE, MMMM d, y',
                              ).format(festivalDate),
                              style: TextStyle(
                                fontSize: 12,
                                color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.event_available_rounded,
                              size: 13,
                              color: typeColor,
                            ),
                            const SizedBox(width: 6),
                            AutoSizeText(
                              _getDaysUntil(festivalDate),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: typeColor,
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
            if (result.code != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.code_rounded,
                      size: 12,
                      color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 6),
                    AutoSizeText(
                      result.code!,
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.celebration_outlined,
              size: 60,
              color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: 18),
          AutoSizeText(
            'No Festivals Found',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.pureWhite : AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 6),
          AutoSizeText(
            'Try selecting a different date range',
            style: TextStyle(
              fontSize: 13.5,
              color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySearchState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 60,
              color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: 18),
          AutoSizeText(
            'No Results Found',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.pureWhite : AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 6),
          AutoSizeText(
            'Try a different search term',
            style: TextStyle(
              fontSize: 13.5,
              color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateHeader(String dateStr) {
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        final date = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
        return DateFormat('EEEE, MMM d, y').format(date);
      }
    } catch (_) {}
    return dateStr;
  }

  String _formatDateShort(String dateStr) {
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        final date = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
        return DateFormat('MMM d, y').format(date);
      }
    } catch (_) {}
    return dateStr;
  }

  String _getDaysUntil(DateTime festivalDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final festival = DateTime(
      festivalDate.year,
      festivalDate.month,
      festivalDate.day,
    );
    final difference = festival.difference(today).inDays;

    if (difference == 0) {
      return 'Today! 🎉';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference > 1 && difference <= 7) {
      return 'In $difference days';
    } else if (difference > 7 && difference <= 30) {
      final weeks = (difference / 7).floor();
      return 'In $weeks ${weeks == 1 ? 'week' : 'weeks'}';
    } else if (difference > 30) {
      final months = (difference / 30).floor();
      return 'In $months ${months == 1 ? 'month' : 'months'}';
    } else if (difference == -1) {
      return 'Yesterday';
    } else {
      return '${difference.abs()} days ago';
    }
  }
}

enum DateRangeMode { currentMonth, upcoming, currentYear }
