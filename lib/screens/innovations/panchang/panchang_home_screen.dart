import 'dart:ui';

import 'package:grocery_app/common_widgets/global_import.dart';

import '../../../cubits/panchang/panchang_home_cubit.dart';
import '../../../cubits/panchang/panchang_home_state.dart';
import '../../../repositories/panchang_repository.dart';
import '../../../models/panchang/panchang_highlights_models.dart';
import '../../../models/panchang/panchang_day_models.dart';
import '../../../models/panchang/panchang_guidance_models.dart';
import 'panchang_month_screen.dart';
import 'panchang_festivals_screen.dart';
import 'panchang_advanced_timings_screen.dart';
import 'panchang_vrat_calendar_screen.dart';
import 'panchang_guidance_screen.dart';

/// Modern redesigned Panchang Calendar Home Screen
/// Features:
/// - Hero header with date selector
/// - Today's panchang with visual timeline
/// - Upcoming festivals highlights
/// - Quick action cards
/// - Smooth animations and transitions
class PanchangHomeScreen extends StatefulWidget {
  const PanchangHomeScreen({super.key});

  @override
  State<PanchangHomeScreen> createState() => _PanchangHomeScreenState();
}

class _PanchangHomeScreenState extends State<PanchangHomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _floatingController;
  late final AnimationController _shimmerController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _floatingAnimation;
  late final Animation<double> _shimmerAnimation;
  late final PanchangHomeCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = PanchangHomeCubit(repository: PanchangRepository());

    // Entrance animation
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    // Floating animation for cards
    _floatingController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _floatingAnimation = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );

    // Shimmer animation for loading
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);

    _shimmerAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    _entranceController.forward();
    _cubit.loadToday();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _floatingController.dispose();
    _shimmerController.dispose();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Stack(
          children: [
            // Animated background
            _buildAnimatedBackground(isDark, theme),

            // Main content
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Hero header with date selector
                _buildHeroHeader(context, isDark),

                // Content
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: BlocBuilder<PanchangHomeCubit, PanchangHomeState>(
                        builder: (context, state) {
                          if (state is PanchangHomeLoading ||
                              state is PanchangHomeInitial) {
                            return _buildLoadingState();
                          }

                          if (state is PanchangHomeError) {
                            return Padding(
                              padding: const EdgeInsets.all(20),
                              child: ErrorStateWidget(
                                title: 'Unable to load Panchang',
                                subtitle: state.message,
                                onRetry:
                                    () =>
                                        context
                                            .read<PanchangHomeCubit>()
                                            .loadToday(),
                              ),
                            );
                          }

                          if (state is PanchangHomeSuccess) {
                            return _buildSuccessState(context, state, isDark);
                          }

                          // Handle muhurats loading state (from Advanced Timings)
                          if (state is PanchangMuhuratsLoading ||
                              state is PanchangMuhuratsSuccess) {
                            return _buildLoadingState();
                          }

                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground(bool isDark, ThemeData theme) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors:
                isDark
                    ? [AppColors.deepSoilGreen, const Color(0xFF3D6B28)]
                    : [
                      theme.scaffoldBackgroundColor,
                      theme.scaffoldBackgroundColor,
                      theme.scaffoldBackgroundColor,
                    ],
          ),
        ),
        child: CustomPaint(painter: _BackgroundPatternPainter(isDark: isDark)),
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context, bool isDark) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppColors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: _buildHeaderBackground(isDark),
        title: null,
        collapseMode: CollapseMode.parallax,
      ),
      leading: _buildBackButton(isDark),
    );
  }

  Widget _buildHeaderBackground(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              isDark
                  ? [
                    (isDark ? AppColors.parchment : AppColors.deepSoilGreen)
                        .withAlpha(50),
                    (isDark ? AppColors.parchment : AppColors.deepSoilGreen)
                        .withAlpha(20),
                  ]
                  : [
                    (isDark ? AppColors.parchment : AppColors.deepSoilGreen)
                        .withAlpha(25),
                    (isDark ? AppColors.parchment : AppColors.deepSoilGreen)
                        .withAlpha(10),
                  ],
        ),
      ),
      child: BlocBuilder<PanchangHomeCubit, PanchangHomeState>(
        builder: (context, state) {
          final selectedDate =
              state is PanchangHomeSuccess
                  ? state.selectedDate
                  : DateTime.now();

          return Padding(
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
                _buildDateSelector(selectedDate, isDark),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateSelector(DateTime selectedDate, bool isDark) {
    return _AnimatedScaleButton(
      onTap: () => _showDatePicker(selectedDate),
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
                color:
                    isDark
                        ? AppColors.parchment.withValues(alpha: 0.9)
                        : AppColors.charcoal,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 20,
              color:
                  isDark
                      ? AppColors.pureWhite.withValues(alpha: 0.54)
                      : AppColors.charcoal54,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton(bool isDark) {
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

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildShimmerCard(height: 120),
          const SizedBox(height: 20),
          _buildShimmerCard(height: 300),
          const SizedBox(height: 20),
          _buildShimmerCard(height: 150),
        ],
      ),
    );
  }

  Widget _buildShimmerCard({required double height}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops:
                  [
                    _shimmerAnimation.value - 0.3,
                    _shimmerAnimation.value,
                    _shimmerAnimation.value + 0.3,
                  ].map((e) => e.clamp(0.0, 1.0)).toList(),
              colors:
                  isDark
                      ? [
                        AppColors.charcoal.withValues(alpha: 0.8),
                        AppColors.deepSoilGreen.withValues(alpha: 0.6),
                        AppColors.charcoal.withValues(alpha: 0.8),
                      ]
                      : [
                        AppColors.rawEarth12,
                        Theme.of(context).scaffoldBackgroundColor,
                        AppColors.rawEarth12,
                      ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuccessState(
    BuildContext context,
    PanchangHomeSuccess state,
    bool isDark,
  ) {
    final day = state.day;
    final timings = day.sunMoonTimings;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sun & Moon Timeline Card
          _buildSunMoonTimelineCard(timings, isDark),
          const SizedBox(height: 20),

          // Panchang Grid
          _buildPanchangGridCard(day, state.selectedDate, day.lunar, isDark),
          const SizedBox(height: 20),

          // All Inauspicious Timings Card
          if (day.inauspiciousTimings != null)
            _buildInauspiciousTimingsCard(day.inauspiciousTimings!, isDark),
          if (day.inauspiciousTimings != null) const SizedBox(height: 20),

          // Auspicious Muhurats
          if (day.auspiciousMuhurats != null)
            _buildMuhuratsCard(day.auspiciousMuhurats!, isDark),
          if (day.auspiciousMuhurats != null) const SizedBox(height: 20),

          // Guidance Highlight Card
          if (state.guidance != null) ...[
            _buildGuidanceHighlightCard(state.guidance!, isDark),
            const SizedBox(height: 20),
          ],

          // Moon Timings & Rashi Card
          _buildMoonRashiCard(timings, day.corePanchang, isDark),
          const SizedBox(height: 20),

          // View More Details Button
          _buildViewDetailsButton(state.selectedDate, isDark),
          const SizedBox(height: 20),

          // Highlights Section
          if (state.highlights != null &&
              state.highlights!.items.isNotEmpty) ...[
            _buildHighlightsSection(state.highlights!, isDark),
            const SizedBox(height: 20),
          ],

          // Quick Actions
          _buildQuickActions(context, isDark),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSunMoonTimelineCard(dynamic timings, bool isDark) {
    // Format times - handle both String and DateTime types
    String formatTime(dynamic time) {
      if (time is String) {
        // Parse string time and convert to 12-hour format with AM/PM
        try {
          final parts = time.split(':');
          if (parts.length >= 2) {
            final hour = int.parse(parts[0]);
            final minute = int.parse(parts[1]);
            final period = hour >= 12 ? 'PM' : 'AM';
            final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
            return '$hour12:${minute.toString().padLeft(2, '0')} $period';
          }
        } catch (e) {
          return time;
        }
        return time;
      }
      if (time is DateTime) {
        // Convert to Indian timezone and format
        final indianTime = time.toLocal();
        final hour = indianTime.hour;
        final minute = indianTime.minute;
        final period = hour >= 12 ? 'PM' : 'AM';
        final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
        return '$hour12:${minute.toString().padLeft(2, '0')} $period';
      }
      return '--:--';
    }

    return AnimatedBuilder(
      animation: _floatingAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatingAnimation.value),
          child: Transform.scale(
            scale: 1.0 + (_floatingAnimation.value.abs() / 300),
            child: AnimatedBuilder(
              animation: _shimmerAnimation,
              builder: (context, shaderChild) {
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(
                          0xFFFFD700,
                        ).withValues(alpha: 0.45 * _shimmerAnimation.value),
                        blurRadius: 18 + (12 * _shimmerAnimation.value),
                        spreadRadius: 2 + (3 * _shimmerAnimation.value),
                        offset: const Offset(-4, 0),
                      ),
                      BoxShadow(
                        color: AppColors.parchment.withValues(
                          alpha: 0.12 * _shimmerAnimation.value,
                        ),
                        blurRadius: 20 + (10 * _shimmerAnimation.value),
                        spreadRadius: 1 + (2 * _shimmerAnimation.value),
                        offset: const Offset(4, 0),
                      ),
                    ],
                  ),
                  child: shaderChild,
                );
              },
              child: child,
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                const Color(0xFFE8760A), // saffron sunrise
                AppColors.deepSoilGreen, // forest green transition
                const Color(0xFF0D1B2A), // deep night sunset side
              ],
              stops: [0.0, 0.48, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // ── Sun radial glow (left) ─────────────────────────
              Positioned(
                top: -30,
                left: -30,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.parchment.withValues(alpha: 0.45),
                        AppColors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // ── Moon soft halo (right) ─────────────────────────
              Positioned(
                top: -20,
                right: -20,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.parchment.withValues(alpha: 0.13),
                        AppColors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // ── Stars (right half) ─────────────────────────────
              Positioned(top: 10, right: 28, child: _buildStarDot(3.0, 0.90)),
              Positioned(top: 22, right: 62, child: _buildStarDot(1.8, 0.60)),
              Positioned(top: 6, right: 90, child: _buildStarDot(1.5, 0.50)),
              Positioned(top: 42, right: 48, child: _buildStarDot(2.2, 0.75)),
              Positioned(top: 18, right: 115, child: _buildStarDot(1.2, 0.40)),
              Positioned(
                bottom: 18,
                right: 32,
                child: _buildStarDot(2.5, 0.85),
              ),
              Positioned(
                bottom: 30,
                right: 70,
                child: _buildStarDot(1.5, 0.55),
              ),
              Positioned(
                bottom: 10,
                right: 95,
                child: _buildStarDot(1.0, 0.40),
              ),
              Positioned(top: 35, right: 20, child: _buildStarDot(1.2, 0.45)),
              // ── Content ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildTimeItem(
                          icon: Icons.wb_sunny_rounded,
                          label: 'Sunrise',
                          time: formatTime(timings.sunrise),
                        ),
                        Column(
                          children: [
                            Container(
                              height: 40,
                              width: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    AppColors.transparent,
                                    AppColors.parchment.withValues(alpha: 0.6),
                                    AppColors.transparent,
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            AutoSizeText(
                              '☀️🌙',
                              style: TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                        _buildTimeItem(
                          icon: Icons.nightlight_round,
                          label: 'Sunset',
                          time: formatTime(timings.sunset),
                        ),
                      ],
                    ),
                    if (timings.solarNoon != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.parchment.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.parchment.withValues(alpha: 0.25),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.wb_sunny,
                              color:
                                  isDark
                                      ? AppColors.pureWhite
                                      : AppColors.parchment,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            AutoSizeText(
                              'Solar Noon: ${formatTime(timings.solarNoon)}',
                              style: TextStyle(
                                color:
                                    isDark
                                        ? AppColors.pureWhite
                                        : AppColors.parchment,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
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

  Widget _buildTimeItem({
    required IconData icon,
    required String label,
    required String time,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, -5 * (0.5 - (value - 0.5).abs())),
          child: child,
        );
      },
      child: Column(
        children: [
          Icon(
            icon,
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? AppColors.pureWhite
                    : AppColors.parchment,
            size: 32,
          ),
          const SizedBox(height: 8),
          AutoSizeText(
            label,
            style: TextStyle(
              color:
                  (Theme.of(context).brightness == Brightness.dark)
                      ? AppColors.pureWhite.withValues(alpha: 0.7)
                      : AppColors.parchment.withValues(alpha: 0.7),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          AutoSizeText(
            time,
            style: TextStyle(
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? AppColors.pureWhite
                      : AppColors.parchment,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarDot(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.parchment.withValues(alpha: opacity),
        boxShadow: [
          BoxShadow(
            color: AppColors.parchment.withValues(alpha: opacity * 0.6),
            blurRadius: size * 1.5,
            spreadRadius: size * 0.3,
          ),
        ],
      ),
    );
  }

  Widget _buildPanchangGridCard(
    dynamic day,
    DateTime selectedDate,
    PanchangLunarInfo lunar,
    bool isDark,
  ) {
    // Check if selected date is today
    final now = DateTime.now();
    final isToday =
        selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;

    // Format date for display
    final dateText =
        isToday
            ? 'Today\'s Panchang'
            : 'Panchang - ${DateFormat('d MMM yyyy').format(selectedDate)}';

    // Helper to format end times
    String formatEndTime(DateTime? end) {
      if (end == null) return '';
      final local = end.toLocal();
      final hour =
          local.hour == 0
              ? 12
              : (local.hour > 12 ? local.hour - 12 : local.hour);
      final minute = local.minute.toString().padLeft(2, '0');
      final period = local.hour >= 12 ? 'PM' : 'AM';
      return 'Until $hour:$minute $period';
    }

    // Define unique colors for each panchang element
    final panchangItems = [
      _PanchangItemData(
        'Tithi',
        day.corePanchang.tithi,
        Icons.brightness_3,
        isDark ? AppColors.parchment : AppColors.harvestAmber,
        formatEndTime(day.corePanchang.tithiEnd),
      ),
      _PanchangItemData(
        'Nakshatra',
        day.corePanchang.nakshatra,
        Icons.stars_rounded,
        isDark ? AppColors.parchment : AppColors.deepSoilGreen,
        formatEndTime(day.corePanchang.nakshatraEnd),
      ),
      _PanchangItemData(
        'Yoga',
        day.corePanchang.yoga,
        Icons.self_improvement_rounded,
        isDark ? AppColors.parchment : AppColors.rawEarth,
        formatEndTime(day.corePanchang.yogaEnd),
      ),
      _PanchangItemData(
        'Karana',
        day.corePanchang.karana,
        Icons.change_history_rounded,
        isDark ? AppColors.parchment : AppColors.harvestAmber,
        formatEndTime(day.corePanchang.karanaEnd),
      ),
      _PanchangItemData(
        'Vara',
        day.corePanchang.vara,
        Icons.wb_sunny_rounded,
        isDark ? AppColors.parchment : AppColors.deepSoilGreen,
        'वार',
      ),
      _PanchangItemData(
        'Paksha',
        day.lunar.paksha,
        Icons.brightness_2_rounded,
        isDark ? AppColors.parchment : AppColors.rawEarth,
        'पक्ष',
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color:
                isDark
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
              colors:
                  isDark
                      ? [AppColors.darkSurface, AppColors.darkSurfaceElevated]
                      : [AppColors.deepSoilGreen, const Color(0xFF3A6B24)],
            ),
          ),
          child: Stack(
            children: [
              // Decorative background elements
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
                          alpha: isDark ? 0.2 : 0.1,
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
                        const Color(
                          0xFF6B4226,
                        ).withValues(alpha: isDark ? 0.15 : 0.08),
                        AppColors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Main content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        AnimatedBuilder(
                          animation: _shimmerAnimation,
                          builder: (context, child) {
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
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
                              child: AutoSizeText(
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
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isDark
                                          ? AppColors.parchment
                                          : AppColors.parchment,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  if (lunar.masa.isNotEmpty) ...[
                                    GestureDetector(
                                      onTap:
                                          () => _showMasaInfoDialog(
                                            context,
                                            lunar.masa,
                                            isDark,
                                          ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              const Color(
                                                0xFF2C4A1E,
                                              ).withValues(
                                                alpha: isDark ? 0.3 : 0.15,
                                              ),
                                              const Color(
                                                0xFF6B4226,
                                              ).withValues(
                                                alpha: isDark ? 0.2 : 0.1,
                                              ),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: const Color(
                                              0xFF2C4A1E,
                                            ).withValues(alpha: 0.3),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            AutoSizeText(
                                              '📅 ${lunar.masa}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color:
                                                    isDark
                                                        ? const Color(
                                                          0xFFF0D78C,
                                                        )
                                                        : const Color(
                                                          0xFFC9943A,
                                                        ),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(
                                              Icons.touch_app_rounded,
                                              size: 12,
                                              color:
                                                  isDark
                                                      ? const Color(
                                                        0xFFF0D78C,
                                                      ).withValues(alpha: 0.6)
                                                      : const Color(
                                                        0xFFC9943A,
                                                      ).withValues(alpha: 0.6),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    ],
                                  if (lunar.paksha.isNotEmpty)
                                    GestureDetector(
                                      onTap:
                                          () => _showPakshaInfoDialog(
                                            context,
                                            lunar.paksha,
                                            isDark,
                                          ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              lunar.paksha
                                                      .toLowerCase()
                                                      .contains('krishna')
                                                  ? const Color(
                                                    0xFF2C4A1E,
                                                  ).withValues(
                                                    alpha: isDark ? 0.3 : 0.15,
                                                  )
                                                  : const Color(
                                                    0xFFC9943A,
                                                  ).withValues(
                                                    alpha: isDark ? 0.3 : 0.15,
                                                  ),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color:
                                                lunar.paksha
                                                        .toLowerCase()
                                                        .contains('krishna')
                                                    ? const Color(
                                                      0xFF2C4A1E,
                                                    ).withValues(alpha: 0.3)
                                                    : const Color(
                                                      0xFFC9943A,
                                                    ).withValues(alpha: 0.3),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            AutoSizeText(
                                              lunar.paksha
                                                      .toLowerCase()
                                                      .contains('krishna')
                                                  ? '🌑 ${lunar.paksha}'
                                                  : '🌕 ${lunar.paksha}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color:
                                                    lunar.paksha
                                                            .toLowerCase()
                                                            .contains('krishna')
                                                        ? (isDark
                                                            ? const Color(
                                                              0xFFE8C362,
                                                            )
                                                            : const Color(
                                                              0xFF2C4A1E,
                                                            ))
                                                        : (isDark
                                                            ? const Color(
                                                              0xFFF0D78C,
                                                            )
                                                            : const Color(
                                                              0xFF6B4226,
                                                            )),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(
                                              Icons.touch_app_rounded,
                                              size: 12,
                                              color:
                                                  lunar.paksha
                                                          .toLowerCase()
                                                          .contains('krishna')
                                                      ? (isDark
                                                          ? const Color(
                                                            0xFFE8C362,
                                                          ).withValues(
                                                            alpha: 0.6,
                                                          )
                                                          : const Color(
                                                            0xFF2C4A1E,
                                                          ).withValues(
                                                            alpha: 0.6,
                                                          ))
                                                      : (isDark
                                                          ? const Color(
                                                            0xFFF0D78C,
                                                          ).withValues(
                                                            alpha: 0.6,
                                                          )
                                                          : const Color(
                                                            0xFF6B4226,
                                                          ).withValues(
                                                            alpha: 0.6,
                                                          )),
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
                          onTap: () => _showPanchangInfoDialog(context, isDark),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color:
                                  isDark
                                      ? AppColors.parchment.withValues(
                                        alpha: 0.1,
                                      )
                                      : const Color(
                                        0xFF2C4A1E,
                                      ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.parchment.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                            ),
                            child: Icon(
                              Icons.info_outline_rounded,
                              color:
                                  isDark
                                      ? AppColors.parchment
                                      : AppColors.parchment,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Panchang Grid - 2 columns
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
                        return _buildPanchangItem(item, isDark, index);
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

  Widget _buildPanchangItem(_PanchangItemData item, bool isDark, int index) {
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
            colors:
                isDark
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
                    color:
                        isDark ? item.color.withValues(alpha: 0.9) : item.color,
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
                        color:
                            isDark
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

  Widget _buildHighlightsSection(
    PanchangHighlightsResponse highlights,
    bool isDark,
  ) {
    final upcomingHighlights =
        highlights.items.where((item) => item.isUpcoming).take(5).toList();

    if (upcomingHighlights.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.parchment.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.celebration_rounded,
                    size: 16,
                    color: isDark ? AppColors.pureWhite : AppColors.deepSoilGreen,
                  ),
                ),
                const SizedBox(width: 10),
                AutoSizeText(
                  'Upcoming Festivals',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.pureWhite : AppColors.charcoal,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PanchangFestivalsScreen(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.deepSoilGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: AutoSizeText(
                  'View All',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.pureWhite : AppColors.deepSoilGreen,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: upcomingHighlights.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              return _buildHighlightItem(upcomingHighlights[index], isDark);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHighlightItem(HighlightItem highlight, bool isDark) {
    final dateParts = highlight.formattedDate.split(' ');
    final day = dateParts.length > 1 ? dateParts[1] : '';
    final month = dateParts.isNotEmpty ? dateParts[0] : '';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PanchangFestivalsScreen()),
        );
      },
      child: Container(
        width: 130,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors:
                isDark
                    ? [AppColors.darkSurface, AppColors.darkSurfaceElevated]
                    : [AppColors.deepSoilGreen, const Color(0xFF3A6B24)],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(
              0xFFFFB020,
            ).withValues(alpha: isDark ? 0.25 : 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(
                0xFFFFB020,
              ).withValues(alpha: isDark ? 0.08 : 0.12),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors:
                          isDark
                              ? [AppColors.darkSurface, AppColors.darkSurfaceElevated]
                              : [
                                AppColors.deepSoilGreen,
                                const Color(0xFF3A6B24),
                              ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: AutoSizeText(
                    day,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: isDark ? AppColors.pureWhite : AppColors.parchment,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                AutoSizeText(
                  month,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.pureWhite.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: AutoSizeText(
                highlight.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.pureWhite : AppColors.charcoal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 22,
              decoration: BoxDecoration(
                color: isDark ? AppColors.pureWhite : AppColors.deepSoilGreen,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            AutoSizeText(
              'Quick Navigation',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.pureWhite : AppColors.charcoal,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.calendar_view_month_rounded,
                label: 'Month\nCalendar',
                color: isDark ? AppColors.pureWhite : AppColors.deepSoilGreen,
                isDark: isDark,
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PanchangMonthScreen(),
                      ),
                    ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                icon: Icons.celebration_rounded,
                label: 'All\nFestivals',
                color: isDark ? AppColors.harvestAmber : AppColors.harvestAmber,
                isDark: isDark,
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PanchangFestivalsScreen(),
                      ),
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.self_improvement_rounded,
                label: 'Vrat\nCalendar',
                color: isDark ? AppColors.pureWhite : AppColors.rawEarth,
                isDark: isDark,
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PanchangVratCalendarScreen(),
                      ),
                    ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                icon: Icons.auto_awesome,
                label: 'Today\'s\nGuidance',
                color: isDark ? AppColors.warmGold : AppColors.warmGold,
                isDark: isDark,
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PanchangGuidanceScreen(),
                      ),
                    ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return _AnimatedScaleButton(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        height: 120,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: isDark ? 0.3 : 0.2),
              color.withValues(alpha: isDark ? 0.2 : 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: isDark ? 0.35 : 0.18),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.35),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: color.withValues(alpha: 0.5),
                  size: 14,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Align(
                alignment: Alignment.bottomLeft,
                child: AutoSizeText(
                  label,
                  maxLines: 2,
                  minFontSize: 9,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.pureWhite : AppColors.charcoal,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDatePicker(DateTime currentDate) async {
    HapticFeedback.mediumImpact();
    final picked = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.deepSoilGreen,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != currentDate) {
      _cubit.loadDate(picked);
    }
  }

  Widget _buildInauspiciousTimingsCard(
    PanchangInauspiciousTimings timings,
    bool isDark,
  ) {
    String formatTime(DateTime? time) {
      if (time == null) return '--:--';
      final localTime = time.toLocal();
      final hour = localTime.hour;
      final minute = localTime.minute;
      final period = hour >= 12 ? 'PM' : 'AM';
      final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      return '$hour12:${minute.toString().padLeft(2, '0')} $period';
    }

    final hasRahuKaal = timings.rahuKaal != null;
    final hasGulika = timings.gulika != null;
    final hasYamaganda = timings.yamaganda != null;

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
                colors:
                    isDark
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
                        color:
                            isDark ? AppColors.pureWhite : AppColors.parchment,
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
                          color:
                              isDark ? AppColors.pureWhite : AppColors.parchment,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showInauspiciousInfoDialog(context, isDark),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.rawEarth.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.info_outline_rounded,
                          color:
                              isDark ? AppColors.rawEarth : AppColors.rawEarth,
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
                    startTime: formatTime(timings.rahuKaal!.start),
                    endTime: formatTime(timings.rahuKaal!.end),
                    isDark: isDark,
                  ),
                  if (hasGulika || hasYamaganda) const SizedBox(height: 12),
                ],
                if (hasGulika) ...[
                  _buildInauspiciousTimeItem(
                    title: 'Gulika Kaal',
                    icon: Icons.block_rounded,
                    startTime: formatTime(timings.gulika!.start),
                    endTime: formatTime(timings.gulika!.end),
                    isDark: isDark,
                  ),
                  if (hasYamaganda) const SizedBox(height: 12),
                ],
                if (hasYamaganda)
                  _buildInauspiciousTimeItem(
                    title: 'Yamaganda Kaal',
                    icon: Icons.report_problem_rounded,
                    startTime: formatTime(timings.yamaganda!.start),
                    endTime: formatTime(timings.yamaganda!.end),
                    isDark: isDark,
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
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: isDark ? AppColors.rawEarth : AppColors.rawEarth,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: AutoSizeText(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.pureWhite,
            ),
          ),
        ),
        AutoSizeText(
          '$startTime - $endTime',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.rawEarth : AppColors.rawEarth,
          ),
        ),
      ],
    );
  }

  Widget _buildRahuKaalCard(PanchangTimeWindow rahuKaal, bool isDark) {
    String formatTime(DateTime? time) {
      if (time == null) return '--:--';
      final localTime = time.toLocal();
      final hour = localTime.hour;
      final minute = localTime.minute;
      final period = hour >= 12 ? 'PM' : 'AM';
      final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      return '$hour12:${minute.toString().padLeft(2, '0')} $period';
    }

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
                colors:
                    isDark
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
                          color:
                              isDark ? AppColors.pureWhite : AppColors.rawEarth,
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
                        '${formatTime(rahuKaal.start)} - ${formatTime(rahuKaal.end)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color:
                              isDark ? AppColors.rawEarth : AppColors.rawEarth,
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

  Widget _buildMuhuratsCard(PanchangAuspiciousMuhurats muhurats, bool isDark) {
    String formatTime(DateTime? time) {
      if (time == null) return '--:--';
      final localTime = time.toLocal();
      final hour = localTime.hour;
      final minute = localTime.minute;
      final period = hour >= 12 ? 'PM' : 'AM';
      final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      return '$hour12:${minute.toString().padLeft(2, '0')} $period';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : AppColors.pureWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              isDark
                  ? AppColors.harvestAmber40
                  : AppColors.harvestAmber.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.parchment.withValues(alpha: 0.12),
            blurRadius: 10,
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors:
                        isDark
                            ? [AppColors.darkSurface, AppColors.darkSurfaceElevated]
                            : [
                              AppColors.deepSoilGreen,
                              const Color(0xFF3A6B24),
                            ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: isDark ? AppColors.pureWhite : AppColors.parchment,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AutoSizeText(
                  'Auspicious Times',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.pureWhite : AppColors.charcoal,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _showAuspiciousInfoDialog(context, isDark),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        isDark
                            ? AppColors.charcoal.withValues(alpha: 0.5)
                            : AppColors.deepSoilGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.info_outline_rounded,
                    color:
                        isDark
                            ? AppColors.harvestAmber
                            : AppColors.deepSoilGreen,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          AutoSizeText(
            'Tap ℹ️ to learn more about auspicious muhurats',
            style: TextStyle(
              fontSize: 12,
              color: (isDark ? AppColors.pureWhite : AppColors.charcoal)
                  .withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 12),
          if (muhurats.abhijit != null)
            _buildMuhuratItem(
              'Abhijit Muhurat',
              'Best time for important work',
              formatTime(muhurats.abhijit!.start),
              formatTime(muhurats.abhijit!.end),
              Icons.star,
              AppColors.harvestAmber,
              isDark,
            ),
          if (muhurats.abhijit != null && muhurats.brahma != null)
            const SizedBox(height: 12),
          if (muhurats.brahma != null)
            _buildMuhuratItem(
              'Brahma Muhurat',
              'Ideal for meditation & study',
              formatTime(muhurats.brahma!.start),
              formatTime(muhurats.brahma!.end),
              Icons.self_improvement,
              AppColors.parchment,
              isDark,
            ),
        ],
      ),
    );
  }

  Widget _buildMuhuratItem(
    String title,
    String subtitle,
    String startTime,
    String endTime,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AutoSizeText(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.pureWhite : AppColors.charcoal,
                  ),
                ),
                AutoSizeText(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: (isDark ? AppColors.pureWhite : AppColors.charcoal)
                        .withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          AutoSizeText(
            '$startTime - $endTime',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoonRashiCard(
    PanchangSunMoonTimings timings,
    PanchangCorePanchang corePanchang,
    bool isDark,
  ) {
    String formatTime(DateTime? time) {
      if (time == null) return '--:--';
      final localTime = time.toLocal();
      final hour = localTime.hour;
      final minute = localTime.minute;
      final period = hour >= 12 ? 'PM' : 'AM';
      final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      return '$hour12:${minute.toString().padLeft(2, '0')} $period';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              isDark
                  ? [AppColors.darkSurface, AppColors.darkSurfaceElevated]
                  : [AppColors.deepSoilGreen, const Color(0xFF3A6B24)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: (isDark ? AppColors.parchment : AppColors.deepSoilGreen).withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.parchment.withValues(alpha: 0.5),
                      blurRadius: 14,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.nightlight_round,
                  color: AppColors.pureWhite,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AutoSizeText(
                  'Moon & Rashi Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.pureWhite : AppColors.charcoal,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _showMoonRashiInfoDialog(context, isDark),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.parchment.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.info_outline_rounded,
                    color: isDark ? AppColors.pureWhite : AppColors.charcoal,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          AutoSizeText(
            'Tap ℹ️ to learn about Moon phases & Rashi',
            style: TextStyle(
              fontSize: 12,
              color: (isDark ? AppColors.pureWhite : AppColors.charcoal)
                  .withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMoonInfoItem(
                  'Moonrise',
                  formatTime(timings.moonrise),
                  Icons.arrow_upward,
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMoonInfoItem(
                  'Moonset',
                  formatTime(timings.moonset),
                  Icons.arrow_downward,
                  isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMoonInfoItem(
                  'Sun Rashi',
                  corePanchang.sunRashi,
                  Icons.wb_sunny,
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMoonInfoItem(
                  'Moon Rashi',
                  corePanchang.moonRashi,
                  Icons.nightlight,
                  isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMoonInfoItem(
    String label,
    String value,
    IconData icon,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.pureWhite.withValues(
          alpha: 0.1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: AppColors.pureWhite,
            size: 20,
          ),
          SizedBox(height: 4),
          AutoSizeText(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.pureWhite.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 2),
          AutoSizeText(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.pureWhite,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuidanceHighlightCard(
    GuidanceTodayResponse guidance,
    bool isDark,
  ) {
    // Find a recommendation that is currently active or upcoming
    final activeRec = guidance.recommendations.firstWhere(
      (r) => r.hasActiveRecommendedWindow,
      orElse:
          () => guidance.recommendations.firstWhere(
            (r) => r.upcomingRecommendedWindows.isNotEmpty,
            orElse: () => guidance.recommendations.first,
          ),
    );

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PanchangGuidanceScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors:
                isDark
                    ? [AppColors.darkSurface, AppColors.darkSurfaceElevated]
                    : [AppColors.deepSoilGreen, const Color(0xFF3A6B24)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: (isDark ? AppColors.parchment : AppColors.deepSoilGreen).withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.parchment.withValues(alpha: 0.15),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.parchment.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.parchment.withValues(alpha: 0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    color: AppColors.pureWhite,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AutoSizeText(
                        'Today\'s Guidance',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.pureWhite,
                        ),
                      ),
                      AutoSizeText(
                        'Personalized recommendations',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.pureWhite.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.pureWhite,
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.pureWhite.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AutoSizeText(
                          activeRec.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.pureWhite,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AutoSizeText(
                          activeRec.verdict,
                          style: TextStyle(
                            fontSize: 13,
                            color:
                                activeRec.verdict.toLowerCase().contains(
                                      'avoid',
                                    )
                                    ? AppColors.rawEarth
                                    : activeRec.verdict.toLowerCase().contains(
                                      'recommended',
                                    )
                                    ? AppColors.deepSoilGreen
                                    : (isDark
                                        ? AppColors.pureWhite.withValues(
                                          alpha: 0.54,
                                        )
                                        : AppColors.charcoal54),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (activeRec.notesList.isNotEmpty)
                    Icon(
                      Icons.info_outline,
                      color: isDark ? AppColors.pureWhite : AppColors.parchment,
                      size: 20,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewDetailsButton(DateTime selectedDate, bool isDark) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => BlocProvider.value(
                  value: _cubit,
                  child: PanchangAdvancedTimingsScreen(
                    selectedDate: selectedDate,
                  ),
                ),
          ),
        );
        // Reload home data when returning from Advanced Timings
        if (mounted) {
          _cubit.loadDate(selectedDate);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors:
                isDark
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
                  SizedBox(height: 4),
                  AutoSizeText(
                    'Hora, Choghadiya & Transitions',
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          (isDark)
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

  void _showInauspiciousInfoDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: AppColors.transparent,
            insetPadding: const EdgeInsets.all(20),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors:
                      isDark
                          ? [AppColors.darkSurface, AppColors.darkSurfaceElevated]
                          : [AppColors.deepSoilGreen, const Color(0xFF3A6B24)],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.rawEarth.withValues(alpha: 0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
                border: Border.all(
                  color: AppColors.rawEarth.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.rawEarth, AppColors.rawEarth],
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
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
                              Icons.warning_rounded,
                              color:
                                  isDark
                                      ? AppColors.pureWhite
                                      : AppColors.parchment,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AutoSizeText(
                                  'Inauspicious Timings',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isDark
                                            ? AppColors.pureWhite
                                            : AppColors.parchment,
                                  ),
                                ),
                                SizedBox(height: 4),
                                AutoSizeText(
                                  'Understanding unfavorable periods',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color:
                                        (isDark)
                                            ? AppColors.pureWhite.withValues(
                                              alpha: 0.7,
                                            )
                                            : AppColors.parchment.withValues(
                                              alpha: 0.7,
                                            ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(
                              Icons.close,
                              color:
                                  (isDark)
                                      ? AppColors.pureWhite.withValues(
                                        alpha: 0.7,
                                      )
                                      : AppColors.parchment.withValues(
                                        alpha: 0.7,
                                      ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _buildInfoSection(
                            icon: Icons.dangerous_rounded,
                            title: 'Rahu Kaal',
                            color: AppColors.rawEarth,
                            description:
                                'Rahu Kaal is considered the most inauspicious time of the day. According to Vedic astrology, Rahu is a shadow planet that brings obstacles, delays, and negative outcomes. Any new venture started during this period may face unexpected hurdles.',
                            tips: [
                              'Avoid starting new businesses',
                              'Not recommended for travel',
                              'Skip signing important contracts',
                              'Avoid major purchases',
                            ],
                            isDark: isDark,
                          ),
                          const SizedBox(height: 16),
                          _buildInfoSection(
                            icon: Icons.block_rounded,
                            title: 'Gulika Kaal',
                            color: AppColors.harvestAmber,
                            description:
                                'Gulika (also known as Mandi) is the son of Saturn and represents a highly malefic period. Activities begun during Gulika Kaal may lead to illness, loss, or failure.',
                            tips: [
                              'Avoid medical treatments',
                              'Not suitable for finance',
                              'Skip educational pursuits',
                              'Avoid initiating relationships',
                            ],
                            isDark: isDark,
                          ),
                          const SizedBox(height: 16),
                          _buildInfoSection(
                            icon: Icons.report_problem_rounded,
                            title: 'Yamaganda Kaal',
                            color: AppColors.rawEarth,
                            description:
                                'Yamaganda means "danger of Yama" (the god of death). Activities started during this time may lead to accidents or health issues.',
                            tips: [
                              'Strictly avoid travel',
                              'No risky activities',
                              'Avoid important ceremonies',
                              'Not suitable for construction',
                            ],
                            isDark: isDark,
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.harvestAmber.withValues(
                                alpha: isDark ? 0.15 : 0.1,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.harvestAmber.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.lightbulb_outline,
                                  color: AppColors.harvestAmber,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: AutoSizeText(
                                    'Tip: Routine activities and ongoing work can continue during these periods. Only avoid starting new important tasks.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color:
                                          isDark
                                              ? AppColors.harvestAmber
                                              : AppColors.harvestAmber,
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
            ),
          ),
    );
  }

  void _showAuspiciousInfoDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: AppColors.transparent,
            insetPadding: const EdgeInsets.all(20),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors:
                      isDark
                          ? [AppColors.darkSurface, AppColors.darkSurfaceElevated]
                          : [AppColors.deepSoilGreen, const Color(0xFF3A6B24)],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.parchment.withValues(alpha: 0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
                border: Border.all(
                  color: AppColors.parchment.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors:
                              isDark
                                  ? [
                                    AppColors.charcoal,
                                    const Color(0xFF222222),
                                  ]
                                  : [
                                    AppColors.deepSoilGreen,
                                    const Color(0xFF3A6B24),
                                  ],
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
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
                              Icons.auto_awesome,
                              color:
                                  isDark
                                      ? AppColors.pureWhite
                                      : AppColors.parchment,
                              size: 28,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AutoSizeText(
                                  'Auspicious Timings',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isDark
                                            ? AppColors.pureWhite
                                            : AppColors.parchment,
                                  ),
                                ),
                                SizedBox(height: 4),
                                AutoSizeText(
                                  'Sacred windows of opportunity',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color:
                                        (isDark)
                                            ? AppColors.pureWhite.withValues(
                                              alpha: 0.7,
                                            )
                                            : AppColors.parchment.withValues(
                                              alpha: 0.7,
                                            ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(
                              Icons.close,
                              color:
                                  (isDark)
                                      ? AppColors.pureWhite.withValues(
                                        alpha: 0.7,
                                      )
                                      : AppColors.parchment.withValues(
                                        alpha: 0.7,
                                      ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _buildInfoSection(
                            icon: Icons.wb_twilight_rounded,
                            title: 'Brahma Muhurat',
                            color: AppColors.harvestAmber,
                            description:
                                'Brahma Muhurat literally means "the creator\'s time" and occurs approximately 1 hour 36 minutes before sunrise. This is the most spiritually powerful time for meditation and prayer.',
                            tips: [
                              'Ideal for meditation and yoga',
                              'Best for studying scriptures',
                              'Perfect for spiritual practices',
                              'Enhanced clarity for decisions',
                            ],
                            isDark: isDark,
                          ),
                          const SizedBox(height: 16),
                          _buildInfoSection(
                            icon: Icons.star_rounded,
                            title: 'Abhijit Muhurat',
                            color: AppColors.harvestAmber,
                            description:
                                'Abhijit Muhurat is the "victorious moment" occurring around midday. It\'s so auspicious that it nullifies all doshas (defects). Lord Krishna was born during this muhurat.',
                            tips: [
                              'Perfect for new ventures',
                              'Excellent for important meetings',
                              'Ideal for signing contracts',
                              'Best for beginning journeys',
                            ],
                            isDark: isDark,
                          ),
                          const SizedBox(height: 16),
                          _buildInfoSection(
                            icon: Icons.sunny,
                            title: 'Sunrise (Suryodaya)',
                            color: AppColors.harvestAmber,
                            description:
                                'The moment of sunrise is highly auspicious. The first rays of the sun carry healing energy and divine blessings. Morning prayers at this time are especially powerful.',
                            tips: [
                              'Offer water to the Sun',
                              'Practice Surya Namaskar',
                              'Begin your day with gratitude',
                              'Set intentions for the day',
                            ],
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  void _showMasaInfoDialog(
    BuildContext context,
    String currentMasa,
    bool isDark,
  ) {
    final masaInfo = {
      'Chaitra': {
        'month': 'March-April',
        'deity': 'Vishnu',
        'significance':
            'Start of Hindu New Year (Vikram Samvat). Chaitra Navratri begins.',
      },
      'Vaishakha': {
        'month': 'April-May',
        'deity': 'Madhusudana',
        'significance':
            'Buddha Purnima, Akshaya Tritiya. Best for charity and new beginnings.',
      },
      'Jyeshtha': {
        'month': 'May-June',
        'deity': 'Trivikrama',
        'significance': 'Ganga Dussehra, Nirjala Ekadashi. Summer heat peaks.',
      },
      'Ashadha': {
        'month': 'June-July',
        'deity': 'Vamana',
        'significance': 'Guru Purnima, start of Chaturmas. Monsoon begins.',
      },
      'Shravana': {
        'month': 'July-August',
        'deity': 'Sridhara',
        'significance':
            'Shravan Somvar, Raksha Bandhan, Janmashtami. Very auspicious month.',
      },
      'Bhadrapada': {
        'month': 'August-September',
        'deity': 'Hrishikesha',
        'significance':
            'Ganesh Chaturthi, Anant Chaturdashi, Pitru Paksha begins.',
      },
      'Ashwin': {
        'month': 'September-October',
        'deity': 'Padmanabha',
        'significance':
            'Sharad Navratri, Durga Puja, Dussehra. Festival season begins.',
      },
      'Kartik': {
        'month': 'October-November',
        'deity': 'Damodara',
        'significance':
            'Diwali, Govardhan Puja, Tulsi Vivah. Most sacred month for Vaishnavites.',
      },
      'Margashirsha': {
        'month': 'November-December',
        'deity': 'Keshava',
        'significance':
            'Gita Jayanti, Mokshada Ekadashi. Lord Krishna\'s favorite month.',
      },
      'Pausha': {
        'month': 'December-January',
        'deity': 'Narayana',
        'significance': 'Makar Sankranti, Lohri. Winter solstice period.',
      },
      'Magha': {
        'month': 'January-February',
        'deity': 'Madhava',
        'significance': 'Vasant Panchami, Maha Shivaratri. Spring begins.',
      },
      'Phalguna': {
        'month': 'February-March',
        'deity': 'Govinda',
        'significance': 'Holi, Holika Dahan. End of Hindu calendar year.',
      },
    };

    final info =
        masaInfo[currentMasa] ??
        {
          'month': 'Hindu Lunar Month',
          'deity': 'Vishnu',
          'significance':
              'Each month is associated with specific festivals and rituals.',
        };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder:
          (context) => Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.pureWhite : AppColors.charcoal,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(25),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.rawEarth54.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors:
                          isDark
                              ? [AppColors.darkSurface, AppColors.darkSurfaceElevated]
                              : [
                                AppColors.deepSoilGreen,
                                const Color(0xFF3A6B24),
                              ],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(25),
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
                        child: AutoSizeText(
                          '📅',
                          style: TextStyle(fontSize: 28),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AutoSizeText(
                              '$currentMasa Masa',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color:
                                    isDark
                                        ? AppColors.pureWhite
                                        : AppColors.parchment,
                              ),
                            ),
                            AutoSizeText(
                              'Hindu Lunar Month (मास)',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.parchment.withValues(
                                  alpha: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.close,
                          color:
                              isDark
                                  ? AppColors.pureWhite
                                  : AppColors.parchment,
                        ),
                      ),
                    ],
                  ),
                ),
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow(
                          Icons.calendar_month,
                          'Gregorian Period',
                          info['month']!,
                          isDark,
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          Icons.temple_hindu,
                          'Presiding Deity',
                          info['deity']!,
                          isDark,
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          Icons.auto_awesome,
                          'Significance',
                          info['significance']!,
                          isDark,
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF2C4A1E,
                            ).withValues(alpha: isDark ? 0.2 : 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.parchment.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AutoSizeText(
                                '💡 What is Masa?',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isDark
                                          ? AppColors.pureWhite
                                          : AppColors.charcoal,
                                ),
                              ),
                              const SizedBox(height: 8),
                              AutoSizeText(
                                'Masa (मास) is the Hindu lunar month. There are 12 months in a lunar year, each named after the Nakshatra in which the full moon occurs. The Hindu calendar follows either Amanta (month ends on New Moon) or Purnimanta (month ends on Full Moon) system.',
                                style: TextStyle(
                                  fontSize: 14,

                                  color:
                                      isDark
                                          ? AppColors.pureWhite.withValues(
                                            alpha: 0.54,
                                          )
                                          : AppColors.charcoal54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _showPakshaInfoDialog(
    BuildContext context,
    String currentPaksha,
    bool isDark,
  ) {
    final isKrishna = currentPaksha.toLowerCase().contains('krishna');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder:
          (context) => Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.pureWhite : AppColors.charcoal,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(25),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.rawEarth54.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors:
                          isKrishna
                              ? isDark
                                  ? [
                                    AppColors.charcoal,
                                    const Color(0xFF222222),
                                  ]
                                  : [
                                    AppColors.deepSoilGreen,
                                    const Color(0xFF3A6B24),
                                  ]
                              : isDark
                              ? [AppColors.darkSurface, AppColors.darkSurfaceElevated]
                              : [
                                AppColors.deepSoilGreen,
                                const Color(0xFF3A6B24),
                              ],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(25),
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
                        child: AutoSizeText(
                          isKrishna ? '🌑' : '🌕',
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AutoSizeText(
                              '$currentPaksha Paksha',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color:
                                    isKrishna
                                        ? AppColors.parchment
                                        : AppColors.charcoal,
                              ),
                            ),
                            AutoSizeText(
                              isKrishna
                                  ? 'Dark Fortnight (कृष्ण पक्ष)'
                                  : 'Bright Fortnight (शुक्ल पक्ष)',
                              style: TextStyle(
                                fontSize: 13,
                                color:
                                    isKrishna
                                        ? AppColors.parchment.withValues(
                                          alpha: 0.8,
                                        )
                                        : AppColors.charcoal54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.close,
                          color:
                              isKrishna
                                  ? AppColors.parchment
                                  : AppColors.charcoal54,
                        ),
                      ),
                    ],
                  ),
                ),
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Moon Phase Visual
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors:
                                  isKrishna
                                      ? [
                                        const Color(
                                          0xFF0D1A10,
                                        ).withValues(alpha: 0.5),
                                        const Color(
                                          0xFF143318,
                                        ).withValues(alpha: 0.3),
                                      ]
                                      : [
                                        AppColors.parchment,
                                        const Color(
                                          0xFFFDE68A,
                                        ).withValues(alpha: 0.5),
                                      ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children:
                                isKrishna
                                    ? [
                                      _buildMoonPhase(
                                        '🌕',
                                        'Purnima',
                                        'Day 1',
                                        isDark,
                                      ),
                                      Icon(
                                        Icons.arrow_forward,
                                        color: AppColors.rawEarth54,
                                      ),
                                      _buildMoonPhase(
                                        '🌖',
                                        'Waning',
                                        'Day 5',
                                        isDark,
                                      ),
                                      Icon(
                                        Icons.arrow_forward,
                                        color: AppColors.rawEarth54,
                                      ),
                                      _buildMoonPhase(
                                        '🌗',
                                        'Half',
                                        'Day 8',
                                        isDark,
                                      ),
                                      Icon(
                                        Icons.arrow_forward,
                                        color: AppColors.rawEarth54,
                                      ),
                                      _buildMoonPhase(
                                        '🌑',
                                        'Amavasya',
                                        'Day 15',
                                        isDark,
                                      ),
                                    ]
                                    : [
                                      _buildMoonPhase(
                                        '🌑',
                                        'Amavasya',
                                        'Day 1',
                                        isDark,
                                      ),
                                      Icon(
                                        Icons.arrow_forward,
                                        color: AppColors.rawEarth54,
                                      ),
                                      _buildMoonPhase(
                                        '🌒',
                                        'Waxing',
                                        'Day 5',
                                        isDark,
                                      ),
                                      Icon(
                                        Icons.arrow_forward,
                                        color: AppColors.rawEarth54,
                                      ),
                                      _buildMoonPhase(
                                        '🌓',
                                        'Half',
                                        'Day 8',
                                        isDark,
                                      ),
                                      Icon(
                                        Icons.arrow_forward,
                                        color: AppColors.rawEarth54,
                                      ),
                                      _buildMoonPhase(
                                        '🌕',
                                        'Purnima',
                                        'Day 15',
                                        isDark,
                                      ),
                                    ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Details
                        _buildInfoRow(
                          Icons.brightness_2,
                          'Moon Phase',
                          isKrishna
                              ? 'Waning Moon (decreasing light)'
                              : 'Waxing Moon (increasing light)',
                          isDark,
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          Icons.calendar_today,
                          'Duration',
                          '15 Tithis (lunar days)',
                          isDark,
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          Icons.star,
                          'Ends On',
                          isKrishna
                              ? 'Amavasya (New Moon)'
                              : 'Purnima (Full Moon)',
                          isDark,
                        ),
                        const SizedBox(height: 24),
                        // Best Activities
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: (isKrishna
                                    ? AppColors.parchment
                                    : AppColors.parchment)
                                .withValues(alpha: isDark ? 0.2 : 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: (isKrishna
                                      ? AppColors.parchment
                                      : AppColors.parchment)
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AutoSizeText(
                                isKrishna
                                    ? '🌙 Krishna Paksha Activities'
                                    : '☀️ Shukla Paksha Activities',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isDark
                                          ? AppColors.pureWhite
                                          : AppColors.charcoal,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ...(isKrishna
                                      ? [
                                        '✅ Pitru Tarpan (ancestral offerings)',
                                        '✅ Tantra Sadhana & occult practices',
                                        '✅ Completion of ongoing tasks',
                                        '✅ Introspection & meditation',
                                        '✅ Shraddha rituals',
                                        '❌ Avoid starting new ventures',
                                        '❌ Avoid marriages & griha pravesh',
                                      ]
                                      : [
                                        '✅ Starting new ventures',
                                        '✅ Marriages & auspicious ceremonies',
                                        '✅ Griha Pravesh (house warming)',
                                        '✅ Religious functions & yagnas',
                                        '✅ Buying property or vehicles',
                                        '✅ Starting education or business',
                                      ])
                                  .map(
                                    (text) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: AutoSizeText(
                                        text,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color:
                                              isDark
                                                  ? AppColors.pureWhite
                                                      .withValues(alpha: 0.54)
                                                  : AppColors.charcoal54,
                                        ),
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
              ],
            ),
          ),
    );
  }

  Widget _buildMoonPhase(String emoji, String label, String day, bool isDark) {
    return Column(
      children: [
        AutoSizeText(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        AutoSizeText(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color:
                isDark
                    ? AppColors.pureWhite.withValues(alpha: 0.54)
                    : AppColors.charcoal54,
          ),
        ),
        AutoSizeText(
          day,
          style: TextStyle(
            fontSize: 9,
            color:
                isDark
                    ? AppColors.pureWhite.withValues(alpha: 0.54)
                    : AppColors.charcoal38,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color:
                isDark
                    ? AppColors.parchment.withValues(alpha: 0.1)
                    : AppColors.rawEarth54.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color:
                isDark
                    ? AppColors.pureWhite.withValues(alpha: 0.54)
                    : AppColors.charcoal54,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AutoSizeText(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color:
                      isDark
                          ? AppColors.pureWhite.withValues(alpha: 0.54)
                          : AppColors.charcoal45,
                ),
              ),
              const SizedBox(height: 2),
              AutoSizeText(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.pureWhite : AppColors.charcoal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showPanchangInfoDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: AppColors.transparent,
            insetPadding: const EdgeInsets.all(20),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors:
                      isDark
                          ? [AppColors.darkSurface, AppColors.darkSurfaceElevated]
                          : [AppColors.deepSoilGreen, const Color(0xFF3A6B24)],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.parchment.withValues(alpha: 0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
                border: Border.all(
                  color: AppColors.parchment.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors:
                              isDark
                                  ? [
                                    AppColors.charcoal,
                                    const Color(0xFF222222),
                                  ]
                                  : [
                                    AppColors.deepSoilGreen,
                                    const Color(0xFF3A6B24),
                                  ],
                        ),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24),
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
                              Icons.auto_awesome_rounded,
                              color:
                                  isDark
                                      ? AppColors.pureWhite
                                      : AppColors.parchment,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AutoSizeText(
                                  'Understanding Panchang',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isDark
                                            ? AppColors.pureWhite
                                            : AppColors.parchment,
                                  ),
                                ),
                                SizedBox(height: 4),
                                AutoSizeText(
                                  'The five limbs of Vedic time',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color:
                                        (isDark)
                                            ? AppColors.pureWhite.withValues(
                                              alpha: 0.7,
                                            )
                                            : AppColors.parchment.withValues(
                                              alpha: 0.7,
                                            ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(
                              Icons.close,
                              color:
                                  (isDark)
                                      ? AppColors.pureWhite.withValues(
                                        alpha: 0.7,
                                      )
                                      : AppColors.parchment.withValues(
                                        alpha: 0.7,
                                      ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF2C4A1E,
                              ).withValues(alpha: isDark ? 0.15 : 0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.parchment.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                            ),
                            child: AutoSizeText(
                              'Panchang (पञ्चाङ्ग) literally means "five limbs" in Sanskrit. It is the ancient Vedic calendar system that tracks five essential elements of time that determine auspiciousness.',
                              style: TextStyle(
                                fontSize: 14,

                                color:
                                    isDark
                                        ? AppColors.pureWhite.withValues(
                                          alpha: 0.54,
                                        )
                                        : AppColors.charcoal54,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildPanchangElementInfo(
                            icon: Icons.brightness_3,
                            title: 'Tithi (तिथि)',
                            subtitle: 'Lunar Day',
                            color:
                                isDark
                                    ? AppColors.pureWhite
                                    : AppColors.parchment,
                            description:
                                'Tithi represents the lunar day based on the angle between the Sun and Moon. There are 30 Tithis in a lunar month.',
                            examples: 'Pratipada, Dvitiya, Amavasya, Purnima',
                            isDark: isDark,
                          ),
                          SizedBox(height: 12),
                          _buildPanchangElementInfo(
                            icon: Icons.stars_rounded,
                            title: 'Nakshatra (नक्षत्र)',
                            subtitle: 'Lunar Mansion',
                            color:
                                isDark
                                    ? AppColors.pureWhite
                                    : AppColors.parchment,
                            description:
                                'Nakshatra is the lunar constellation where the Moon resides. There are 27 Nakshatras, each spanning 13°20\'.',
                            examples: 'Ashwini, Rohini, Pushya, Revati',
                            isDark: isDark,
                          ),
                          SizedBox(height: 12),
                          _buildPanchangElementInfo(
                            icon: Icons.self_improvement_rounded,
                            title: 'Yoga (योग)',
                            subtitle: 'Auspicious Combination',
                            color:
                                isDark
                                    ? AppColors.pureWhite
                                    : AppColors.parchment,
                            description:
                                'Yoga is calculated from the combined longitude of Sun and Moon. There are 27 Yogas, each lasting about one day.',
                            examples: 'Siddhi, Amrita, Shobhana',
                            isDark: isDark,
                          ),
                          SizedBox(height: 12),
                          _buildPanchangElementInfo(
                            icon: Icons.change_history_rounded,
                            title: 'Karana (करण)',
                            subtitle: 'Half Tithi',
                            color:
                                isDark
                                    ? AppColors.pureWhite
                                    : AppColors.parchment,
                            description:
                                'Karana is half of a Tithi. There are 11 Karanas. Vishti Karana (Bhadra) is considered inauspicious.',
                            examples: 'Bava, Balava, Vishti (inauspicious)',
                            isDark: isDark,
                          ),
                          SizedBox(height: 12),
                          _buildPanchangElementInfo(
                            icon: Icons.wb_sunny_rounded,
                            title: 'Vara (वार)',
                            subtitle: 'Weekday',
                            color:
                                isDark
                                    ? AppColors.pureWhite
                                    : AppColors.parchment,
                            description:
                                'Vara is the day of the week, ruled by different planets. Each day has specific favorable activities.',
                            examples: 'Ravivara (Sun), Somavara (Mon)',
                            isDark: isDark,
                          ),
                          SizedBox(height: 12),
                          _buildPanchangElementInfo(
                            icon: Icons.brightness_2_rounded,
                            title: 'Paksha (पक्ष)',
                            subtitle: 'Lunar Fortnight',
                            color:
                                isDark
                                    ? AppColors.pureWhite
                                    : AppColors.parchment,
                            description:
                                'Paksha divides the lunar month into two halves. Shukla (bright) for new beginnings, Krishna (dark) for completion.',
                            examples: 'Shukla Paksha, Krishna Paksha',
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  void _showMoonRashiInfoDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: AppColors.transparent,
            insetPadding: const EdgeInsets.all(20),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors:
                      isDark
                          ? [AppColors.darkSurface, AppColors.darkSurfaceElevated]
                          : [AppColors.deepSoilGreen, const Color(0xFF3A6B24)],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.parchment.withValues(alpha: 0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
                border: Border.all(
                  color: AppColors.parchment.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors:
                              isDark
                                  ? [
                                    AppColors.charcoal,
                                    const Color(0xFF222222),
                                  ]
                                  : [
                                    AppColors.deepSoilGreen,
                                    const Color(0xFF3A6B24),
                                  ],
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
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
                              Icons.nightlight_round,
                              color:
                                  isDark
                                      ? AppColors.pureWhite
                                      : AppColors.parchment,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AutoSizeText(
                                  'Moon & Rashi',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isDark
                                            ? AppColors.pureWhite
                                            : AppColors.parchment,
                                  ),
                                ),
                                SizedBox(height: 4),
                                AutoSizeText(
                                  'Lunar influence on daily life',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color:
                                        (isDark)
                                            ? AppColors.pureWhite.withValues(
                                              alpha: 0.7,
                                            )
                                            : AppColors.parchment.withValues(
                                              alpha: 0.7,
                                            ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(
                              Icons.close,
                              color:
                                  (isDark)
                                      ? AppColors.pureWhite.withValues(
                                        alpha: 0.7,
                                      )
                                      : AppColors.parchment.withValues(
                                        alpha: 0.7,
                                      ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _buildMoonRashiSection(
                            icon: Icons.arrow_upward_rounded,
                            title: 'Moonrise (चन्द्रोदय)',
                            color: AppColors.harvestAmber,
                            description:
                                'Moonrise marks when the Moon becomes visible above the eastern horizon. The energy after moonrise is favorable for creativity and nurturing.',
                            significance: [
                              'Ideal for Moon worship',
                              'Favorable for creative endeavors',
                              'Important for Karva Chauth',
                            ],
                            isDark: isDark,
                          ),
                          const SizedBox(height: 16),
                          _buildMoonRashiSection(
                            icon: Icons.arrow_downward_rounded,
                            title: 'Moonset (चन्द्रास्त)',
                            color: AppColors.harvestAmber,
                            description:
                                'Moonset is when the Moon descends below the western horizon. Important for calculating lunar day transitions.',
                            significance: [
                              'Marks end of lunar visibility',
                              'Relevant for fasting observances',
                              'Affects meditation practices',
                            ],
                            isDark: isDark,
                          ),
                          const SizedBox(height: 16),
                          _buildMoonRashiSection(
                            icon: Icons.wb_sunny_rounded,
                            title: 'Sun Rashi (सूर्य राशि)',
                            color: AppColors.harvestAmber,
                            description:
                                'Sun Rashi indicates which zodiac sign the Sun is transiting. Determines solar months and Sankranti festivals.',
                            significance: [
                              'Determines solar months',
                              'Influences personality',
                              'Important for timing festivals',
                            ],
                            isDark: isDark,
                          ),
                          const SizedBox(height: 16),
                          _buildMoonRashiSection(
                            icon: Icons.nightlight_rounded,
                            title: 'Moon Rashi (चन्द्र राशि)',
                            color: AppColors.deepSoilGreen,
                            description:
                                'Moon Rashi shows which zodiac sign the Moon occupies. More important than Sun sign in Vedic astrology for emotions and mental well-being.',
                            significance: [
                              'Governs emotions',
                              'Determines Janma Rashi',
                              'Crucial for Muhurat selection',
                            ],
                            isDark: isDark,
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(
                                    0xFF3F5E46,
                                  ).withValues(alpha: isDark ? 0.2 : 0.1),
                                  const Color(
                                    0xFF1A3D24,
                                  ).withValues(alpha: isDark ? 0.2 : 0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.parchment.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.lightbulb_outline,
                                      color:
                                          isDark
                                              ? AppColors.parchment
                                              : AppColors.parchment,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: AutoSizeText(
                                        'The 12 Rashis (Zodiac Signs)',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              isDark
                                                  ? AppColors.parchment
                                                  : AppColors.parchment,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children:
                                      [
                                            'Mesha (Aries)',
                                            'Vrishabha (Taurus)',
                                            'Mithuna (Gemini)',
                                            'Karka (Cancer)',
                                            'Simha (Leo)',
                                            'Kanya (Virgo)',
                                            'Tula (Libra)',
                                            'Vrishchika (Scorpio)',
                                            'Dhanu (Sagittarius)',
                                            'Makara (Capricorn)',
                                            'Kumbha (Aquarius)',
                                            'Meena (Pisces)',
                                          ]
                                          .map(
                                            (rashi) => Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(
                                                  0xFF3F5E46,
                                                ).withValues(
                                                  alpha: isDark ? 0.2 : 0.15,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: AutoSizeText(
                                                rashi,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                  color:
                                                      isDark
                                                          ? AppColors
                                                              .parchment70
                                                          : const Color(
                                                            0xFF1A3D24,
                                                          ),
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
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
            ),
          ),
    );
  }

  Widget _buildInfoSection({
    required IconData icon,
    required String title,
    required Color color,
    required String description,
    required List<String> tips,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.1 : 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              AutoSizeText(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.pureWhite : AppColors.charcoal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AutoSizeText(
            description,
            style: TextStyle(
              fontSize: 13,

              color:
                  isDark
                      ? AppColors.pureWhite.withValues(alpha: 0.54)
                      : AppColors.charcoal54,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                tips
                    .map(
                      (tip) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: isDark ? 0.15 : 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, color: color, size: 14),
                            const SizedBox(width: 6),
                            Flexible(
                              child: AutoSizeText(
                                tip,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      isDark
                                          ? AppColors.pureWhite.withValues(
                                            alpha: 0.54,
                                          )
                                          : AppColors.charcoal54,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPanchangElementInfo({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required String description,
    required String examples,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.1 : 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AutoSizeText(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color:
                            isDark ? AppColors.pureWhite : AppColors.charcoal,
                      ),
                    ),
                    AutoSizeText(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AutoSizeText(
            description,
            style: TextStyle(
              fontSize: 13,

              color:
                  isDark
                      ? AppColors.pureWhite.withValues(alpha: 0.54)
                      : AppColors.charcoal54,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.15 : 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.format_list_bulleted, color: color, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: AutoSizeText(
                    examples,
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color:
                          isDark
                              ? AppColors.pureWhite.withValues(alpha: 0.60)
                              : AppColors.charcoal45,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoonRashiSection({
    required IconData icon,
    required String title,
    required Color color,
    required String description,
    required List<String> significance,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.1 : 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AutoSizeText(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.pureWhite : AppColors.charcoal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AutoSizeText(
            description,
            style: TextStyle(
              fontSize: 13,

              color:
                  isDark
                      ? AppColors.pureWhite.withValues(alpha: 0.54)
                      : AppColors.charcoal54,
            ),
          ),
          const SizedBox(height: 12),
          ...significance.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle, color: color, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AutoSizeText(
                      item,
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            isDark
                                ? AppColors.pureWhite.withValues(alpha: 0.60)
                                : AppColors.charcoal45,
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
}

// Custom painter for background pattern
/// Data class for panchang item display
class _PanchangItemData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String secondaryLabel;

  const _PanchangItemData(
    this.label,
    this.value,
    this.icon,
    this.color,
    this.secondaryLabel,
  );
}

class _BackgroundPatternPainter extends CustomPainter {
  final bool isDark;

  _BackgroundPatternPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = (isDark ? AppColors.pureWhite : AppColors.charcoal)
              .withValues(alpha: 0.02)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;

    for (int i = 0; i < 10; i++) {
      canvas.drawCircle(
        Offset(size.width * (i / 10), size.height * 0.2),
        50 + (i * 10),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Animated scale button widget for subtle tap effects
class _AnimatedScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _AnimatedScaleButton({required this.child, required this.onTap});

  @override
  State<_AnimatedScaleButton> createState() => _AnimatedScaleButtonState();
}

class _AnimatedScaleButtonState extends State<_AnimatedScaleButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
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
      child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
    );
  }
}
