import '../../../core/theme/app_theme.dart';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grocery_app/core/theme/app_colors.dart';
import 'package:intl/intl.dart';

import '../../../common_widgets/error_state_widget.dart';
import '../../../cubits/panchang/panchang_month_cubit.dart';
import '../../../cubits/panchang/panchang_month_state.dart';
import '../../../helpers/indian_month_helper.dart';
import '../../../helpers/panchang_month_analyzer.dart';
import '../../../models/panchang/panchang_month_models.dart';
import '../../../repositories/panchang_repository.dart';

class PanchangMonthScreen extends StatefulWidget {
  const PanchangMonthScreen({super.key});

  @override
  State<PanchangMonthScreen> createState() => _PanchangMonthScreenState();
}

class _PanchangMonthScreenState extends State<PanchangMonthScreen>
    with TickerProviderStateMixin {
  late final PanchangMonthCubit _cubit;
  late final AnimationController _entranceController;
  late final AnimationController _monthTransitionController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _slideAnimation;

  // For swipe gesture
  bool _isTransitioning = false;

  @override
  void initState() {
    super.initState();
    _cubit = PanchangMonthCubit(repository: PanchangRepository());

    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _monthTransitionController = AnimationController(
      duration: const Duration(milliseconds: 400),
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
    _monthTransitionController.dispose();
    _cubit.close();
    super.dispose();
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_isTransitioning) return;

    final velocity = details.primaryVelocity ?? 0;
    if (velocity > 500) {
      _navigateToPreviousMonth();
    } else if (velocity < -500) {
      _navigateToNextMonth();
    }
  }

  Future<void> _navigateToNextMonth() async {
    if (_isTransitioning) return;
    _isTransitioning = true;
    HapticFeedback.lightImpact();
    await _cubit.nextMonth();
    _isTransitioning = false;
  }

  Future<void> _navigateToPreviousMonth() async {
    if (_isTransitioning) return;
    _isTransitioning = true;
    HapticFeedback.lightImpact();
    await _cubit.previousMonth();
    _isTransitioning = false;
  }

  void _onDayTapped(PanchangDaySummary day) {
    HapticFeedback.mediumImpact();
    // Parse the date string and navigate to day view
    final dateParts = day.date.split('-');
    if (dateParts.length == 3) {
      final year = int.tryParse(dateParts[0]) ?? DateTime.now().year;
      final month = int.tryParse(dateParts[1]) ?? DateTime.now().month;
      final dayNum = int.tryParse(dateParts[2]) ?? DateTime.now().day;
      final selectedDate = DateTime(year, month, dayNum);

      // Pop back with the selected date
      Navigator.pop(context, selectedDate);
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
            isDark ? AppColors.pureBlack : AppColors.parchment,
        body: GestureDetector(
          onHorizontalDragEnd: _onHorizontalDragEnd,
          child: Stack(
            children: [
              _buildAnimatedBackground(isDark),
              SafeArea(
                child: Column(
                  children: [
                    _buildHeader(context, theme, isDark),
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
                        child:
                            BlocBuilder<PanchangMonthCubit, PanchangMonthState>(
                              builder: (context, state) {
                                if (state is PanchangMonthLoading ||
                                    state is PanchangMonthInitial) {
                                  return _buildLoadingState(theme, isDark);
                                }

                                if (state is PanchangMonthError) {
                                  return Center(
                                    child: ErrorStateWidget(
                                      title: 'Unable to load calendar',
                                      subtitle: state.message,
                                      onRetry:
                                          () => _cubit.loadMonth(
                                            state.year,
                                            state.month,
                                          ),
                                    ),
                                  );
                                }

                                if (state is PanchangMonthSuccess) {
                                  return _buildCalendarContent(
                                    context,
                                    theme,
                                    isDark,
                                    state.data,
                                  );
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
      ),
    );
  }

  Widget _buildAnimatedBackground(bool isDark) {
    return Stack(
      children: [
        // Gradient background
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors:
                  isDark
                      ? [
                        AppColors.deepSoilGreen,
                        AppColors.deepSoilGreen,
                        AppColors.deepSoilGreen,
                      ]
                      : [
                        AppColors.parchment,
                        AppColors.parchment,
                        AppColors.parchment,
                      ],
            ),
          ),
        ),
        // Animated orbs
        Positioned(
          top: -50,
          right: -50,
          child: _GlowingOrb(
            color:
                isDark
                    ? AppColors.parchment.withValues(alpha: 0.3)
                    : AppColors.harvestAmber.withValues(alpha: 0.15),
            size: 200,
          ),
        ),
        Positioned(
          bottom: 100,
          left: -80,
          child: _GlowingOrb(
            color:
                isDark
                    ? AppColors.parchment.withValues(alpha: 0.2)
                    : AppColors.deepSoilGreen.withValues(alpha: 0.12),
            size: 180,
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          // Back button
          _GlassButton(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            isDark: isDark,
            child: Icon(
              Icons.arrow_back_rounded,
              color:
                  isDark ? AppColors.pureWhite : AppColors.charcoal,
            ),
          ),
          const Spacer(),
          AutoSizeText(
            'Month Calendar',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color:
                  isDark ? AppColors.pureWhite : AppColors.charcoal,
            ),
          ),
          const Spacer(),
          // Today button
          _GlassButton(
            onTap: () {
              HapticFeedback.lightImpact();
              _cubit.loadCurrentMonth();
            },
            isDark: isDark,
            child: Icon(
              Icons.today_rounded,
              color:
                  isDark ? AppColors.pureWhite : AppColors.charcoal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation(
                isDark ? AppColors.pureWhite : theme.primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 16),
          AutoSizeText(
            'Loading calendar...',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarContent(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    PanchangMonthResponse data,
  ) {
    // Analyze masa distribution
    final masaAnalysis = PanchangMonthAnalyzer.analyzeMasaDistribution(
      data.grid,
    );

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 8),
          // Beautiful Month Navigator
          _BeautifulMonthNavigator(
            year: data.year,
            month: data.month,
            masaAnalysis: masaAnalysis,
            onPrevious: _navigateToPreviousMonth,
            onNext: _navigateToNextMonth,
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          // Calendar Card with glass effect
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors:
                        isDark
                            ? [
                              AppColors.deepSoilGreen.withValues(alpha: 0.95),
                              const Color(0xFF3D6B28).withValues(alpha: 0.95),
                            ]
                            : [
                              AppColors.pureWhite.withValues(alpha: 0.98),
                              AppColors.pureWhite.withValues(alpha: 0.98),
                            ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: (isDark ? AppColors.pureWhite : AppColors.charcoal)
                        .withValues(alpha: 0.1),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(
                        0xFF3F5E46,
                      ).withValues(alpha: isDark ? 0.2 : 0.08),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Weekday headers
                    _WeekdayHeader(isDark: isDark),
                    const SizedBox(height: 8),
                    // Calendar Grid - Rich detailed version
                    _RichCalendarGrid(
                      grid: data.grid,
                      masaAnalysis: masaAnalysis,
                      isDark: isDark,
                      onDayTapped: _onDayTapped,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Legend
          _EnhancedLegendCard(
            isDark: isDark,
            presentMasas: masaAnalysis.presentMasas,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ============================================================================
// SUPPORTING WIDGETS
// ============================================================================

class _GlowingOrb extends StatefulWidget {
  final Color color;
  final double size;

  const _GlowingOrb({required this.color, required this.size});

  @override
  State<_GlowingOrb> createState() => _GlowingOrbState();
}

class _GlowingOrbState extends State<_GlowingOrb>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color,
                blurRadius: 60 + (_controller.value * 20),
                spreadRadius: 20 + (_controller.value * 10),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GlassButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  final bool isDark;

  const _GlassButton({
    required this.onTap,
    required this.child,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (isDark ? AppColors.pureWhite : AppColors.charcoal)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (isDark ? AppColors.pureWhite : AppColors.charcoal)
                    .withValues(alpha: 0.1),
              ),
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

class _DualMonthNavigatorCard extends StatelessWidget {
  final int year;
  final int month;
  final MasaAnalysis masaAnalysis;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final bool isDark;

  const _DualMonthNavigatorCard({
    required this.year,
    required this.month,
    required this.masaAnalysis,
    required this.onPrevious,
    required this.onNext,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monthName = DateFormat('MMMM').format(DateTime(year, month));

    // Get Indian months for this Gregorian month
    final indianMonths = IndianMonthHelper.getMonthsForGregorianMonth(month);
    final firstMasa = masaAnalysis.firstMasa;
    final lastMasa = masaAnalysis.lastMasa;

    // Build Indian month display
    String indianMonthText = '';
    if (firstMasa != null && lastMasa != null) {
      if (firstMasa == lastMasa) {
        indianMonthText = firstMasa;
      } else {
        indianMonthText = '$firstMasa | $lastMasa';
      }
    } else if (indianMonths.isNotEmpty) {
      // Fallback to expected months
      if (indianMonths.length == 2) {
        indianMonthText =
            '${indianMonths[0].sanskritName} | ${indianMonths[1].sanskritName}';
      } else {
        indianMonthText = indianMonths[0].sanskritName;
      }
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors:
                  isDark
                      ? [
                        AppColors.parchment.withValues(alpha: 0.8),
                        AppColors.parchment.withValues(alpha: 0.8),
                      ]
                      : [
                        AppColors.parchment.withValues(alpha: 0.9),
                        AppColors.parchment.withValues(alpha: 0.9),
                      ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: (isDark ? AppColors.pureWhite : AppColors.charcoal)
                  .withValues(alpha: 0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.parchment.withValues(
                  alpha: isDark ? 0.3 : 0.1,
                ),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _NavArrowButton(
                icon: Icons.chevron_left_rounded,
                onTap: onPrevious,
                isDark: isDark,
              ),
              Expanded(
                child: Column(
                  children: [
                    // Gregorian month (primary)
                    AutoSizeText(
                      monthName,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color:
                            (isDark
                                ? AppColors.parchment
                                : AppTheme
                                    .lightTheme
                                    .textTheme
                                    .bodyLarge
                                    ?.color),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Year badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.parchment.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: AutoSizeText(
                        '$year',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color:
                              isDark
                                  ? AppColors.parchment
                                  : AppColors.parchment,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Indian month (secondary)
                    if (indianMonthText.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.brightness_3,
                            size: 12,
                            color: (isDark ? AppColors.pureWhite : AppColors.charcoal)
                                .withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: AutoSizeText(
                              indianMonthText,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: (isDark ? AppColors.pureWhite : AppColors.charcoal)
                                    .withValues(alpha: 0.6),
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              _NavArrowButton(
                icon: Icons.chevron_right_rounded,
                onTap: onNext,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthNavigatorCard extends StatelessWidget {
  final int year;
  final int month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final bool isDark;

  const _MonthNavigatorCard({
    required this.year,
    required this.month,
    required this.onPrevious,
    required this.onNext,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monthName = DateFormat('MMMM').format(DateTime(year, month));

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors:
                  isDark
                      ? [
                        AppColors.parchment.withValues(alpha: 0.8),
                        AppColors.parchment.withValues(alpha: 0.8),
                      ]
                      : [
                        AppColors.parchment.withValues(alpha: 0.9),
                        AppColors.parchment.withValues(alpha: 0.9),
                      ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: (isDark ? AppColors.pureWhite : AppColors.charcoal)
                  .withValues(alpha: 0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.parchment.withValues(
                  alpha: isDark ? 0.3 : 0.1,
                ),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _NavArrowButton(
                icon: Icons.chevron_left_rounded,
                onTap: onPrevious,
                isDark: isDark,
              ),
              Expanded(
                child: Column(
                  children: [
                    AutoSizeText(
                      monthName,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color:
                            (isDark
                                ? AppColors.parchment
                                : AppTheme
                                    .lightTheme
                                    .textTheme
                                    .bodyLarge
                                    ?.color),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.parchment.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: AutoSizeText(
                        '$year',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color:
                              isDark
                                  ? AppColors.parchment
                                  : AppColors.parchment,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _NavArrowButton(
                icon: Icons.chevron_right_rounded,
                onTap: onNext,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavArrowButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;

  const _NavArrowButton({
    required this.icon,
    required this.onTap,
    required this.isDark,
  });

  @override
  State<_NavArrowButton> createState() => _NavArrowButtonState();
}

class _NavArrowButtonState extends State<_NavArrowButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: (widget.isDark ? AppColors.pureWhite : AppColors.charcoal)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                widget.icon,
                size: 28,
                color:
                    widget.isDark ? AppColors.pureWhite.withValues(alpha: 0.54) : AppColors.charcoal54,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _IndianMonthStrip extends StatelessWidget {
  final List<List<PanchangDaySummary?>> grid;
  final MasaAnalysis masaAnalysis;
  final bool isDark;

  const _IndianMonthStrip({
    required this.grid,
    required this.masaAnalysis,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (masaAnalysis.rowMasaMap.isEmpty) {
      return const SizedBox(width: 40);
    }

    return Column(
      children: List.generate(grid.length, (rowIndex) {
        final masa = masaAnalysis.rowMasaMap[rowIndex];
        if (masa == null || masa.isEmpty) {
          return const SizedBox(height: 88); // Match cell height + padding
        }

        final isTransition = masaAnalysis.transitionRows.contains(rowIndex);
        final month = IndianMonthHelper.getBySanskritName(masa);
        final color = IndianMonthHelper.getBaseColorForMasa(masa, isDark);

        return Container(
          height: 88, // Match cell height (80) + padding (8)
          width: 40,
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: isTransition ? Border.all(color: color, width: 2) : null,
          ),
          child: Center(
            child: RotatedBox(
              quarterTurns: 3,
              child: AutoSizeText(
                month?.abbreviation ?? masa.substring(0, 3).toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isTransition ? FontWeight.bold : FontWeight.w600,
                  color:
                      isDark ? AppColors.pureWhite : AppColors.charcoal,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  final bool isDark;

  const _WeekdayHeader({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Row(
      children:
          weekdays.asMap().entries.map((entry) {
            final isSunday = entry.key == 0;
            return Expanded(
              child: Center(
                child: AutoSizeText(
                  entry.value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color:
                        isSunday
                            ? (isDark
                                ? AppColors.parchment
                                : AppColors.rawEarth)
                            : (isDark
                                ? AppColors.parchment54
                                : AppColors.charcoal45),
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  final List<List<PanchangDaySummary?>> grid;
  final bool isDark;
  final ValueChanged<PanchangDaySummary> onDayTapped;

  const _CalendarGrid({
    required this.grid,
    required this.isDark,
    required this.onDayTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children:
          grid.asMap().entries.map((rowEntry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children:
                    rowEntry.value.asMap().entries.map((cellEntry) {
                      final day = cellEntry.value;
                      return Expanded(
                        child:
                            day == null
                                ? const SizedBox(height: 80)
                                : _DayCell(
                                  day: day,
                                  isDark: isDark,
                                  onTap: () => onDayTapped(day),
                                  animationDelay: Duration(
                                    milliseconds:
                                        (rowEntry.key * 50) +
                                        (cellEntry.key * 30),
                                  ),
                                ),
                      );
                    }).toList(),
              ),
            );
          }).toList(),
    );
  }
}

class _CalendarGridWithMasa extends StatelessWidget {
  final List<List<PanchangDaySummary?>> grid;
  final MasaAnalysis masaAnalysis;
  final bool isDark;
  final ValueChanged<PanchangDaySummary> onDayTapped;

  const _CalendarGridWithMasa({
    required this.grid,
    required this.masaAnalysis,
    required this.isDark,
    required this.onDayTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children:
          grid.asMap().entries.map((rowEntry) {
            final rowIndex = rowEntry.key;
            final isTransitionRow = masaAnalysis.transitionRows.contains(
              rowIndex,
            );
            final newMasa =
                isTransitionRow ? masaAnalysis.rowMasaMap[rowIndex] : null;

            return Column(
              children: [
                // Show transition banner if this row starts a new masa
                if (isTransitionRow && newMasa != null)
                  _MasaTransitionBanner(masaName: newMasa, isDark: isDark),
                // Calendar row
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children:
                        rowEntry.value.asMap().entries.map((cellEntry) {
                          final day = cellEntry.value;
                          return Expanded(
                            child:
                                day == null
                                    ? const SizedBox(height: 80)
                                    : _DayCellWithMasa(
                                      day: day,
                                      isDark: isDark,
                                      onTap: () => onDayTapped(day),
                                      animationDelay: Duration(
                                        milliseconds:
                                            (rowEntry.key * 50) +
                                            (cellEntry.key * 30),
                                      ),
                                    ),
                          );
                        }).toList(),
                  ),
                ),
              ],
            );
          }).toList(),
    );
  }
}

class _MasaTransitionBanner extends StatelessWidget {
  final String masaName;
  final bool isDark;

  const _MasaTransitionBanner({required this.masaName, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final month = IndianMonthHelper.getBySanskritName(masaName);
    final color = IndianMonthHelper.getBaseColorForMasa(masaName, isDark);

    return Container(
      margin: const EdgeInsets.only(bottom: 12, top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.0),
            color.withValues(alpha: 0.3),
            color.withValues(alpha: 0.0),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.celebration_rounded, size: 14, color: color),
          const SizedBox(width: 8),
          AutoSizeText(
            '${month?.sanskritName ?? masaName} begins',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.pureWhite.withValues(alpha: 0.54) : AppColors.charcoal54,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.celebration_rounded, size: 14, color: color),
        ],
      ),
    );
  }
}

class _DayCell extends StatefulWidget {
  final PanchangDaySummary day;
  final bool isDark;
  final VoidCallback onTap;
  final Duration animationDelay;

  const _DayCell({
    required this.day,
    required this.isDark,
    required this.onTap,
    required this.animationDelay,
  });

  @override
  State<_DayCell> createState() => _DayCellState();
}

class _DayCellState extends State<_DayCell>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future.delayed(widget.animationDelay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showDayDetails() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: AppColors.charcoal.withValues(alpha: 0.5),
      builder:
          (context) => BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: _DayDetailsDialog(day: widget.day, isDark: widget.isDark),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final day = widget.day;
    final hasFestival = day.festivals.isNotEmpty || day.majorFestivalsCount > 0;
    final hasVrat = day.vratsCount > 0;
    final isSunday = day.weekday == 0;

    // Determine cell color
    Color cellColor;
    if (day.isToday) {
      cellColor = AppColors.parchment;
    } else if (hasFestival) {
      cellColor =
          widget.isDark
              ? AppColors.parchment.withValues(alpha: 0.2)
              : AppColors.parchment.withValues(alpha: 0.15);
    } else {
      cellColor = (widget.isDark ? AppColors.pureWhite : AppColors.charcoal)
          .withValues(alpha: 0.05);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(opacity: _opacityAnimation.value, child: child),
        );
      },
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: _showDayDetails,
        child: Container(
          height: 80,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: cellColor,
            borderRadius: BorderRadius.circular(12),
            border:
                day.isToday
                    ? null
                    : Border.all(
                      color: (widget.isDark ? AppColors.pureWhite : AppColors.charcoal)
                          .withValues(alpha: 0.08),
                    ),
            boxShadow:
                day.isToday
                    ? [
                      BoxShadow(
                        color: AppColors.parchment.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                    : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Day number
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AutoSizeText(
                      '${day.dayNumber}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color:
                            day.isToday
                                ? AppColors.parchment
                                : isSunday
                                ? (widget.isDark
                                    ? AppColors.parchment
                                    : AppColors.rawEarth)
                                : (widget.isDark ? AppColors.pureWhite : AppColors.charcoal),
                      ),
                    ),
                    if (hasFestival)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              day.isToday
                                  ? AppColors.parchment
                                  : AppColors.parchment,
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                // Tithi (truncated)
                AutoSizeText(
                  day.tithi,
                  style: TextStyle(
                    fontSize: 9,
                    color:
                        day.isToday
                            ? AppColors.parchment54
                            : (widget.isDark
                                ? AppColors.parchment54
                                : AppColors.charcoal45),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                // Festival indicator
                if (hasFestival && day.festivals.isNotEmpty)
                  AutoSizeText(
                    day.festivals.first.name,
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      color:
                          day.isToday
                              ? AppColors.parchment
                              : AppColors.parchment,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                // Vrat indicator
                if (hasVrat && !hasFestival)
                  Row(
                    children: [
                      Icon(
                        Icons.brightness_3,
                        size: 8,
                        color:
                            day.isToday
                                ? AppColors.parchment54
                                : (widget.isDark
                                    ? AppColors.parchment
                                    : AppColors.deepSoilGreen),
                      ),
                      const SizedBox(width: 2),
                      AutoSizeText(
                        'Vrat',
                        style: TextStyle(
                          fontSize: 8,
                          color:
                              day.isToday
                                  ? AppColors.parchment54
                                  : (widget.isDark
                                      ? AppColors.parchment
                                      : AppColors.deepSoilGreen),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DayCellWithMasa extends StatefulWidget {
  final PanchangDaySummary day;
  final bool isDark;
  final VoidCallback onTap;
  final Duration animationDelay;

  const _DayCellWithMasa({
    required this.day,
    required this.isDark,
    required this.onTap,
    required this.animationDelay,
  });

  @override
  State<_DayCellWithMasa> createState() => _DayCellWithMasaState();
}

class _DayCellWithMasaState extends State<_DayCellWithMasa>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future.delayed(widget.animationDelay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showDayDetails() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: AppColors.charcoal.withValues(alpha: 0.5),
      builder:
          (context) => BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: _DayDetailsDialog(day: widget.day, isDark: widget.isDark),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final day = widget.day;
    final hasFestival = day.festivals.isNotEmpty || day.majorFestivalsCount > 0;
    final hasVrat = day.vratsCount > 0;
    final isSunday = day.weekday == 0;

    // Get masa color
    final masaColor = IndianMonthHelper.getColorForMasa(
      day.masa,
      widget.isDark,
      opacity: 0.15,
    );

    // Determine cell color
    Color cellColor;
    if (day.isToday) {
      cellColor = AppColors.parchment;
    } else if (hasFestival) {
      cellColor =
          widget.isDark
              ? AppColors.parchment.withValues(alpha: 0.25)
              : AppColors.parchment.withValues(alpha: 0.2);
    } else {
      // Use masa color as base
      cellColor = masaColor;
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(opacity: _opacityAnimation.value, child: child),
        );
      },
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: _showDayDetails,
        child: Container(
          height: 80,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: cellColor,
            borderRadius: BorderRadius.circular(12),
            border:
                day.isToday
                    ? null
                    : Border.all(
                      color: (widget.isDark ? AppColors.pureWhite : AppColors.charcoal)
                          .withValues(alpha: 0.08),
                    ),
            boxShadow:
                day.isToday
                    ? [
                      BoxShadow(
                        color: AppColors.parchment.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                    : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Day number
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AutoSizeText(
                      '${day.dayNumber}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color:
                            day.isToday
                                ? AppColors.parchment
                                : isSunday
                                ? (widget.isDark
                                    ? AppColors.parchment
                                    : AppColors.rawEarth)
                                : (widget.isDark ? AppColors.pureWhite : AppColors.charcoal),
                      ),
                    ),
                    if (hasFestival)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              day.isToday
                                  ? AppColors.parchment
                                  : AppColors.parchment,
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                // Tithi (truncated)
                AutoSizeText(
                  day.tithi,
                  style: TextStyle(
                    fontSize: 9,
                    color:
                        day.isToday
                            ? AppColors.parchment54
                            : (widget.isDark
                                ? AppColors.parchment54
                                : AppColors.charcoal45),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                // Festival indicator
                if (hasFestival && day.festivals.isNotEmpty)
                  AutoSizeText(
                    day.festivals.first.name,
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      color:
                          day.isToday
                              ? AppColors.parchment
                              : AppColors.parchment,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                // Vrat indicator
                if (hasVrat && !hasFestival)
                  Row(
                    children: [
                      Icon(
                        Icons.brightness_3,
                        size: 8,
                        color:
                            day.isToday
                                ? AppColors.parchment54
                                : (widget.isDark
                                    ? AppColors.parchment
                                    : AppColors.deepSoilGreen),
                      ),
                      const SizedBox(width: 2),
                      AutoSizeText(
                        'Vrat',
                        style: TextStyle(
                          fontSize: 8,
                          color:
                              day.isToday
                                  ? AppColors.parchment54
                                  : (widget.isDark
                                      ? AppColors.parchment
                                      : AppColors.deepSoilGreen),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LegendCard extends StatelessWidget {
  final bool isDark;

  const _LegendCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: (isDark ? AppColors.pureWhite : AppColors.charcoal)
                .withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: (isDark ? AppColors.pureWhite : AppColors.charcoal)
                  .withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AutoSizeText(
                'Legend',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.pureWhite.withValues(alpha: 0.54) : AppColors.charcoal54,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _LegendItem(
                    color: isDark ? AppColors.pureWhite : AppColors.parchment,
                    label: 'Today',
                    isDark: isDark,
                  ),
                  const SizedBox(width: 20),
                  _LegendItem(
                    color: isDark ? AppColors.pureWhite : AppColors.parchment,
                    label: 'Festival',
                    isDark: isDark,
                  ),
                        SizedBox(width: 20),
                  _LegendItem(
                    color:
                        isDark ? AppColors.pureWhite : AppColors.deepSoilGreen,
                    label: 'Vrat',
                    isDark: isDark,
                    icon: Icons.brightness_3,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool isDark;
  final IconData? icon;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.isDark,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon != null
            ? Icon(icon, size: 12, color: color)
            : Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
        const SizedBox(width: 6),
        AutoSizeText(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.pureWhite.withValues(alpha: 0.54) : AppColors.charcoal45,
          ),
        ),
      ],
    );
  }
}

class _EnhancedLegendCard extends StatelessWidget {
  final bool isDark;
  final List<String> presentMasas;

  const _EnhancedLegendCard({required this.isDark, required this.presentMasas});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: (isDark ? AppColors.pureWhite : AppColors.charcoal)
                .withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: (isDark ? AppColors.pureWhite : AppColors.charcoal)
                  .withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AutoSizeText(
                'Legend',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.pureWhite.withValues(alpha: 0.54) : AppColors.charcoal54,
                ),
              ),
              const SizedBox(height: 12),
              // Basic indicators
              Row(
                children: [
                  _LegendItem(
                    color: isDark ? AppColors.pureWhite : AppColors.parchment,
                    label: 'Today',
                    isDark: isDark,
                  ),
                  const SizedBox(width: 20),
                  _LegendItem(
                    color: isDark ? AppColors.pureWhite : AppColors.parchment,
                    label: 'Festival',
                    isDark: isDark,
                  ),
                        SizedBox(width: 20),
                  _LegendItem(
                    color:
                        isDark ? AppColors.pureWhite : AppColors.deepSoilGreen,
                    label: 'Vrat',
                    isDark: isDark,
                    icon: Icons.brightness_3,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Indian months section
              AutoSizeText(
                'Indian Months',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.pureWhite.withValues(alpha: 0.60) : AppColors.charcoal45,
                ),
              ),
              const SizedBox(height: 8),
              // Show present masas
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    presentMasas.map((masa) {
                      final month = IndianMonthHelper.getBySanskritName(masa);
                      final color = IndianMonthHelper.getBaseColorForMasa(
                        masa,
                        isDark,
                      );

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: color.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            AutoSizeText(
                              month?.sanskritName ?? masa,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color:
                                    (isDark
                                        ? AppTheme
                                            .darkTheme
                                            .textTheme
                                            .bodyLarge
                                            ?.color
                                        : AppTheme
                                            .lightTheme
                                            .textTheme
                                            .bodyLarge
                                            ?.color),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayDetailsDialog extends StatelessWidget {
  final PanchangDaySummary day;
  final bool isDark;

  const _DayDetailsDialog({required this.day, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final month = IndianMonthHelper.getBySanskritName(day.masa);
    final masaColor = IndianMonthHelper.getBaseColorForMasa(day.masa, isDark);
    final hasFestival = day.festivals.isNotEmpty;
    final hasVrat = day.vratsCount > 0;

    return Dialog(
      backgroundColor: AppColors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 380),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors:
                isDark
                    ? [
                      (isDark
                              ? AppColors.parchment
                              : AppColors.deepSoilGreen)
                          .withAlpha(200),
                      (isDark
                          ? AppColors.parchment
                          : AppColors.deepSoilGreen),
                    ]
                    : [
                      (isDark
                          ? AppColors.parchment
                          : AppColors.deepSoilGreen),
                      (isDark
                              ? AppColors.parchment
                              : AppColors.deepSoilGreen)
                          .withAlpha(200),
                    ],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: masaColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: masaColor.withValues(alpha: 0.2),
              blurRadius: 40,
              spreadRadius: 0,
            ),
            BoxShadow(
              color: AppColors.charcoal.withValues(alpha: 0.3),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with gradient accent
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    masaColor.withValues(alpha: 0.15),
                    AppColors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Stack(
                children: [
                  // Close button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: (isDark ? AppColors.pureWhite : AppColors.charcoal)
                              .withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: (isDark ? AppColors.pureWhite : AppColors.charcoal)
                              .withValues(alpha: 0.6),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  // Date display
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 60, 16),
                    child: Row(
                      children: [
                        // Day number with glow
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                masaColor,
                                masaColor.withValues(alpha: 0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: masaColor.withValues(alpha: 0.5),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AutoSizeText(
                                '${day.dayNumber}',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  color: isDark ? AppColors.pureWhite : AppColors.parchment,
                                  fontWeight: FontWeight.bold,
                                  height: 1,
                                ),
                              ),
                              AutoSizeText(
                                DateFormat('EEE')
                                    .format(DateTime.parse(day.date))
                                    .toUpperCase(),
                                style: TextStyle(
                                  color: AppColors.parchment.withValues(
                                    alpha: 0.9,
                                  ),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Month & Year
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AutoSizeText(
                                DateFormat(
                                  'MMMM yyyy',
                                ).format(DateTime.parse(day.date)),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      (isDark
                                          ? AppTheme
                                              .darkTheme
                                              .textTheme
                                              .bodyLarge
                                              ?.color
                                          : AppTheme
                                              .lightTheme
                                              .textTheme
                                              .bodyLarge
                                              ?.color),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: masaColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: masaColor.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: AutoSizeText(
                                  month?.sanskritName ?? day.masa,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: masaColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Tithi Banner
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.parchment.withValues(alpha: isDark ? 0.2 : 0.1),
                    AppColors.parchment.withValues(alpha: isDark ? 0.2 : 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.parchment.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.parchment.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.nightlight_round,
                      size: 18,
                      color: isDark ? AppColors.pureWhite : AppColors.parchment,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AutoSizeText(
                          'Tithi',
                          style: TextStyle(
                            fontSize: 11,
                            color: (isDark ? AppColors.pureWhite : AppColors.charcoal)
                                .withValues(alpha: 0.5),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        AutoSizeText(
                          day.tithi,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color:
                                (isDark
                                    ? AppTheme
                                        .darkTheme
                                        .textTheme
                                        .bodyLarge
                                        ?.color
                                    : AppTheme
                                        .lightTheme
                                        .textTheme
                                        .bodyLarge
                                        ?.color),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Quick Info Row (Sun/Moon)
            if (day.sunrise != null || day.moonrise != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    if (day.sunrise != null)
                      Expanded(
                        child: _CompactTimingTile(
                          icon: Icons.wb_sunny_rounded,
                          label: 'Sunrise',
                          time: DateFormat(
                            'h:mm a',
                          ).format(day.sunrise!.toLocal()),
                          color: isDark ? AppColors.pureWhite : AppColors.parchment,
                          isDark: isDark,
                        ),
                      ),
                    if (day.sunrise != null && day.sunset != null)
                      const SizedBox(width: 10),
                    if (day.sunset != null)
                      Expanded(
                        child: _CompactTimingTile(
                          icon: Icons.nights_stay_rounded,
                          label: 'Sunset',
                          time: DateFormat(
                            'h:mm a',
                          ).format(day.sunset!.toLocal()),
                          color: isDark ? AppColors.pureWhite : AppColors.parchment,
                          isDark: isDark,
                        ),
                      ),
                  ],
                ),
              ),

            // Festivals Section
            if (hasFestival) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  padding:       EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(
                          0xFFFFAA33,
                        ).withValues(alpha: isDark ? 0.15 : 0.1),
                        const Color(
                          0xFFFF8833,
                        ).withValues(alpha: isDark ? 0.1 : 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.parchment.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.celebration_rounded,
                            size: 16,
                            color: isDark ? AppColors.pureWhite : AppColors.parchment,
                          ),
                          const SizedBox(width: 8),
                          AutoSizeText(
                            'Festivals',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.pureWhite : AppColors.parchment,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding:       EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.parchment.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: AutoSizeText(
                              '${day.festivals.length}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.pureWhite : AppColors.parchment,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...day.festivals
                          .take(3)
                          .map(
                            (festival) => Padding(
                              padding:       EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: isDark ? AppColors.pureWhite : AppColors.parchment,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: AutoSizeText(
                                      festival.name,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color:
                                                isDark ? AppColors.pureWhite : AppColors.charcoal,
                                            fontWeight: FontWeight.w500,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      if (day.festivals.length > 3)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: AutoSizeText(
                            '+${day.festivals.length - 3} more',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.pureWhite : AppColors.parchment,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],

            // Vrats indicator
            if (hasVrat) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding:       EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(
                          0xFF66D9FF,
                        ).withValues(alpha: isDark ? 0.15 : 0.1),
                        const Color(
                          0xFF33BBFF,
                        ).withValues(alpha: isDark ? 0.1 : 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.parchment.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.self_improvement_rounded,
                        size: 20,
                        color: isDark ? AppColors.pureWhite : AppColors.parchment,
                      ),
                      const SizedBox(width: 12),
                      AutoSizeText(
                        '${day.vratsCount} Vrat${day.vratsCount > 1 ? 's' : ''}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color:
                              (isDark
                                  ? AppTheme
                                      .darkTheme
                                      .textTheme
                                      .bodyLarge
                                      ?.color
                                  : AppTheme
                                      .lightTheme
                                      .textTheme
                                      .bodyLarge
                                      ?.color),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _CompactTimingTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String time;
  final Color color;
  final bool isDark;

  const _CompactTimingTile({
    required this.icon,
    required this.label,
    required this.time,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AutoSizeText(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: (isDark ? AppColors.pureWhite : AppColors.charcoal)
                      .withValues(alpha: 0.5),
                ),
              ),
              AutoSizeText(
                time,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color:
                      isDark ? AppColors.pureWhite : AppColors.charcoal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final bool isDark;
  final Widget child;

  const _DetailCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: (isDark ? AppColors.pureWhite : AppColors.charcoal)
                .withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: color),
                  const SizedBox(width: 8),
                  AutoSizeText(
                    title,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: (isDark ? AppColors.pureWhite : AppColors.charcoal)
                          .withValues(alpha: 0.6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _TimingItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String time;
  final bool isDark;

  const _TimingItem({
    required this.icon,
    required this.label,
    required this.time,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(
          icon,
          size: 24,
          color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(
            alpha: 0.7,
          ),
        ),
        const SizedBox(height: 4),
        AutoSizeText(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: (isDark ? AppColors.pureWhite : AppColors.charcoal)
                .withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 2),
        AutoSizeText(
          time,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color:
                isDark ? AppColors.pureWhite : AppColors.charcoal,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// NEW BEAUTIFUL CALENDAR WIDGETS
// ============================================================================

class _BeautifulMonthNavigator extends StatelessWidget {
  final int year;
  final int month;
  final MasaAnalysis masaAnalysis;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final bool isDark;

  const _BeautifulMonthNavigator({
    required this.year,
    required this.month,
    required this.masaAnalysis,
    required this.onPrevious,
    required this.onNext,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monthName = DateFormat('MMMM').format(DateTime(year, month));

    // Get Indian months info
    final firstMasa = masaAnalysis.firstMasa;
    final lastMasa = masaAnalysis.lastMasa;
    final firstMasaMonth =
        firstMasa != null
            ? IndianMonthHelper.getBySanskritName(firstMasa)
            : null;
    final lastMasaMonth =
        lastMasa != null && lastMasa != firstMasa
            ? IndianMonthHelper.getBySanskritName(lastMasa)
            : null;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              isDark
                  ? [
                    AppColors.parchment.withValues(alpha: 0.6),
                    AppColors.parchment.withValues(alpha: 0.8),
                  ]
                  : [
                    AppColors.parchment.withValues(alpha: 0.95),
                    AppColors.parchment.withValues(alpha: 0.95),
                  ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(
            alpha: 0.1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.parchment.withValues(alpha: isDark ? 0.25 : 0.1),
            blurRadius: 25,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Previous button
          _AnimatedNavButton(
            icon: Icons.chevron_left_rounded,
            onTap: onPrevious,
            isDark: isDark,
          ),

          // Center content
          Expanded(
            child: Column(
              children: [
                // Gregorian Month & Year
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AutoSizeText(
                      monthName,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color:
                            (isDark
                                ? AppColors.parchment
                                : AppTheme
                                    .lightTheme
                                    .textTheme
                                    .bodyLarge
                                    ?.color),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.parchment.withValues(alpha: 0.2),
                            AppColors.parchment.withValues(alpha: 0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: AutoSizeText(
                        '$year',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color:
                              isDark
                                  ? AppColors.parchment
                                  : AppColors.parchment,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Indian Months Pills
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (firstMasaMonth != null)
                      _MasaPill(month: firstMasaMonth, isDark: isDark),
                    if (lastMasaMonth != null) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: (isDark ? AppColors.pureWhite : AppColors.charcoal)
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      _MasaPill(month: lastMasaMonth, isDark: isDark),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Next button
          _AnimatedNavButton(
            icon: Icons.chevron_right_rounded,
            onTap: onNext,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _MasaPill extends StatelessWidget {
  final IndianMonth month;
  final bool isDark;

  const _MasaPill({required this.month, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = isDark ? month.lightColor : month.darkColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6),
              ],
            ),
          ),
          const SizedBox(width: 8),
          AutoSizeText(
            month.sanskritName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedNavButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;

  const _AnimatedNavButton({
    required this.icon,
    required this.onTap,
    required this.isDark,
  });

  @override
  State<_AnimatedNavButton> createState() => _AnimatedNavButtonState();
}

class _AnimatedNavButtonState extends State<_AnimatedNavButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.85,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors:
                      widget.isDark
                          ? [
                            AppColors.parchment.withValues(alpha: 0.3),
                            AppColors.parchment.withValues(alpha: 0.1),
                          ]
                          : [
                            AppColors.parchment.withValues(alpha: 0.15),
                            AppColors.parchment.withValues(alpha: 0.05),
                          ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.parchment.withValues(alpha: 0.2),
                ),
              ),
              child: Icon(
                widget.icon,
                size: 28,
                color:
                    (widget.isDark
                        ? AppColors.charcoal
                        : AppColors.parchment),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BeautifulWeekdayHeader extends StatelessWidget {
  final bool isDark;

  const _BeautifulWeekdayHeader({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    final fullNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Row(
      children:
          weekdays.asMap().entries.map((entry) {
            final isSunday = entry.key == 0;
            final isSaturday = entry.key == 6;

            return Expanded(
              child: Tooltip(
                message: fullNames[entry.key],
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color:
                        isSunday
                            ? const Color(
                              0xFFFF6B9D,
                            ).withValues(alpha: isDark ? 0.15 : 0.1)
                            : isSaturday
                            ? const Color(
                              0xFF3F5E46,
                            ).withValues(alpha: isDark ? 0.15 : 0.1)
                            : AppColors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: AutoSizeText(
                      entry.value,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color:
                            isSunday
                                ? (isDark
                                    ? AppColors.parchment
                                    : AppColors.rawEarth)
                                : isSaturday
                                ? (isDark
                                    ? AppColors.parchment
                                    : AppColors.parchment)
                                : (isDark
                                    ? AppColors.parchment60
                                    : AppColors.charcoal54),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }
}

// Rich Calendar Grid with detailed day cells (colors, tithi, festivals)
class _RichCalendarGrid extends StatelessWidget {
  final List<List<PanchangDaySummary?>> grid;
  final MasaAnalysis masaAnalysis;
  final bool isDark;
  final ValueChanged<PanchangDaySummary> onDayTapped;

  const _RichCalendarGrid({
    required this.grid,
    required this.masaAnalysis,
    required this.isDark,
    required this.onDayTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children:
          grid.asMap().entries.map((rowEntry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children:
                    rowEntry.value.asMap().entries.map((cellEntry) {
                      final day = cellEntry.value;
                      return Expanded(
                        child:
                            day == null
                                ? const SizedBox(height: 74)
                                : _RichDayCell(
                                  day: day,
                                  isDark: isDark,
                                  onTap: () => onDayTapped(day),
                                  animationDelay: Duration(
                                    milliseconds:
                                        (rowEntry.key * 40) +
                                        (cellEntry.key * 20),
                                  ),
                                ),
                      );
                    }).toList(),
              ),
            );
          }).toList(),
    );
  }
}

class _RichDayCell extends StatefulWidget {
  final PanchangDaySummary day;
  final bool isDark;
  final VoidCallback onTap;
  final Duration animationDelay;

  const _RichDayCell({
    required this.day,
    required this.isDark,
    required this.onTap,
    required this.animationDelay,
  });

  @override
  State<_RichDayCell> createState() => _RichDayCellState();
}

class _RichDayCellState extends State<_RichDayCell>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future.delayed(widget.animationDelay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showDayDetails() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: AppColors.charcoal.withValues(alpha: 0.5),
      builder:
          (context) => BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: _DayDetailsDialog(day: widget.day, isDark: widget.isDark),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final day = widget.day;
    final hasFestival = day.festivals.isNotEmpty || day.majorFestivalsCount > 0;
    final hasVrat = day.vratsCount > 0;
    final isSunday = day.weekday == 0;
    final isSaturday = day.weekday == 6;

    // Determine cell color based on events
    Color cellColor;

    if (day.isToday) {
      cellColor = AppColors.parchment;
    } else if (hasFestival) {
      cellColor = const Color(
        0xFFFFAA33,
      ).withValues(alpha: widget.isDark ? 0.15 : 0.1);
    } else if (hasVrat) {
      cellColor = const Color(
        0xFF66D9FF,
      ).withValues(alpha: widget.isDark ? 0.1 : 0.06);
    } else {
      cellColor = (widget.isDark ? AppColors.pureWhite : AppColors.charcoal)
          .withValues(alpha: 0.04);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(opacity: _opacityAnimation.value, child: child),
        );
      },
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: _showDayDetails,
        child: Container(
          height: 74,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            gradient:
                day.isToday
                    ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: widget.isDark ? [AppColors.charcoal, const Color(0xFF222222)] : [AppColors.deepSoilGreen, const Color(0xFF3A6B24)],
                    )
                    : hasFestival
                    ? LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(
                          0xFFFFAA33,
                        ).withValues(alpha: widget.isDark ? 0.2 : 0.15),
                        const Color(
                          0xFFFF8800,
                        ).withValues(alpha: widget.isDark ? 0.08 : 0.05),
                      ],
                    )
                    : null,
            color: (day.isToday || hasFestival) ? null : cellColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow:
                day.isToday
                    ? [
                      BoxShadow(
                        color: AppColors.parchment.withValues(alpha: 0.5),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                    : hasFestival
                    ? [
                      // Burning/glow effect for festivals
                      BoxShadow(
                        color: AppColors.parchment.withValues(alpha: 0.4),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: AppColors.parchment.withValues(alpha: 0.2),
                        blurRadius: 12,
                        spreadRadius: -2,
                      ),
                    ]
                    : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Day number + indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AutoSizeText(
                      '${day.dayNumber}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color:
                            day.isToday
                                ? AppColors.parchment
                                : isSunday
                                ? (widget.isDark
                                    ? AppColors.parchment
                                    : AppColors.rawEarth)
                                : isSaturday
                                ? (widget.isDark
                                    ? AppColors.parchment
                                    : AppColors.parchment)
                                : (widget.isDark ? AppColors.pureWhite : AppColors.charcoal),
                      ),
                    ),
                    // Event indicators
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (hasFestival)
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color:
                                  day.isToday
                                      ? AppColors.parchment
                                      : AppColors.parchment,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: (day.isToday
                                          ? AppColors.parchment
                                          : AppColors.parchment)
                                      .withValues(alpha: 0.6),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        if (hasVrat) ...[
                          if (hasFestival) const SizedBox(width: 3),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color:
                                  day.isToday
                                      ? AppColors.parchment54
                                      : AppColors.parchment,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: (day.isToday
                                          ? AppColors.parchment54
                                          : AppColors.parchment)
                                      .withValues(alpha: 0.5),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                // Tithi
                AutoSizeText(
                  day.tithi,
                  style: TextStyle(
                    fontSize: 8,
                    color:
                        day.isToday
                            ? AppColors.parchment.withValues(alpha: 0.8)
                            : (widget.isDark
                                ? AppColors.parchment54
                                : AppColors.charcoal45),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                // Festival name (if any)
                if (hasFestival && day.festivals.isNotEmpty)
                  AutoSizeText(
                    day.festivals.first.name,
                    style: TextStyle(
                      fontSize: 7,
                      fontWeight: FontWeight.w600,
                      color:
                          day.isToday
                              ? AppColors.parchment
                              : AppColors.parchment,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                else if (hasVrat)
                  Row(
                    children: [
                      Icon(
                        Icons.brightness_3,
                        size: 7,
                        color:
                            day.isToday
                                ? AppColors.parchment54
                                : AppColors.parchment,
                      ),
                      const SizedBox(width: 2),
                      AutoSizeText(
                        'Vrat',
                        style: TextStyle(
                          fontSize: 7,
                          fontWeight: FontWeight.w500,
                          color:
                              day.isToday
                                  ? AppColors.parchment54
                                  : AppColors.parchment,
                        ),
                      ),
                    ],
                  )
                else
                  const SizedBox(height: 9),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BeautifulCalendarGrid extends StatelessWidget {
  final List<List<PanchangDaySummary?>> grid;
  final MasaAnalysis masaAnalysis;
  final bool isDark;
  final ValueChanged<PanchangDaySummary> onDayTapped;

  const _BeautifulCalendarGrid({
    required this.grid,
    required this.masaAnalysis,
    required this.isDark,
    required this.onDayTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children:
          grid.asMap().entries.map((rowEntry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children:
                    rowEntry.value.asMap().entries.map((cellEntry) {
                      final day = cellEntry.value;
                      return Expanded(
                        child:
                            day == null
                                ? const SizedBox(height: 62)
                                : _BeautifulDayCell(
                                  day: day,
                                  isDark: isDark,
                                  onTap: () => onDayTapped(day),
                                  animationDelay: Duration(
                                    milliseconds:
                                        (rowEntry.key * 40) +
                                        (cellEntry.key * 20),
                                  ),
                                ),
                      );
                    }).toList(),
              ),
            );
          }).toList(),
    );
  }
}

class _BeautifulDayCell extends StatefulWidget {
  final PanchangDaySummary day;
  final bool isDark;
  final VoidCallback onTap;
  final Duration animationDelay;

  const _BeautifulDayCell({
    required this.day,
    required this.isDark,
    required this.onTap,
    required this.animationDelay,
  });

  @override
  State<_BeautifulDayCell> createState() => _BeautifulDayCellState();
}

class _BeautifulDayCellState extends State<_BeautifulDayCell>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future.delayed(widget.animationDelay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showDayDetails() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: AppColors.charcoal.withValues(alpha: 0.5),
      builder:
          (context) => BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: _DayDetailsDialog(day: widget.day, isDark: widget.isDark),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final day = widget.day;
    final hasFestival = day.festivals.isNotEmpty || day.majorFestivalsCount > 0;
    final hasVrat = day.vratsCount > 0;
    final isSunday = day.weekday == 0;
    final isSaturday = day.weekday == 6;
    final masaColor = IndianMonthHelper.getBaseColorForMasa(
      day.masa,
      widget.isDark,
    );

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(opacity: _opacityAnimation.value, child: child),
        );
      },
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: _showDayDetails,
        child: Container(
          height: 62,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            gradient:
                day.isToday
                    ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: widget.isDark ? [AppColors.charcoal, const Color(0xFF222222)] : [AppColors.deepSoilGreen, const Color(0xFF3A6B24)],
                    )
                    : null,
            color:
                day.isToday
                    ? null
                    : hasFestival
                    ? const Color(
                      0xFFFFAA33,
                    ).withValues(alpha: widget.isDark ? 0.12 : 0.1)
                    : (widget.isDark ? AppColors.pureWhite : AppColors.charcoal)
                        .withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(14),
            border:
                day.isToday
                    ? null
                    : Border.all(
                      color:
                          hasFestival
                              ? AppColors.parchment.withValues(alpha: 0.3)
                              : (widget.isDark ? AppColors.pureWhite : AppColors.charcoal)
                                  .withValues(alpha: 0.06),
                      width: 1,
                    ),
            boxShadow:
                day.isToday
                    ? [
                      BoxShadow(
                        color: AppColors.parchment.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                    : null,
          ),
          child: Stack(
            children: [
              // Masa color indicator (top-left corner)
              if (!day.isToday)
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: masaColor.withValues(alpha: 0.7),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(14),
                        bottomRight: Radius.circular(8),
                      ),
                    ),
                  ),
                ),
              // Main content
              Padding(
                padding: const EdgeInsets.all(6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Day number
                    AutoSizeText(
                      '${day.dayNumber}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color:
                            day.isToday
                                ? AppColors.parchment
                                : isSunday
                                ? (widget.isDark
                                    ? AppColors.parchment
                                    : AppColors.rawEarth)
                                : isSaturday
                                ? (widget.isDark
                                    ? AppColors.parchment
                                    : AppColors.parchment)
                                : (widget.isDark ? AppColors.pureWhite : AppColors.charcoal),
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Festival/Vrat indicator
                    if (hasFestival || hasVrat)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (hasFestival)
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color:
                                    day.isToday
                                        ? AppColors.parchment
                                        : AppColors.parchment,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: (day.isToday
                                            ? AppColors.parchment
                                            : AppColors.parchment)
                                        .withValues(alpha: 0.5),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          if (hasFestival && hasVrat) const SizedBox(width: 4),
                          if (hasVrat)
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color:
                                    day.isToday
                                        ? AppColors.parchment54
                                        : AppColors.parchment,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: (day.isToday
                                            ? AppColors.parchment54
                                            : AppColors.parchment)
                                        .withValues(alpha: 0.5),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                        ],
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
}

class _BeautifulLegendCard extends StatelessWidget {
  final bool isDark;
  final List<String> presentMasas;

  const _BeautifulLegendCard({
    required this.isDark,
    required this.presentMasas,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors:
                  isDark
                      ? [
                        AppColors.parchment.withValues(alpha: 0.7),
                        AppColors.parchment.withValues(alpha: 0.8),
                      ]
                      : [
                        AppColors.parchment.withValues(alpha: 0.9),
                        AppColors.parchment.withValues(alpha: 0.9),
                      ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: (isDark ? AppColors.pureWhite : AppColors.charcoal)
                  .withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.parchment.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.palette_outlined,
                      size: 18,
                      color: isDark ? AppColors.pureWhite : AppColors.parchment,
                    ),
                  ),
                  const SizedBox(width: 12),
                  AutoSizeText(
                    'Legend',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color:
                          isDark ? AppColors.pureWhite : AppColors.charcoal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Indicator Row
              Row(
                children: [
                  _LegendItem(
                    color: isDark ? AppColors.pureWhite : AppColors.parchment,
                    label: 'Festival',
                    isDark: isDark,
                  ),
                  const SizedBox(width: 20),
                  _LegendItem(
                    color: isDark ? AppColors.pureWhite : AppColors.parchment,
                    label: 'Vrat',
                    isDark: isDark,
                  ),
                  const SizedBox(width: 20),
                  _LegendItem(
                    color: isDark ? AppColors.pureWhite : AppColors.parchment,
                    label: 'Today',
                    isDark: isDark,
                  ),
                ],
              ),

              // Indian Months (if present)
              if (presentMasas.isNotEmpty) ...[
                      SizedBox(height: 16),
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.transparent,
                        (isDark ? AppColors.pureWhite : AppColors.charcoal)
                            .withValues(alpha: 0.1),
                        AppColors.transparent,
                      ],
                    ),
                  ),
                ),
                      SizedBox(height: 16),
                AutoSizeText(
                  'Indian Months',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: (isDark ? AppColors.pureWhite : AppColors.charcoal)
                        .withValues(alpha: 0.5),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      presentMasas.map((masa) {
                        final month = IndianMonthHelper.getBySanskritName(masa);
                        final color = IndianMonthHelper.getBaseColorForMasa(
                          masa,
                          isDark,
                        );

                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: color.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              AutoSizeText(
                                month?.sanskritName ?? masa,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      (isDark
                                          ? AppTheme
                                              .darkTheme
                                              .textTheme
                                              .bodyLarge
                                              ?.color
                                          : AppTheme
                                              .lightTheme
                                              .textTheme
                                              .bodyLarge
                                              ?.color),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
