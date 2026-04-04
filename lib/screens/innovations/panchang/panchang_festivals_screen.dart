import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../common_widgets/error_state_widget.dart';
import '../../../cubits/panchang/panchang_festivals_cubit.dart';
import '../../../cubits/panchang/panchang_festivals_state.dart';
import '../../../models/panchang/panchang_festival_models.dart';
import '../../../repositories/panchang_repository.dart';

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
    _cubit = PanchangFestivalsCubit(repository: PanchangRepository());

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
        backgroundColor:
            isDark ? const Color(0xFF070C09) : const Color(0xFFF4F8F4),
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
                    ? [
                      const Color(0xFF070C09),
                      const Color(0xFF0D150E),
                      const Color(0xFF0A1510),
                    ]
                    : [
                      const Color(0xFFF4F8F4),
                      const Color(0xFFDCEEDF),
                      const Color(0xFFDCEEDF),
                    ],
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
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: isDark ? Colors.white : Colors.black87,
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
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    AutoSizeText(
                      'Hindu Calendar Festivals',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white60 : Colors.black54,
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
                          ? const Color(0xFF3F5E46).withOpacity(0.2)
                          : (isDark
                              ? Colors.white.withOpacity(0.1)
                              : Colors.black.withOpacity(0.05)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Material(
                  color: Colors.transparent,
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
                                ? const Color(0xFF3F5E46)
                                : (isDark ? Colors.white : Colors.black87),
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
                ? Colors.white.withOpacity(0.1)
                : Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.1),
        ),
      ),
      child: TextField(
        controller: _searchTextController,
        focusNode: _searchFocusNode,
        onChanged: _onSearch,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: 'Search festivals...',
          hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
          suffixIcon:
              _searchTextController.text.isNotEmpty
                  ? IconButton(
                    icon: Icon(
                      Icons.clear_rounded,
                      color: isDark ? Colors.white54 : Colors.black54,
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
                  ? const LinearGradient(
                    colors: [Color(0xFF3F5E46), Color(0xFF3A8C54)],
                  )
                  : null,
          color:
              isSelected
                  ? null
                  : (isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.white.withOpacity(0.7)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected
                    ? const Color(0xFF3F5E46)
                    : (isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.1)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color:
                  isSelected
                      ? Colors.white
                      : (isDark ? Colors.white70 : Colors.black87),
            ),
            const SizedBox(width: 6),
            AutoSizeText(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color:
                    isSelected
                        ? Colors.white
                        : (isDark ? Colors.white70 : Colors.black87),
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
                              ? Color(type.colorValue).withOpacity(0.2)
                              : (isDark
                                  ? Colors.white.withOpacity(0.08)
                                  : Colors.white.withOpacity(0.6)),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color:
                            isSelected
                                ? Color(type.colorValue)
                                : (isDark
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.black.withOpacity(0.1)),
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
                                        ? Colors.white70
                                        : Colors.black87),
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
              color:
                  isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.white.withOpacity(0.7),
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3F5E46)),
            ),
          ),
          const SizedBox(height: 20),
          AutoSizeText(
            'Loading festivals...',
            style: TextStyle(
              fontSize: 15,
              color: isDark ? Colors.white70 : Colors.black87,
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
      color: const Color(0xFF3F5E46),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        itemCount: state.response.festivals.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildStatsCard(state, isDark);
          }
          final dateGroup = state.response.festivals[index - 1];
          return _buildDateGroupCard(dateGroup, isDark);
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
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3F5E46), Color(0xFF3A8C54)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3F5E46).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
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
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.celebration_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AutoSizeText(
                      '${metadata.totalFestivals} Festivals',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    AutoSizeText(
                      'Across ${metadata.totalDays} days',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (metadata.startDate != null && metadata.endDate != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.date_range_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  AutoSizeText(
                    '${_formatDateShort(metadata.startDate!)} - ${_formatDateShort(metadata.endDate!)}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
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

  Widget _buildDateGroupCard(FestivalDateGroup dateGroup, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color:
            isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors:
                        isDark
                            ? [
                              Colors.white.withOpacity(0.1),
                              Colors.white.withOpacity(0.05),
                            ]
                            : [
                              Colors.black.withOpacity(0.05),
                              Colors.black.withOpacity(0.02),
                            ],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3F5E46).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.calendar_today_rounded,
                        size: 20,
                        color: const Color(0xFF3F5E46),
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
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          if (dateGroup.dayOfWeek.isNotEmpty ||
                              dateGroup.tithi.isNotEmpty)
                            AutoSizeText(
                              '${dateGroup.dayOfWeek}${dateGroup.dayOfWeek.isNotEmpty && dateGroup.tithi.isNotEmpty ? " • " : ""}${dateGroup.tithi}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF9933).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: AutoSizeText(
                        '${dateGroup.festivals.length}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF9933),
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
        ),
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
            color:
                isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.05),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
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
                    color:
                        isDark
                            ? Colors.white.withOpacity(0.95)
                            : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.2),
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
                    if (festival.isNationalHoliday) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF138808).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.flag_rounded,
                              size: 10,
                              color: Color(0xFF138808),
                            ),
                            SizedBox(width: 3),
                            AutoSizeText(
                              'HOLIDAY',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF138808),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                if (festival.description != null) ...[
                  const SizedBox(height: 6),
                  AutoSizeText(
                    festival.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: isDark ? Colors.white30 : Colors.black26,
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
        color:
            isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: Color(0xFF3F5E46), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: 'Found ',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
                children: [
                  TextSpan(
                    text: '${state.response.metadata.totalResults} results',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3F5E46),
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
        color:
            isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [typeColor, typeColor.withOpacity(0.7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: typeColor.withOpacity(0.3),
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
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1,
                              ),
                            ),
                            AutoSizeText(
                              DateFormat('y').format(festivalDate),
                              style: const TextStyle(
                                fontSize: 9,
                                color: Colors.white70,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AutoSizeText(
                            result.name,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: typeColor.withOpacity(0.2),
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
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      isDark
                                          ? Colors.white.withOpacity(0.1)
                                          : Colors.black.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.source_rounded,
                                      size: 10,
                                      color:
                                          isDark
                                              ? Colors.white60
                                              : Colors.black54,
                                    ),
                                    const SizedBox(width: 4),
                                    AutoSizeText(
                                      result.source,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color:
                                            isDark
                                                ? Colors.white60
                                                : Colors.black54,
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
                                  color:
                                      isDark ? Colors.white60 : Colors.black54,
                                ),
                                const SizedBox(width: 6),
                                AutoSizeText(
                                  DateFormat(
                                    'EEEE, MMMM d, y',
                                  ).format(festivalDate),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        isDark
                                            ? Colors.white70
                                            : Colors.black87,
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
                                  color:
                                      isDark ? Colors.white60 : Colors.black54,
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
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.black.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            isDark
                                ? Colors.white.withOpacity(0.1)
                                : Colors.black.withOpacity(0.05),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.code_rounded,
                          size: 12,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                        const SizedBox(width: 6),
                        AutoSizeText(
                          result.code!,
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
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
              color:
                  isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.celebration_outlined,
              size: 64,
              color: isDark ? Colors.white30 : Colors.black26,
            ),
          ),
          const SizedBox(height: 20),
          AutoSizeText(
            'No Festivals Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          AutoSizeText(
            'Try selecting a different date range',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.black54,
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
              color:
                  isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 64,
              color: isDark ? Colors.white30 : Colors.black26,
            ),
          ),
          const SizedBox(height: 20),
          AutoSizeText(
            'No Results Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          AutoSizeText(
            'Try a different search term',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white54 : Colors.black54,
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
