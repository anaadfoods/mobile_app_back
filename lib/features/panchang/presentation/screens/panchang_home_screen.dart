import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:grocery_app/features/panchang/presentation/cubit/panchang_home_cubit.dart';
import 'package:grocery_app/features/panchang/presentation/cubit/panchang_home_state.dart';
import 'package:grocery_app/repositories/panchang_repository.dart';
import 'package:grocery_app/services/content_config_service.dart';

import '../widgets/panchang_background.dart';
import '../widgets/panchang_header_widget.dart';
import '../widgets/panchang_loading_state.dart';
import '../widgets/sun_moon_timeline_card.dart';
import '../widgets/panchang_grid_card.dart';
import '../widgets/panchang_highlights_section.dart';
import '../widgets/panchang_quick_actions.dart';
import '../widgets/inauspicious_timings_card.dart';
import '../widgets/auspicious_muhurats_card.dart';
import '../widgets/moon_rashi_card.dart';
import '../widgets/view_details_button.dart';
import '../widgets/daily_muhurta_timeline_card.dart';
import '../widgets/planetary_positions_card.dart';
import '../widgets/panchang_insight_card.dart';
import '../widgets/kundli_summary_card.dart';
import '../widgets/ayurvedic_guidance_card.dart';
import '../widgets/personalized_recommendations_card.dart';
import '../widgets/user_profile_summary_card.dart';
import '../widgets/prakriti_assessment_card.dart';
import '../widgets/ai_memory_card.dart';
import '../widgets/panchang_info_dialogs.dart';
import 'panchang_advanced_timings_screen.dart';

/// Complete, Production-Ready Panchang Calendar Home Screen
class PanchangHomeScreen extends StatefulWidget {
  const PanchangHomeScreen({super.key});

  @override
  State<PanchangHomeScreen> createState() => _PanchangHomeScreenState();
}

