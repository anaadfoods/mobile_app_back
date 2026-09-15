// lib/features/panchang/presentation/screens/kundli_details_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:grocery_app/common_widgets/animated_screen_header.dart';
import 'package:grocery_app/common_widgets/glassmorphic_icon_button.dart';
import 'package:grocery_app/core/theme/app_colors.dart';
import '../cubit/kundli_cubit.dart';
import '../cubit/kundli_state.dart';
import '../widgets/kundli/north_indian_chart_painter.dart';
import '../widgets/kundli/south_indian_chart_painter.dart';
import '../widgets/kundli/kundli_planet_table.dart';
import '../widgets/kundli/kundli_dasha_timeline.dart';
import '../widgets/kundli/kundli_ayurveda_sync_card.dart';
import '../widgets/kundli/kundli_dosha_card.dart';

class KundliDetailsScreen extends StatefulWidget {
  const KundliDetailsScreen({super.key});

  @override
  State<KundliDetailsScreen> createState() => _KundliDetailsScreenState();
}

class _KundliDetailsScreenState extends State<KundliDetailsScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerController;

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _headerController.forward();
    });
  }

  @override
  void dispose() {
    _headerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocBuilder<KundliCubit, KundliState>(
      builder: (context, state) {
        if (state is KundliLoading || state is KundliInitial) {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: Column(
              children: [
                AnimatedScreenHeader(
                  title: 'Janam Kundli',
                  subtitle: 'Vedic Astrology & Planetary Chart',
                  showBack: true,
                  hasParticles: true,
                  animationController: _headerController,
                ),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: (isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen).withValues(alpha: 0.12),
                            ),
                            child: SizedBox(
                              width: 36,
                              height: 36,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Calculating Vedic Janam Kundli...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.charcoal,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Computing Lagna, Planetary Degrees & Dasha Timelines (NASA DE421 Ephemeris)',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: (isDark ? Colors.white : AppColors.charcoal).withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        if (state is KundliError) {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: Column(
              children: [
                AnimatedScreenHeader(
                  title: 'Janam Kundli',
                  subtitle: 'Vedic Astrology & Planetary Chart',
                  showBack: true,
                  hasParticles: true,
                  animationController: _headerController,
                ),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline_rounded, size: 48, color: AppColors.softRed),
                          const SizedBox(height: 16),
                          Text(
                            'Unable to load Kundli',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.charcoal),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            state.message,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : AppColors.charcoal70),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () => context.read<KundliCubit>().loadUserKundli(),
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Try Again'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen,
                              foregroundColor: isDark ? Colors.black : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        if (state is! KundliLoaded) {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: Column(
              children: [
                AnimatedScreenHeader(
                  title: 'Janam Kundli',
                  subtitle: 'Vedic Astrology & Planetary Chart',
                  showBack: true,
                  hasParticles: true,
                  animationController: _headerController,
                  actions: [
                    GlassmorphicIconButton(
                      icon: Icons.edit_calendar_outlined,
                      onTap: () => context.push('/kundli-input'),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            size: 64,
                            color: isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Kundli Generated Yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.charcoal,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Enter your birth date, time, and place to calculate your Lagna, Janma Rashi, Nakshatra, and Doshas.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white70 : AppColors.charcoal70,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => context.push('/kundli-input'),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Enter Birth Details'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen,
                              foregroundColor: isDark ? Colors.black : Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final kundli = state.kundli;
        final isNorth = state.isNorthIndianFormat;

        return DefaultTabController(
          length: 4,
          child: Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: Column(
              children: [
                AnimatedScreenHeader(
                  title: kundli.birthDetails.name.isNotEmpty ? "${kundli.birthDetails.name}'s Kundli" : 'Janam Kundli',
                  subtitle: '${kundli.lagna.sign} Lagna • ${kundli.janmaRashi} Rashi',
                  showBack: true,
                  hasParticles: true,
                  animationController: _headerController,
                  actions: [
                    GlassmorphicIconButton(
                      icon: Icons.person_add_alt_1_outlined,
                      onTap: () => context.push('/kundli-input'),
                    ),
                    const SizedBox(width: 6),
                    GlassmorphicIconButton(
                      icon: Icons.edit_calendar_outlined,
                      onTap: () => context.push('/kundli-input'),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
                if (state.isTemporary)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: (isDark ? AppColors.harvestAmber : AppColors.rawEarth).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: (isDark ? AppColors.harvestAmber : AppColors.rawEarth).withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded, size: 18, color: isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Temporary Kundli (Other\'s Details)',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen),
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.read<KundliCubit>().loadUserKundli(),
                          style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                          child: Text('Restore My Kundli', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen)),
                        ),
                      ],
                    ),
                  ),
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.pureWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? Colors.white12 : AppColors.parchment),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: TabBar(
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    labelColor: isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen,
                    unselectedLabelColor: isDark ? Colors.white60 : AppColors.charcoal60,
                    indicatorColor: isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen,
                    indicatorSize: TabBarIndicatorSize.label,
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(icon: Icon(Icons.grid_view_rounded, size: 20), text: 'Chart'),
                      Tab(icon: Icon(Icons.spa_rounded, size: 20), text: 'Body Type'),
                      Tab(icon: Icon(Icons.stars_rounded, size: 20), text: 'Planets'),
                      Tab(icon: Icon(Icons.timeline_rounded, size: 20), text: 'Dashas'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      // 1. Chart Tab
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            // Today's Planetary Transit Banner (HTML v2.0)
                            Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: (isDark ? AppColors.gold : const Color(0xFFC4900F)).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: (isDark ? AppColors.gold : const Color(0xFFC4900F)).withValues(alpha: 0.35),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppColors.gold,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        style: TextStyle(
                                          fontSize: 12,
                                          height: 1.4,
                                          color: isDark ? Colors.white : AppColors.charcoal,
                                        ),
                                        children: [
                                          const TextSpan(text: 'Lagna Alignment: '),
                                          TextSpan(
                                            text: '${kundli.lagna.signEn} Ascendant (${kundli.lagna.lord} Lord)',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: isDark ? AppColors.goldLight : AppColors.gold,
                                            ),
                                          ),
                                          TextSpan(
                                            text: ' — align with ${kundli.bodyType.primaryDosha} pacifying diet & seasonal Ahara.',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  isNorth ? 'North Indian (Diamond)' : 'South Indian (Grid)',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                Row(
                                  children: [
                                    TextButton.icon(
                                      onPressed: () => context.push('/kundli-input'),
                                      icon: Icon(Icons.person_search_outlined, size: 16, color: isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen),
                                      label: Text('Other\'s', style: TextStyle(color: isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen, fontSize: 12)),
                                    ),
                                    TextButton.icon(
                                      onPressed: () => context.read<KundliCubit>().toggleChartFormat(),
                                      icon: Icon(Icons.swap_horiz, size: 16, color: isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen),
                                      label: Text('Style', style: TextStyle(color: isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen, fontSize: 12)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            RepaintBoundary(
                              child: Container(
                                width: double.infinity,
                                height: 320,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: isDark ? AppColors.darkSurface : AppColors.pureWhite,
                                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04), blurRadius: 10, offset: const Offset(0, 4))],
                                ),
                                child: CustomPaint(
                                    painter: isNorth
                                        ? NorthIndianChartPainter(
                                            kundli: kundli,
                                            borderColor: isDark
                                                ? AppColors.harvestAmber
                                                : const Color(0xFFD4AF37),
                                            primaryColor: isDark
                                                ? AppColors.harvestAmber
                                                : AppColors.deepSoilGreen,
                                            textColor: isDark
                                                ? Colors.white
                                                : AppColors.charcoal,
                                            houseNumberColor: isDark
                                                ? AppColors.harvestAmber.withValues(alpha: 0.8)
                                                : const Color(0xFF8C7A3E),
                                            backgroundColor: isDark
                                                ? AppColors.darkSurfaceElevated
                                                : const Color(0xFFFAF7EE),
                                          )
                                        : SouthIndianChartPainter(
                                            kundli: kundli,
                                            borderColor: isDark
                                                ? AppColors.harvestAmber
                                                : const Color(0xFFD4AF37),
                                            primaryColor: isDark
                                                ? AppColors.harvestAmber
                                                : AppColors.deepSoilGreen,
                                            textColor: isDark
                                                ? Colors.white
                                                : AppColors.charcoal,
                                            backgroundColor: isDark
                                                ? AppColors.darkSurfaceElevated
                                                : const Color(0xFFFAF7EE),
                                            centerColor: isDark
                                                ? AppColors.darkSurface
                                                : const Color(0xFFF3EED9),
                                          ),
                                  ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                _buildBadge(context, 'Lagna', '${kundli.lagna.sign} (${kundli.lagna.degree}°)', isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen, isDark),
                                const SizedBox(width: 8),
                                _buildBadge(context, 'Moon (Rashi)', kundli.janmaRashi, AppColors.infoTeal, isDark),
                                const SizedBox(width: 8),
                                _buildBadge(context, 'Nakshatra', '${kundli.janmaNakshatra} P${kundli.janmaNakshatraPada}', AppColors.rawEarth, isDark),
                              ],
                            ),
                            const SizedBox(height: 16),
                            KundliAyurvedaSyncCard(
                              bodyType: kundli.bodyType,
                              onAskAyurAI: () => context.push('/ai-chat'),
                            ),
                          ],
                        ),
                      ),
                      // 2. Body Type & Doshas Tab
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            KundliAyurvedaSyncCard(
                              bodyType: kundli.bodyType,
                              onAskAyurAI: () => context.push('/ai-chat'),
                            ),
                            const SizedBox(height: 16),
                            KundliDoshaCard(
                              mangalDosha: kundli.mangalDosha,
                              sadeSati: kundli.sadeSati,
                            ),
                          ],
                        ),
                      ),
                      // 3. Planets Tab
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: KundliPlanetTable(planets: kundli.planets),
                      ),
                      // 4. Dashas Tab
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: KundliDashaTimeline(
                          timeline: kundli.dashaTimeline,
                          activeDasha: kundli.activeDasha,
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

  Widget _buildBadge(
    BuildContext context,
    String label,
    String value,
    Color color,
    bool isDark,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.pureWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.white12 : AppColors.parchment),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : AppColors.charcoal60)),
            const SizedBox(height: 2),
            Text(value, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: color)),
          ],
        ),
      ),
    );
  }
}
