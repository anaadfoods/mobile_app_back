import 'package:grocery_app/common_widgets/global_import.dart';

import '../../../cubits/panchang/panchang_home_cubit.dart';
import '../../../cubits/panchang/panchang_home_state.dart';
import '../../../repositories/panchang_repository.dart';
import 'widgets/panchang_background.dart';
import 'widgets/panchang_loading_state.dart';
import 'widgets/sun_moon_timeline_card.dart';
import 'widgets/panchang_grid_card.dart';
import 'widgets/panchang_highlights_section.dart';
import 'widgets/panchang_quick_actions.dart';
import 'widgets/inauspicious_timings_card.dart';
import 'widgets/auspicious_muhurats_card.dart';
import 'widgets/moon_rashi_card.dart';
import 'widgets/guidance_highlight_card.dart';
import 'widgets/view_details_button.dart';
import 'panchang_advanced_timings_screen.dart';

/// Modern redesigned Panchang Calendar Home Screen
/// Features:
/// - Hero header with date selector
/// - Today's panchang with visual timeline
/// - Upcoming festivals highlights
/// - Quick action cards
/// - Smooth animations and transitions
import 'package:grocery_app/service_locator.dart';

class PanchangHomeScreen extends StatefulWidget {
  const PanchangHomeScreen({super.key});

  @override
  State<PanchangHomeScreen> createState() => _PanchangHomeScreenState();
}

class _PanchangHomeScreenState extends State<PanchangHomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  late final PanchangHomeCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = PanchangHomeCubit(repository: getIt<PanchangRepository>());

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

    _entranceController.forward();
    _cubit.loadToday();
  }

  @override
  void dispose() {
    _entranceController.dispose();
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
            PanchangBackground(isDark: isDark),

            // Main content
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Hero header with date selector
                BlocBuilder<PanchangHomeCubit, PanchangHomeState>(
                  buildWhen: (previous, current) =>
                      current is PanchangHomeSuccess,
                  builder: (context, state) {
                    final selectedDate = state is PanchangHomeSuccess
                        ? state.selectedDate
                        : DateTime.now();
                    return PanchangHeroHeader(
                      selectedDate: selectedDate,
                      isDark: isDark,
                      onDateTap: () => _showDatePicker(selectedDate),
                    );
                  },
                ),

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
                            return const PanchangLoadingState();
                          }

                          if (state is PanchangHomeError) {
                            return Padding(
                              padding: const EdgeInsets.all(20),
                              child: ErrorStateWidget(
                                title: 'Unable to load Panchang',
                                subtitle: state.message,
                                onRetry: () => context
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
                            return const PanchangLoadingState();
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
          SunMoonTimelineCard(timings: timings, isDark: isDark),
          const SizedBox(height: 20),

          // Panchang Grid
          PanchangGridCard(
            day: day,
            selectedDate: state.selectedDate,
            lunar: day.lunar,
            isDark: isDark,
          ),
          const SizedBox(height: 20),

          // All Inauspicious Timings Card
          if (day.inauspiciousTimings != null)
            InauspiciousTimingsCard(
              timings: day.inauspiciousTimings!,
              isDark: isDark,
            ),
          if (day.inauspiciousTimings != null) const SizedBox(height: 20),

          // Auspicious Muhurats
          if (day.auspiciousMuhurats != null)
            AuspiciousMuhuratsCard(
              muhurats: day.auspiciousMuhurats!,
              isDark: isDark,
            ),
          if (day.auspiciousMuhurats != null) const SizedBox(height: 20),

          // Guidance Highlight Card
          if (state.guidance != null) ...[
            GuidanceHighlightCard(guidance: state.guidance!, isDark: isDark),
            const SizedBox(height: 20),
          ],

          // Moon Timings & Rashi Card
          MoonRashiCard(
            timings: timings,
            corePanchang: day.corePanchang,
            isDark: isDark,
          ),
          const SizedBox(height: 20),

          // View More Details Button
          ViewDetailsButton(
            isDark: isDark,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: _cubit,
                    child: PanchangAdvancedTimingsScreen(
                      selectedDate: state.selectedDate,
                    ),
                  ),
                ),
              );
              // Reload home data when returning from Advanced Timings
              if (mounted) {
                _cubit.loadDate(state.selectedDate);
              }
            },
          ),
          const SizedBox(height: 20),

          // Highlights Section
          if (state.highlights != null &&
              state.highlights!.items.isNotEmpty) ...[
            PanchangHighlightsSection(
              highlights: state.highlights!,
              isDark: isDark,
            ),
            const SizedBox(height: 20),
          ],

          // Quick Actions
          PanchangQuickActions(isDark: isDark),
          const SizedBox(height: 20),
        ],
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
}