class _PanchangHomeScreenState extends State<PanchangHomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<Offset> _slideAnimation;
  late final PanchangHomeCubit _cubit;
  late final TabController _tabController;

  String _locationLabel = 'New Delhi, India (28.61° N, 77.21° E)';
  Map<String, dynamic>? _healthProfile;
  List<Map<String, dynamic>> _memoryFacts = [];
  List<Map<String, dynamic>> _medicalReports = [];
  List<Map<String, dynamic>> _foodThaliLogs = [];
  bool _loadingPersonalized = false;
  List<Map<String, dynamic>> _presetLocations = [];

  @override
  void initState() {
    super.initState();
    _cubit = PanchangHomeCubit(repository: getIt<PanchangRepository>());
    _tabController = TabController(length: 2, vsync: this);

    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.1, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _entranceController.forward();
    });
    _cubit.loadToday();
    _loadPersonalizedData();
    _loadPresetLocations();
    PanchangInfoDialogs.prefetchEncyclopediaData();
  }


  Future<void> _loadPresetLocations() async {
    try {
      final locations = await ContentConfigService().fetchPresetLocations();
      if (locations.isNotEmpty && mounted) {
        setState(() => _presetLocations = locations);
      }
    } catch (_) {
      // Keep empty, will use fallback
    }
  }

  List<dynamic> _extractList(dynamic resData) {
    if (resData is List) return resData;
    if (resData is Map<String, dynamic>) {
      if (resData['data'] is List) return resData['data'] as List<dynamic>;
      if (resData['results'] is List) return resData['results'] as List<dynamic>;
      if (resData['items'] is List) return resData['items'] as List<dynamic>;
    }
    return [];
  }

  Map<String, dynamic> _extractMap(dynamic resData) {
    if (resData is Map<String, dynamic>) {
      if (resData.containsKey('data') && resData['data'] is Map<String, dynamic>) {
        return resData['data'] as Map<String, dynamic>;
      }
      return resData;
    }
    return {};
  }

  Future<void> _loadPersonalizedData() async {
    if (!mounted) return;
    setState(() => _loadingPersonalized = true);
    try {
      // 1. Fetch Profile
      try {
        final profileResp = await ApiClient.instance.get(ApiConfig.healthProfileEndpoint);
        if (profileResp.data != null) {
          _healthProfile = _extractMap(profileResp.data);
        }
      } catch (_) {}

      // 2. Fetch Summary & Memory Insights
      try {
        final summaryResp = await ApiClient.instance.get(ApiConfig.healthProfileSummaryEndpoint);
        final summaryMap = _extractMap(summaryResp.data);
        final findings = (summaryMap['key_findings'] as List<dynamic>?)
            ?.map((e) => {'fact': e.toString(), 'category': 'Health Insight'})
            .toList() ?? [];

        final List<Map<String, dynamic>> compiledFacts = [...findings];

        // Also add conditions & allergies from base profile if present
        if (_healthProfile != null) {
          final conditions = _healthProfile!['medical_conditions'] as List<dynamic>?;
          if (conditions != null) {
            for (final c in conditions) {
              compiledFacts.add({'fact': 'Diagnosed condition: $c', 'category': 'Medical'});
            }
          }
          final allergies = _healthProfile!['allergies'] as List<dynamic>?;
          if (allergies != null) {
            for (final a in allergies) {
              compiledFacts.add({'fact': 'Allergy: $a', 'category': 'Allergy'});
            }
          }
        }
        _memoryFacts = compiledFacts;
      } catch (_) {}

      // 3. Fetch Medical Reports
      try {
        final reportsResp = await ApiClient.instance.get(ApiConfig.medicalReportsEndpoint);
        final list = _extractList(reportsResp.data);
        _medicalReports = list.map((e) => e is Map<String, dynamic> ? e : <String, dynamic>{}).toList();
      } catch (_) {}

      // 4. Fetch Food Thali Logs
      try {
        final thaliResp = await ApiClient.instance.get(ApiConfig.foodThaliEndpoint);
        final list = _extractList(thaliResp.data);
        _foodThaliLogs = list.map((e) => e is Map<String, dynamic> ? e : <String, dynamic>{}).toList();
      } catch (_) {}
    } catch (_) {
      // Catch-all
    } finally {
      if (mounted) {
        setState(() => _loadingPersonalized = false);
      }
    }
  }

  void _showLocationPicker(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final controller = TextEditingController(text: _locationLabel.split('(').first.trim());

    final quickCities = _presetLocations.isNotEmpty
        ? _presetLocations.map((loc) {
            final lat = (loc['latitude'] as num?)?.toDouble() ?? 0.0;
            final lon = (loc['longitude'] as num?)?.toDouble() ?? 0.0;
            return {
              'name': loc['name'] ?? '',
              'coords': '${lat.toStringAsFixed(2)}\u00b0 ${lat >= 0 ? "N" : "S"}, ${lon.toStringAsFixed(2)}\u00b0 ${lon >= 0 ? "E" : "W"}',
            };
          }).toList()
        : [
            {'name': 'New Delhi', 'coords': '28.61\u00b0 N, 77.21\u00b0 E'},
            {'name': 'Varanasi', 'coords': '25.31\u00b0 N, 82.97\u00b0 E'},
            {'name': 'Ujjain', 'coords': '23.17\u00b0 N, 75.78\u00b0 E'},
            {'name': 'Haridwar', 'coords': '29.94\u00b0 N, 78.16\u00b0 E'},
            {'name': 'Mumbai', 'coords': '19.07\u00b0 N, 72.87\u00b0 E'},
            {'name': 'Bengaluru', 'coords': '12.97\u00b0 N, 77.59\u00b0 E'},
            {'name': 'Pune', 'coords': '18.52\u00b0 N, 73.85\u00b0 E'},
            {'name': 'Jaipur', 'coords': '26.91\u00b0 N, 75.78\u00b0 E'},
            {'name': 'Kolkata', 'coords': '22.57\u00b0 N, 88.36\u00b0 E'},
            {'name': 'Chennai', 'coords': '13.08\u00b0 N, 80.27\u00b0 E'},
            {'name': 'Hyderabad', 'coords': '17.38\u00b0 N, 78.48\u00b0 E'},
            {'name': 'Ahmedabad', 'coords': '23.02\u00b0 N, 72.57\u00b0 E'},
          ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 20,
                left: 20,
                right: 20,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceElevated : AppColors.pureWhite,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Panchang Location',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Panchang calculations (Tithi, Sunrise, Muhurtas) dynamically adapt to your geographical coordinates.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: 'Enter city or location name...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: isDark ? AppColors.darkSurface : AppColors.softCream,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                        ),
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.check_circle, color: AppColors.deepSoilGreen),
                        onPressed: () {
                          if (controller.text.trim().isNotEmpty) {
                            setState(() {
                              _locationLabel = '${controller.text.trim()}, India';
                            });
                            Navigator.pop(ctx);
                          }
                        },
                      ),
                    ),
                    onSubmitted: (val) {
                      if (val.trim().isNotEmpty) {
                        setState(() {
                          _locationLabel = '${val.trim()}, India';
                        });
                        Navigator.pop(ctx);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Holy & Major Vedic Centers:',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: quickCities.map((city) {
                      final isSelected = _locationLabel.contains(city['name']!);
                      return ActionChip(
                        label: Text(city['name']!),
                        avatar: Icon(
                          isSelected ? Icons.check_circle : Icons.place_outlined,
                          size: 14,
                          color: isSelected ? AppColors.harvestAmber : null,
                        ),
                        backgroundColor: isSelected
                            ? (isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen).withValues(alpha: 0.15)
                            : (isDark ? AppColors.darkSurface : AppColors.softCream),
                        onPressed: () {
                          setState(() {
                            _locationLabel = '${city['name']!}, India (${city['coords']!})';
                          });
                          Navigator.pop(ctx);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _tabController.dispose();
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
            // Background pattern
            PanchangBackground(isDark: isDark),

            // Main scroll area
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Animated Header matching Home Screen
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: BlocBuilder<PanchangHomeCubit, PanchangHomeState>(
                        buildWhen: (previous, current) =>
                            current is PanchangHomeSuccess,
                        builder: (context, state) {
                          final selectedDate =
                              state is PanchangHomeSuccess
                                  ? state.selectedDate
                                  : DateTime.now();
                          return PanchangHeaderWidget(
                            selectedDate: selectedDate,
                            isDark: isDark,
                            locationLabel: _locationLabel,
                            onLocationTap: () => _showLocationPicker(context),
                            onDateTap: () => _showDatePicker(selectedDate),
                            onPreviousDay: () => _cubit.loadDate(
                              selectedDate.subtract(const Duration(days: 1)),
                            ),
                            onNextDay: () => _cubit.loadDate(
                              selectedDate.add(const Duration(days: 1)),
                            ),
                            onTodayTap: () => _cubit.loadToday(),
                            onBack: () {
                              if (Navigator.of(context).canPop()) {
                                Navigator.of(context).pop();
                              } else {
                                context.go('/home');
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),

                // Tab Bar Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : AppColors.pureWhite,
                        borderRadius: BorderRadius.circular(16),
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
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          color: isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelColor: isDark ? AppColors.charcoal : AppColors.pureWhite,
                        unselectedLabelColor: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.6),
                        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                        tabs: const [
                          Tab(text: 'Vedic Panchang'),
                          Tab(text: 'Personalized & Ayurveda'),
                        ],
                      ),
                    ),
                  ),
                ),

                // Main Content
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
                                onRetry: () => _cubit.loadToday(),
                              ),
                            );
                          }

                          if (state is PanchangHomeSuccess) {
                            return AnimatedBuilder(
                              animation: _tabController,
                              builder: (context, _) {
                                if (_tabController.index == 0) {
                                  return _buildPanchangTab(context, state, isDark);
                                } else {
                                  return _buildPersonalizedTab(context, state, isDark);
                                }
                              },
                            );
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

  /// Tab 1: Objective Astrological Panchang
  Widget _buildPanchangTab(
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

          // Panchang Core 4 Grid (Tithi, Nakshatra, Yoga, Karana)
          PanchangGridCard(
            day: day,
            selectedDate: state.selectedDate,
            lunar: day.lunar,
            isDark: isDark,
          ),
          const SizedBox(height: 20),

          // Inauspicious Timings Card (Rahu Kalam, Yamaganda, Gulika)
          if (day.inauspiciousTimings != null)
            InauspiciousTimingsCard(
              timings: day.inauspiciousTimings!,
              isDark: isDark,
            ),
          if (day.inauspiciousTimings != null) const SizedBox(height: 20),

          // Auspicious Muhurats (Abhijit, Brahma, Choghadiya)
          if (day.auspiciousMuhurats != null)
            AuspiciousMuhuratsCard(
              muhurats: day.auspiciousMuhurats!,
              isDark: isDark,
            ),
          if (day.auspiciousMuhurats != null) const SizedBox(height: 20),

          // Chronological Daily Muhurta Timeline
          DailyMuhurtaTimelineCard(day: day, isDark: isDark),
          const SizedBox(height: 20),

          // Planetary Positions (Graha Sthiti)
          if (day.planets != null && day.planets!.isNotEmpty) ...[
            PlanetaryPositionsCard(planets: day.planets!, isDark: isDark),
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
              if (mounted) {
                _cubit.loadDate(state.selectedDate);
              }
            },
          ),
          const SizedBox(height: 20),

          // Highlights & Festivals Section
          if (state.highlights != null && state.highlights!.items.isNotEmpty) ...[
            PanchangHighlightsSection(
              highlights: state.highlights!,
              isDark: isDark,
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }

  /// Tab 2: Personalized Profile, Kundli, Body Type, AI Insight, Ayurveda & Anaad Diet Recommendations
  Widget _buildPersonalizedTab(
    BuildContext context,
    PanchangHomeSuccess state,
    bool isDark,
  ) {
    final day = state.day;
    final isQuizDone = _healthProfile?['onboarding_status'] == 'QUIZ_DONE' ||
        _healthProfile?['onboarding_status'] == 'COMPLETE' ||
        (_healthProfile?['prakriti_dosha'] != null &&
            _healthProfile!['prakriti_dosha'].toString().isNotEmpty);

    final tokenUser = TokenService().currentUser;
    String? tokenUserName;
    if (tokenUser != null) {
      final fn = tokenUser.firstName.trim();
      final ln = tokenUser.lastName.trim();
      if (fn.isNotEmpty || ln.isNotEmpty) {
        tokenUserName = '$fn $ln'.trim();
      } else if (tokenUser.username.isNotEmpty &&
          !tokenUser.username.startsWith('+') &&
          !tokenUser.username.contains('@')) {
        tokenUserName = tokenUser.username;
      }
    }

    final String? resolvedUserName = (_healthProfile?['kundli_person_name']?.toString().trim().isNotEmpty == true)
        ? _healthProfile!['kundli_person_name'].toString().trim()
        : (_healthProfile?['user_name']?.toString().trim().isNotEmpty == true &&
                _healthProfile!['user_name'] != 'User Profile' &&
                _healthProfile!['user_name'] != 'User')
            ? _healthProfile!['user_name'].toString().trim()
            : (_healthProfile?['name']?.toString().trim().isNotEmpty == true &&
                    _healthProfile!['name'] != 'User Profile' &&
                    _healthProfile!['name'] != 'User')
                ? _healthProfile!['name'].toString().trim()
                : (_healthProfile?['first_name']?.toString().trim().isNotEmpty == true &&
                        _healthProfile!['first_name'] != 'User Profile' &&
                        _healthProfile!['first_name'] != 'User')
                    ? _healthProfile!['first_name'].toString().trim()
                    : tokenUserName;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. User Profile Summary Card
          UserProfileSummaryCard(
            isDark: isDark,
            userName: resolvedUserName,
            profileImageUrl: _healthProfile?['profile_picture'] ?? tokenUser?.profilePicture,
            dateOfBirth: _healthProfile?['date_of_birth'],
            timeOfBirth: _healthProfile?['time_of_birth'],
            birthCity: _healthProfile?['birth_city'],
            primaryDosha: _healthProfile?['primary_dosha'] ?? _healthProfile?['prakriti_dosha'],
            onboardingStatus: _healthProfile?['onboarding_status'] ??
                ((_healthProfile?['date_of_birth'] != null &&
                        _healthProfile!['date_of_birth'].toString().isNotEmpty)
                    ? 'COMPLETE'
                    : null),
            onEditProfile: () async {
              await context.push('/kundli-input');
              _loadPersonalizedData();
            },
          ),
          const SizedBox(height: 20),

          // 2. Kundli Summary Card (Only shown if birth details are missing or if raw_kundli_data is available; avoids duplicate empty placeholder if birth details already exist in profile)
          if (_healthProfile?['date_of_birth'] == null ||
              _healthProfile!['date_of_birth'].toString().isEmpty ||
              _healthProfile?['raw_kundli_data'] != null) ...[
            KundliSummaryCard(
              kundliData: {
                ...?(_healthProfile?['raw_kundli_data'] as Map<String, dynamic>?),
                if (resolvedUserName != null && resolvedUserName.isNotEmpty)
                  'kundli_person_name': resolvedUserName,
              },
              isDark: isDark,
            ),
            const SizedBox(height: 20),
          ],

          // 3. Prakriti Body Type Assessment Card
          PrakritiAssessmentCard(
            isDark: isDark,
            isQuizDone: isQuizDone,
            vataScore: double.tryParse('${_healthProfile?['vata_score'] ?? 0}') ?? 0.0,
            pittaScore: double.tryParse('${_healthProfile?['pitta_score'] ?? 0}') ?? 0.0,
            kaphaScore: double.tryParse('${_healthProfile?['kapha_score'] ?? 0}') ?? 0.0,
            primaryDosha: _healthProfile?['primary_dosha'] ?? _healthProfile?['prakriti_dosha'],
            secondaryDosha: _healthProfile?['secondary_dosha'],
            onTakeQuiz: () async {
              await context.push('/prakriti-quiz');
              _loadPersonalizedData();
            },
            onViewAnswers: () => context.push('/prakriti-answers'),
          ),
          const SizedBox(height: 20),

          // 4. AI Explanation / Insight Card
          PanchangInsightCard(day: day, isDark: isDark),
          const SizedBox(height: 20),

          // 5. Ayurvedic Guidance Card (Prakriti, foods to favor/avoid)
          AyurvedicGuidanceCard(day: day, isDark: isDark),
          const SizedBox(height: 20),

          // 6. Personalized Diet & Product Recommendations
          PersonalizedRecommendationsCard(
            day: day,
            isDark: isDark,
            userDosha: _healthProfile?['primary_dosha'] ?? _healthProfile?['prakriti_dosha'],
          ),
          const SizedBox(height: 20),

          // 7. Uploaded Media Gallery Card (Medical Reports & Food Thali) (Commented out)
          // UploadedMediaCard(
          //   isDark: isDark,
          //   medicalReports: _medicalReports,
          //   foodThaliLogs: _foodThaliLogs,
          // ),
          // const SizedBox(height: 20),

          // 8. Individual AI Memory Card (Only shown if memory facts exist in DB)
          if (_memoryFacts.isNotEmpty) ...[
            AiMemoryCard(
              isDark: isDark,
              memoryFacts: _memoryFacts,
              isLoading: _loadingPersonalized,
            ),
            const SizedBox(height: 20),
          ],

          // 9. Quick Action shortcuts
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
