import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../common_widgets/error_state_widget.dart';
import '../../../cubits/panchang/panchang_home_cubit.dart';
import '../../../cubits/panchang/panchang_home_state.dart';
import '../../../repositories/panchang_repository.dart';
import '../../../models/panchang/panchang_highlights_models.dart';
import '../../../models/panchang/panchang_day_models.dart';
import 'panchang_month_screen.dart';
import 'panchang_festivals_screen.dart';
import 'panchang_advanced_timings_screen.dart';
import 'panchang_vrat_calendar_screen.dart';

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
      CurvedAnimation(
        parent: _floatingController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Shimmer animation for loading
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);
    
    _shimmerAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _shimmerController,
        curve: Curves.easeInOut,
      ),
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
        backgroundColor: isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF5F7FA),
        body: Stack(
          children: [
            // Animated background
            _buildAnimatedBackground(isDark),
            
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
                                onRetry: () => context.read<PanchangHomeCubit>().loadToday(),
                              ),
                            );
                          }

                          if (state is PanchangHomeSuccess) {
                            return _buildSuccessState(context, state, isDark);
                          }

                          // Handle muhurats loading state (from Advanced Timings)
                          if (state is PanchangMuhuratsLoading || state is PanchangMuhuratsSuccess) {
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

  Widget _buildAnimatedBackground(bool isDark) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF1A0F2E),
                    const Color(0xFF0F0A1A),
                    const Color(0xFF0A0A0F),
                  ]
                : [
                    const Color(0xFFE8EAFF),
                    const Color(0xFFF5F7FA),
                    const Color(0xFFFFFFFF),
                  ],
          ),
        ),
        child: CustomPaint(
          painter: _BackgroundPatternPainter(isDark: isDark),
        ),
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context, bool isDark) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: Colors.transparent,
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
          colors: isDark
              ? [
                  const Color(0xFF6B46C1).withOpacity(0.3),
                  const Color(0xFF9333EA).withOpacity(0.2),
                ]
              : [
                  const Color(0xFF9333EA).withOpacity(0.1),
                  const Color(0xFF6B46C1).withOpacity(0.05),
                ],
        ),
      ),
      child: BlocBuilder<PanchangHomeCubit, PanchangHomeState>(
        builder: (context, state) {
          final selectedDate = state is PanchangHomeSuccess
              ? state.selectedDate
              : DateTime.now();
          
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Panchang Calendar',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
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
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.purple : Colors.deepPurple).withOpacity(0.1),
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
              color: isDark ? Colors.white : Colors.black87,
            ),
            const SizedBox(width: 10),
            Text(
              DateFormat('EEEE, d MMMM yyyy').format(selectedDate),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: isDark ? Colors.white70 : Colors.black54,
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
              Navigator.pop(context);
            },
            child: Container(
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: isDark ? Colors.white : Colors.black87,
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
              stops: [
                _shimmerAnimation.value - 0.3,
                _shimmerAnimation.value,
                _shimmerAnimation.value + 0.3,
              ].map((e) => e.clamp(0.0, 1.0)).toList(),
              colors: [
                Colors.grey.shade300,
                Colors.grey.shade100,
                Colors.grey.shade300,
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
          if (day.inauspiciousTimings != null)
            const SizedBox(height: 20),
          
          // Auspicious Muhurats
          if (day.auspiciousMuhurats != null)
            _buildMuhuratsCard(day.auspiciousMuhurats!, isDark),
          if (day.auspiciousMuhurats != null)
            const SizedBox(height: 20),
          
          // Moon Timings & Rashi Card
          _buildMoonRashiCard(timings, day.corePanchang, isDark),
          const SizedBox(height: 20),
          
          // View More Details Button
          _buildViewDetailsButton(state.selectedDate, isDark),
          const SizedBox(height: 20),
          
          // Highlights Section
          if (state.highlights != null && state.highlights!.items.isNotEmpty) ...[
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
                        color: (isDark ? const Color(0xFFFF6B6B) : const Color(0xFFFFAA00))
                            .withOpacity(0.4 * _shimmerAnimation.value),
                        blurRadius: 15 + (10 * _shimmerAnimation.value),
                        spreadRadius: 2 + (3 * _shimmerAnimation.value),
                        offset: const Offset(0, 0),
                      ),
                      BoxShadow(
                        color: (isDark ? const Color(0xFFFFB347) : const Color(0xFFFF6B6B))
                            .withOpacity(0.3 * _shimmerAnimation.value),
                        blurRadius: 25 + (15 * _shimmerAnimation.value),
                        spreadRadius: 4 + (4 * _shimmerAnimation.value),
                        offset: const Offset(0, 0),
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
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFFFF6B6B), const Color(0xFFFFB347)]
              : [const Color(0xFFFFAA00), const Color(0xFFFF6B6B)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
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
              Container(
                height: 50,
                width: 1,
                color: Colors.white.withOpacity(0.3),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.wb_sunny,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Solar Noon: ${formatTime(timings.solarNoon)}',
                    style: const TextStyle(
                      color: Colors.white,
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
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          time,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        ],
      ),
    );
  }

  Widget _buildPanchangGridCard(dynamic day, DateTime selectedDate, PanchangLunarInfo lunar, bool isDark) {
    // Check if selected date is today
    final now = DateTime.now();
    final isToday = selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;
    
    // Format date for display
    final dateText = isToday
        ? 'Today\'s Panchang'
        : 'Panchang - ${DateFormat('d MMM yyyy').format(selectedDate)}';
    
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF9333EA).withOpacity(0.5 * _shimmerAnimation.value),
                blurRadius: 20 + (15 * _shimmerAnimation.value),
                spreadRadius: 0,
                offset: const Offset(0, 0),
              ),
              BoxShadow(
                color: const Color(0xFF6B46C1).withOpacity(0.4 * _shimmerAnimation.value),
                blurRadius: 35 + (20 * _shimmerAnimation.value),
                spreadRadius: 0,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1A1A2E).withOpacity(0.6)
                  : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFF9333EA).withOpacity(0.5 + (0.3 * _shimmerAnimation.value)),
                width: 2,
              ),
            ),
            child: child,
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9333EA), Color(0xFF6B46C1)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF9333EA).withOpacity(0.5),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateText,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                        shadows: [
                          Shadow(
                            color: const Color(0xFF9333EA).withOpacity(0.3),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                    if (lunar.masa.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF9333EA).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFF9333EA).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          lunar.masa,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFFB794F6) : const Color(0xFF7C3AED),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.8,
            children: [
              _buildPanchangItem('Tithi', day.corePanchang.tithi, Icons.brightness_3, isDark, 0),
              _buildPanchangItem('Nakshatra', day.corePanchang.nakshatra, Icons.stars_rounded, isDark, 1),
              _buildPanchangItem('Yoga', day.corePanchang.yoga, Icons.self_improvement_rounded, isDark, 2),
              _buildPanchangItem('Karana', day.corePanchang.karana, Icons.circle_outlined, isDark, 3),
              _buildPanchangItem('Vara', day.corePanchang.vara, Icons.calendar_today, isDark, 4),
              _buildPanchangItem('Paksha', day.lunar.paksha, Icons.brightness_2, isDark, 5),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPanchangItem(String label, String value, IconData icon, bool isDark, int index) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF6B46C1).withOpacity(0.35),
                  const Color(0xFF9333EA).withOpacity(0.25),
                ]
              : [
                  const Color(0xFFE8D5FF).withOpacity(0.8),
                  const Color(0xFFF3E8FF).withOpacity(0.6),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF9333EA).withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9333EA).withOpacity(0.15),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
          Icon(
            icon,
            color: const Color(0xFF9333EA),
            size: 20,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value.isEmpty ? '—' : value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightsSection(PanchangHighlightsResponse highlights, bool isDark) {
    final upcomingHighlights = highlights.items
        .where((item) => item.isUpcoming)
        .take(5)
        .toList();

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
                    color: const Color(0xFFFFB020).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.celebration_rounded,
                    size: 16,
                    color: Color(0xFFFFB020),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Upcoming Festivals',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black87,
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF9333EA).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF9333EA),
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
            colors: isDark
                ? [const Color(0xFF2D2D3A), const Color(0xFF1A1A24)]
                : [Colors.white, const Color(0xFFFFFBF0)],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFFFB020).withValues(alpha: isDark ? 0.25 : 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFB020).withValues(alpha: isDark ? 0.08 : 0.12),
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFB020), Color(0xFFFF8C00)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    day,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  month,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                highlight.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                  height: 1.2,
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
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.calendar_view_month_rounded,
                label: 'Month\nCalendar',
                color: const Color(0xFF6B46C1),
                isDark: isDark,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PanchangMonthScreen()),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                icon: Icons.celebration_rounded,
                label: 'All\nFestivals',
                color: const Color(0xFF9333EA),
                isDark: isDark,
                onTap: () => Navigator.push(
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
                color: const Color(0xFF6B46C1),
                isDark: isDark,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PanchangVratCalendarScreen(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(child: SizedBox.shrink()),
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
              color.withOpacity(isDark ? 0.3 : 0.2),
              color.withOpacity(isDark ? 0.2 : 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withOpacity(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
                height: 1.2,
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
            colorScheme: ColorScheme.fromSwatch(
              primarySwatch: Colors.deepPurple,
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

  Widget _buildInauspiciousTimingsCard(PanchangInauspiciousTimings timings, bool isDark) {
    String formatTime(DateTime? time) {
      if (time == null) return '--:--';
      final hour = time.hour;
      final minute = time.minute;
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
                color: Colors.red.withOpacity(0.3 * _shimmerAnimation.value),
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
                    ? [const Color(0xFFFF4444).withOpacity(0.3), const Color(0xFFFF6B6B).withOpacity(0.2)]
                    : [const Color(0xFFFFEBEE), const Color(0xFFFFCDD2)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.red.withOpacity(0.5),
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
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.5),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.warning_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Inauspicious Timings ⚠️',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.red.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Avoid starting new work during these times',
                  style: TextStyle(
                    fontSize: 12,
                    color: (isDark ? Colors.white : Colors.black).withOpacity(0.6),
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
          color: isDark ? Colors.red.shade300 : Colors.red.shade700,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.red.shade900,
            ),
          ),
        ),
        Text(
          '$startTime - $endTime',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.red.shade200 : Colors.red.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildRahuKaalCard(PanchangTimeWindow rahuKaal, bool isDark) {
    String formatTime(DateTime? time) {
      if (time == null) return '--:--';
      final hour = time.hour;
      final minute = time.minute;
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
                color: Colors.red.withOpacity(0.3 * _shimmerAnimation.value),
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
                    ? [const Color(0xFFFF4444).withOpacity(0.3), const Color(0xFFFF6B6B).withOpacity(0.2)]
                    : [const Color(0xFFFFEBEE), const Color(0xFFFFCDD2)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.red.withOpacity(0.5),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.warning_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rahu Kaal ⚠️',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.red.shade900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Avoid starting new work',
                        style: TextStyle(
                          fontSize: 12,
                          color: (isDark ? Colors.white : Colors.black).withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${formatTime(rahuKaal.start)} - ${formatTime(rahuKaal.end)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.red.shade200 : Colors.red.shade700,
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
      final hour = time.hour;
      final minute = time.minute;
      final period = hour >= 12 ? 'PM' : 'AM';
      final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      return '$hour12:${minute.toString().padLeft(2, '0')} $period';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1A1A2E).withOpacity(0.6)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.green.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
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
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Auspicious Times',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (muhurats.abhijit != null)
            _buildMuhuratItem(
              'Abhijit Muhurat',
              'Best time for important work',
              formatTime(muhurats.abhijit!.start),
              formatTime(muhurats.abhijit!.end),
              Icons.star,
              Colors.amber,
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
              Colors.purple,
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
        color: color.withOpacity(isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: (isDark ? Colors.white : Colors.black).withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Text(
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
      final hour = time.hour;
      final minute = time.minute;
      final period = hour >= 12 ? 'PM' : 'AM';
      final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      return '$hour12:${minute.toString().padLeft(2, '0')} $period';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E3A8A).withOpacity(0.4), const Color(0xFF3B82F6).withOpacity(0.3)]
              : [const Color(0xFFE3F2FD), const Color(0xFFBBDEFB)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.nightlight_round, color: Colors.blue, size: 28),
              const SizedBox(width: 12),
              Text(
                'Moon & Rashi Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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

  Widget _buildMoonInfoItem(String label, String value, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.blue.shade900).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.blue.shade300, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewDetailsButton(DateTime selectedDate, bool isDark) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: _cubit,
              child: PanchangAdvancedTimingsScreen(selectedDate: selectedDate),
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
            colors: isDark
                ? [const Color(0xFF6366F1), const Color(0xFF8B5CF6)]
                : [const Color(0xFF8B5CF6), const Color(0xFF6366F1)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withOpacity(0.4),
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
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.access_time_filled,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'View Advanced Timings',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Hora, Choghadiya & Transitions',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painter for background pattern
class _BackgroundPatternPainter extends CustomPainter {
  final bool isDark;

  _BackgroundPatternPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.02)
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

  const _AnimatedScaleButton({
    required this.child,
    required this.onTap,
  });

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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
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
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}
