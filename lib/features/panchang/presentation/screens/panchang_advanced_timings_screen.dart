import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grocery_app/core/theme/app_colors.dart';
import 'package:intl/intl.dart';

import 'package:grocery_app/common_widgets/error_state_widget.dart';
import 'package:grocery_app/features/panchang/presentation/cubit/panchang_home_cubit.dart';
import 'package:grocery_app/features/panchang/presentation/cubit/panchang_home_state.dart';
import 'package:grocery_app/models/panchang/panchang_day_models.dart';
import 'package:grocery_app/services/api_config.dart';
import 'package:grocery_app/services/content_config_service.dart';

/// Advanced Panchang Timings Screen with Vedic Planet Colors
class PanchangAdvancedTimingsScreen extends StatefulWidget {
  final DateTime selectedDate;

  const PanchangAdvancedTimingsScreen({super.key, required this.selectedDate});

  @override
  State<PanchangAdvancedTimingsScreen> createState() =>
      _PanchangAdvancedTimingsScreenState();
}

class _PanchangAdvancedTimingsScreenState
    extends State<PanchangAdvancedTimingsScreen>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final AnimationController _pulseController;

  // Vedic Planet Data with authentic colors and symbols
  static const Map<String, _PlanetData> planetData = {
    'Sun': _PlanetData(
      name: 'Sun',
      sanskrit: 'सूर्य (Surya)',
      symbol: '☉',
      emoji: '☀️',
      color: AppColors.harvestAmber,
      gradientColors: [AppColors.harvestAmber, AppColors.warmGold],
      deity: 'Surya Dev',
      day: 'Sunday',
      nature: 'Malefic (Krura)',
      significance: 'Soul, Authority, Father',
    ),
    'Moon': _PlanetData(
      name: 'Moon',
      sanskrit: 'चन्द्र (Chandra)',
      symbol: '☽',
      emoji: '🌙',
      color: AppColors.parchment,
      gradientColors: [AppColors.parchment, AppColors.softCream],
      deity: 'Chandra Dev',
      day: 'Monday',
      nature: 'Benefic (Saumya)',
      significance: 'Mind, Mother, Emotions',
    ),
    'Mars': _PlanetData(
      name: 'Mars',
      sanskrit: 'मंगल (Mangal)',
      symbol: '♂',
      emoji: '🔴',
      color: AppColors.rawEarth,
      gradientColors: [AppColors.rawEarth, AppColors.softRed],
      deity: 'Mangal Dev',
      day: 'Tuesday',
      nature: 'Malefic (Krura)',
      significance: 'Courage, Energy, Siblings',
    ),
    'Mercury': _PlanetData(
      name: 'Mercury',
      sanskrit: 'बुध (Budha)',
      symbol: '☿',
      emoji: '🟢',
      color: AppColors.successGreen,
      gradientColors: [AppColors.successGreen, AppColors.mintGreen],
      deity: 'Budha Dev',
      day: 'Wednesday',
      nature: 'Neutral (Mishra)',
      significance: 'Intelligence, Communication',
    ),
    'Jupiter': _PlanetData(
      name: 'Jupiter',
      sanskrit: 'गुरु (Guru)',
      symbol: '♃',
      emoji: '🟡',
      color: AppColors.warmGold,
      gradientColors: [AppColors.warmGold, AppColors.harvestAmber],
      deity: 'Brihaspati',
      day: 'Thursday',
      nature: 'Benefic (Saumya)',
      significance: 'Wisdom, Fortune, Teacher',
    ),
    'Venus': _PlanetData(
      name: 'Venus',
      sanskrit: 'शुक्र (Shukra)',
      symbol: '♀',
      emoji: '💎',
      color: AppColors.parchment,
      gradientColors: [AppColors.parchment, AppColors.softCream],
      deity: 'Shukra Dev',
      day: 'Friday',
      nature: 'Benefic (Saumya)',
      significance: 'Love, Beauty, Luxury',
    ),
    'Saturn': _PlanetData(
      name: 'Saturn',
      sanskrit: 'शनि (Shani)',
      symbol: '♄',
      emoji: '🔵',
      color: AppColors.charcoal,
      gradientColors: [AppColors.charcoal, Color(0xFF3A3A3A)],
      deity: 'Shani Dev',
      day: 'Saturday',
      nature: 'Malefic (Krura)',
      significance: 'Karma, Discipline, Longevity',
    ),
  };

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _controller.forward();
    _loadEncyclopediaData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PanchangHomeCubit>().loadMuhurats(
        widget.selectedDate,
        types: ['hora', 'choghadiya'],
      );
    });
  }

  Future<void> _loadEncyclopediaData() async {
    try {
      await Future.wait([
        ContentConfigService().getEncyclopediaCategory(
          endpoint: ApiConfig.encyclopediaPlanets,
        ),
        ContentConfigService().getEncyclopediaCategory(
          endpoint: ApiConfig.encyclopediaChoghadiyaTypes,
        ),
      ]);
    } catch (_) {}
  }


  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  String formatTime(dynamic time) {
    if (time == null) return '--:--';
    DateTime dateTime;
    if (time is String) {
      try {
        final parts = time.split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        dateTime = DateTime(2024, 1, 1, hour, minute);
      } catch (e) {
        return time;
      }
    } else if (time is DateTime) {
      dateTime = time.toLocal();
    } else {
      return '--:--';
    }
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$hour12:${minute.toString().padLeft(2, '0')} $period';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.pureBlack : AppColors.parchment,
      body: BlocBuilder<PanchangHomeCubit, PanchangHomeState>(
        builder: (context, state) {
          if (state is PanchangMuhuratsLoading) {
            return _buildLoadingState(isDark);
          }
          if (state is PanchangHomeError) {
            return ErrorStateWidget(
              subtitle: state.message,
              onRetry:
                  () => context.read<PanchangHomeCubit>().loadMuhurats(
                    widget.selectedDate,
                    types: ['hora', 'choghadiya'],
                  ),
            );
          }
          if (state is! PanchangMuhuratsSuccess) {
            return const Center(child: AutoSizeText('No data available'));
          }
          final muhurats = state.muhurats;
          return CustomScrollView(
            slivers: [
              _buildAppBar(isDark),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPlanetLegendCard(isDark),
                          const SizedBox(height: 20),
                          if (muhurats.hora != null)
                            _buildHoraCard(muhurats.hora!, isDark),
                          if (muhurats.hora != null) const SizedBox(height: 20),
                          if (muhurats.choghadiya != null)
                            _buildChoghadiyaCard(muhurats.choghadiya!, isDark),
                        ],
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
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
              boxShadow: [
                BoxShadow(
                  color: AppColors.parchment.withValues(alpha: 0.4),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              Icons.schedule_rounded,
              color: AppColors.parchment,
              size: 40,
            ),
          ),
          const SizedBox(height: 24),
          AutoSizeText(
            'Loading Planetary Hours...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color:
                  isDark
                      ? AppColors.pureWhite.withValues(alpha: 0.54)
                      : AppColors.charcoal54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(bool isDark) {
    return SliverAppBar(
      expandedHeight: 160,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.deepSoilGreen,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.info_outline_rounded,
              color: Colors.white,
            ),
            onPressed: () => _showHoraInfoDialog(context, isDark),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AutoSizeText(
              'Advanced Timings',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            AutoSizeText(
              DateFormat('EEEE, d MMMM yyyy').format(widget.selectedDate),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.deepSoilGreen,
                AppColors.successGreen,
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 30,
                right: 20,
                child: _buildDecorativePlanet('☉', Colors.white, 50),
              ),
              Positioned(
                top: 60,
                right: 90,
                child: _buildDecorativePlanet('☽', Colors.white, 35),
              ),
              Positioned(
                top: 40,
                right: 150,
                child: _buildDecorativePlanet('♂', Colors.white, 28),
              ),
              Positioned(
                bottom: 60,
                right: 40,
                child: _buildDecorativePlanet('♃', Colors.white, 32),
              ),
              Positioned(
                bottom: 70,
                right: 100,
                child: _buildDecorativePlanet('♀', Colors.white, 25),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDecorativePlanet(String symbol, Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
      ),
      child: Center(
        child: AutoSizeText(
          symbol,
          style: TextStyle(fontSize: size * 0.5, color: color),
        ),
      ),
    );
  }

  Widget _buildPlanetLegendCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.public,
                  color: isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AutoSizeText(
                      'Navagraha - Seven Planets',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.pureWhite : AppColors.charcoal,
                      ),
                    ),
                    AutoSizeText(
                      'Vedic planetary rulers of time',
                      style: TextStyle(
                        fontSize: 12,
                        color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children:
                planetData.entries
                    .map((entry) => _buildPlanetChip(entry.value, isDark))
                    .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanetChip(_PlanetData planet, bool isDark) {
    return GestureDetector(
      onTap: () => _showPlanetDetailDialog(context, planet, isDark),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: planet.color.withValues(alpha: isDark ? 0.2 : 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: planet.color.withValues(alpha: 0.4),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: planet.gradientColors),
                boxShadow: [
                  BoxShadow(
                    color: planet.color.withValues(alpha: 0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: AutoSizeText(
                  planet.symbol,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: planet.name == 'Moon' || planet.name == 'Venus'
                        ? AppColors.charcoal
                        : AppColors.parchment,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            AutoSizeText(
              planet.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.pureWhite : AppColors.charcoal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHoraCard(PanchangHora hora, bool isDark) {
    final horas = hora.slots;
    if (horas.isEmpty) return const SizedBox.shrink();

    return Container(
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
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.03),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
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
                    Icons.alarm_rounded,
                    color: isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AutoSizeText(
                        'Hora Timings',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.pureWhite : AppColors.charcoal,
                        ),
                      ),
                      AutoSizeText(
                        '${horas.length} planetary hours • Each ~1 hour',
                        style: TextStyle(
                          fontSize: 12,
                          color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children:
                  horas
                      .asMap()
                      .entries
                      .map(
                        (entry) => Padding(
                          padding: EdgeInsets.only(
                            bottom: entry.key < horas.length - 1 ? 10 : 0,
                          ),
                          child: _buildEnhancedHoraItem(
                            entry.value,
                            entry.value.isCurrent,
                            isDark,
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedHoraItem(
    PanchangHoraSlot horaSlot,
    bool isCurrent,
    bool isDark,
  ) {
    final planet = planetData[horaSlot.planet] ?? planetData['Sun']!;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isCurrent
            ? (isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen).withValues(alpha: 0.1)
            : (isDark ? AppColors.darkSurfaceElevated : AppColors.softCream),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrent
              ? (isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen)
              : (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.06),
          width: isCurrent ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: planet.gradientColors,
              ),
              boxShadow: [
                BoxShadow(
                  color: planet.color.withValues(alpha: isCurrent ? 0.5 : 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: AutoSizeText(
                planet.symbol,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color:
                      planet.name == 'Moon' || planet.name == 'Venus'
                          ? AppColors.charcoal
                          : AppColors.parchment,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AutoSizeText(
                      planet.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.pureWhite : AppColors.charcoal,
                      ),
                    ),
                    const SizedBox(width: 6),
                    AutoSizeText(
                      planet.emoji,
                      style: const TextStyle(fontSize: 14),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: (isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: AutoSizeText(
                          'NOW',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                AutoSizeText(
                  planet.sanskrit,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontStyle: FontStyle.italic,
                    color: isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: AutoSizeText(
                  formatTime(horaSlot.start),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.pureWhite : AppColors.charcoal,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              AutoSizeText(
                'to ${formatTime(horaSlot.end)}',
                style: TextStyle(
                  fontSize: 11,
                  color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChoghadiyaCard(PanchangChoghadiya choghadiya, bool isDark) {
    final dayChoghadiyas = choghadiya.day;
    final nightChoghadiyas = choghadiya.night;

    return Container(
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
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.03),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
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
                    Icons.schedule_rounded,
                    color: isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AutoSizeText(
                        'Choghadiya',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.pureWhite : AppColors.charcoal,
                        ),
                      ),
                      AutoSizeText(
                        'Auspicious muhurat periods',
                        style: TextStyle(
                          fontSize: 12,
                          color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _showChoghadiyaInfoDialog(context, isDark),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.06),
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
          ),
          if (dayChoghadiyas.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
              child: Row(
                children: [
                  const Icon(Icons.wb_sunny_rounded, color: AppColors.harvestAmber, size: 18),
                  const SizedBox(width: 8),
                  AutoSizeText(
                    'Day Choghadiya',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.pureWhite : AppColors.charcoal,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children:
                    dayChoghadiyas
                        .asMap()
                        .entries
                        .map(
                          (entry) => Padding(
                            padding: EdgeInsets.only(
                              bottom:
                                  entry.key < dayChoghadiyas.length - 1
                                      ? 10
                                      : 0,
                            ),
                            child: _buildEnhancedChoghadiyaItem(
                              entry.value,
                              isDark,
                            ),
                          ),
                        )
                        .toList(),
              ),
            ),
          ],
          if (nightChoghadiyas.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 8),
              child: Row(
                children: [
                  const Icon(Icons.nightlight_round, color: AppColors.deepSoilGreen, size: 18),
                  const SizedBox(width: 8),
                  AutoSizeText(
                    'Night Choghadiya',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.pureWhite : AppColors.charcoal,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children:
                    nightChoghadiyas
                        .asMap()
                        .entries
                        .map(
                          (entry) => Padding(
                            padding: EdgeInsets.only(
                              bottom:
                                  entry.key < nightChoghadiyas.length - 1
                                      ? 10
                                      : 0,
                            ),
                            child: _buildEnhancedChoghadiyaItem(
                              entry.value,
                              isDark,
                            ),
                          ),
                        )
                        .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEnhancedChoghadiyaItem(
    PanchangChoghadiyaSlot choghadiyaSlot,
    bool isDark,
  ) {
    final choghadiyaData = {
      'Amrit': _ChoghadiyaData(
        'Amrit',
        '🍯',
        AppColors.parchment,
        true,
        'Most auspicious',
      ),
      'Shubh': _ChoghadiyaData(
        'Shubh',
        '✨',
        AppColors.parchment,
        true,
        'Auspicious',
      ),
      'Labh': _ChoghadiyaData(
        'Labh',
        '💰',
        AppColors.parchment,
        true,
        'Profitable',
      ),
      'Char': _ChoghadiyaData(
        'Char',
        '🚶',
        AppColors.parchment,
        true,
        'Good for travel',
      ),
      'Rog': _ChoghadiyaData(
        'Rog',
        '🤒',
        AppColors.parchment,
        false,
        'Inauspicious',
      ),
      'Kaal': _ChoghadiyaData('Kaal', '⚫', AppColors.parchment, false, 'Avoid'),
      'Udveg': _ChoghadiyaData(
        'Udveg',
        '😰',
        AppColors.parchment,
        false,
        'Stressful',
      ),
    };

    _ChoghadiyaData? data;
    for (var entry in choghadiyaData.entries) {
      if (choghadiyaSlot.name.toLowerCase().contains(entry.key.toLowerCase())) {
        data = entry.value;
        break;
      }
    }
    data ??= _ChoghadiyaData(
      choghadiyaSlot.name,
      '⏱️',
      AppColors.parchment,
      false,
      '',
    );
    final isCurrent = choghadiyaSlot.isCurrent;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isCurrent
            ? (data.isAuspicious ? AppColors.successGreen : AppColors.rawEarth).withValues(alpha: isDark ? 0.15 : 0.08)
            : (isDark ? AppColors.darkSurfaceElevated : AppColors.softCream),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrent
              ? (data.isAuspicious ? AppColors.successGreen : AppColors.rawEarth)
              : (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.06),
          width: isCurrent ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (data.isAuspicious ? AppColors.successGreen : AppColors.rawEarth).withValues(alpha: isDark ? 0.2 : 0.1),
              border: Border.all(
                color: (data.isAuspicious ? AppColors.successGreen : AppColors.rawEarth).withValues(alpha: 0.4),
                width: 1.2,
              ),
            ),
            child: Center(
              child: AutoSizeText(
                data.emoji,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AutoSizeText(
                      choghadiyaSlot.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.pureWhite : AppColors.charcoal,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color:
                            data.isAuspicious
                                ? AppColors.deepSoilGreen.withValues(
                                  alpha: isDark ? 0.25 : 0.12,
                                )
                                : AppColors.rawEarth.withValues(
                                  alpha: isDark ? 0.25 : 0.12,
                                ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: AutoSizeText(
                        data.isAuspicious ? 'Good' : 'Avoid',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color:
                              data.isAuspicious
                                  ? AppColors.deepSoilGreen
                                  : AppColors.rawEarth,
                        ),
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: (isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: AutoSizeText(
                          'NOW',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (data.description.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  AutoSizeText(
                    data.description,
                    style: TextStyle(
                      fontSize: 11,
                      color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: AutoSizeText(
                  formatTime(choghadiyaSlot.start),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.pureWhite : AppColors.charcoal,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              AutoSizeText(
                'to ${formatTime(choghadiyaSlot.end)}',
                style: TextStyle(
                  fontSize: 11,
                  color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPlanetDetailDialog(
    BuildContext context,
    _PlanetData planet,
    bool isDark,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: AppColors.transparent,
            insetPadding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 360),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceElevated : AppColors.pureWhite,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.08),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: planet.gradientColors),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: AutoSizeText(
                              planet.symbol,
                              style: TextStyle(
                                fontSize: 36,
                                color: planet.name == 'Moon' || planet.name == 'Venus'
                                    ? AppColors.charcoal
                                    : AppColors.parchment,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        AutoSizeText(
                          planet.name,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: planet.name == 'Moon' || planet.name == 'Venus'
                                ? AppColors.charcoal
                                : AppColors.parchment,
                          ),
                        ),
                        AutoSizeText(
                          planet.sanskrit,
                          style: TextStyle(
                            fontSize: 14,
                            color: (planet.name == 'Moon' || planet.name == 'Venus'
                                    ? AppColors.charcoal
                                    : AppColors.parchment)
                                .withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildPlanetDetailRow(
                          Icons.temple_hindu,
                          'Deity',
                          planet.deity,
                          planet.color,
                          isDark,
                        ),
                        const SizedBox(height: 10),
                        _buildPlanetDetailRow(
                          Icons.calendar_today,
                          'Rules',
                          planet.day,
                          planet.color,
                          isDark,
                        ),
                        const SizedBox(height: 10),
                        _buildPlanetDetailRow(
                          Icons.balance,
                          'Nature',
                          planet.nature,
                          planet.color,
                          isDark,
                        ),
                        const SizedBox(height: 10),
                        _buildPlanetDetailRow(
                          Icons.star,
                          'Signifies',
                          planet.significance,
                          planet.color,
                          isDark,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: planet.color,
                          foregroundColor:
                              planet.name == 'Moon' || planet.name == 'Venus'
                                  ? AppColors.charcoal
                                  : AppColors.parchment,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const AutoSizeText(
                          'Close',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildPlanetDetailRow(
    IconData icon,
    String label,
    String value,
    Color color,
    bool isDark,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AutoSizeText(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.6),
                ),
              ),
              AutoSizeText(
                value,
                style: TextStyle(
                  fontSize: 13.5,
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

  void _showHoraInfoDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: AppColors.transparent,
            insetPadding: const EdgeInsets.all(20),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceElevated : AppColors.pureWhite,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.08),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.04),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
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
                              Icons.alarm_rounded,
                              color: isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AutoSizeText(
                                  'What is Hora?',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? AppColors.pureWhite : AppColors.charcoal,
                                  ),
                                ),
                                AutoSizeText(
                                  'Planetary hours in Vedic astrology',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(
                              Icons.close_rounded,
                              color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AutoSizeText(
                            'Hora divides each day into 24 planetary hours, with each hour ruled by one of the seven Vedic planets. The first hora of the day is ruled by the planet that rules that day.',
                            style: TextStyle(
                              fontSize: 13.5,
                              height: 1.5,
                              color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(height: 20),
                          AutoSizeText(
                            'Best Activities by Planet:',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.pureWhite : AppColors.charcoal,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _buildHoraActivityItem('☉ Sun', 'Government work, authority, leadership', AppColors.harvestAmber, isDark),
                          _buildHoraActivityItem('☽ Moon', 'Creative work, travel, motherly care', Colors.blueGrey, isDark),
                          _buildHoraActivityItem('♂ Mars', 'Property, machinery, physical tasks', AppColors.rawEarth, isDark),
                          _buildHoraActivityItem('☿ Mercury', 'Business, studies, communication', AppColors.successGreen, isDark),
                          _buildHoraActivityItem('♃ Jupiter', 'Religious deeds, higher education, finance', AppColors.warmGold, isDark),
                          _buildHoraActivityItem('♀ Venus', 'Love, arts, luxury, creative design', Colors.pinkAccent, isDark),
                          _buildHoraActivityItem('♄ Saturn', 'Agriculture, real estate, discipline, labor', isDark ? Colors.grey : AppColors.charcoal, isDark),
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

  Widget _buildHoraActivityItem(
    String planet,
    String activities,
    Color color,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: (isDark ? AppColors.darkSurface : AppColors.softCream),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.15),
                border: Border.all(color: color.withValues(alpha: 0.4), width: 1.2),
              ),
              child: Center(
                child: AutoSizeText(
                  planet.split(' ')[0],
                  style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AutoSizeText(
                    planet.split(' ').sublist(1).join(' '),
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.pureWhite : AppColors.charcoal,
                    ),
                  ),
                  AutoSizeText(
                    activities,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.65),
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

  void _showChoghadiyaInfoDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: AppColors.transparent,
            insetPadding: const EdgeInsets.all(20),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceElevated : AppColors.pureWhite,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.08),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.04),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
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
                              Icons.schedule_rounded,
                              color: isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AutoSizeText(
                                  'What is Choghadiya?',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? AppColors.pureWhite : AppColors.charcoal,
                                  ),
                                ),
                                AutoSizeText(
                                  'Quick muhurat selection guide',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(
                              Icons.close_rounded,
                              color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AutoSizeText(
                            'Choghadiya divides day and night into 8 periods each, totaling 16 muhurats. It is a quick and effective Vedic system to select the best time for auspicious work.',
                            style: TextStyle(
                              fontSize: 13.5,
                              height: 1.5,
                              color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(height: 20),
                          AutoSizeText(
                            'Types of Choghadiya:',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.pureWhite : AppColors.charcoal,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _buildChoghadiyaTypeItem(
                            '🍯 Amrit',
                            'Best for all activities, auspicious',
                            AppColors.deepSoilGreen,
                            true,
                            isDark,
                          ),
                          _buildChoghadiyaTypeItem(
                            '✨ Shubh',
                            'Auspicious for ceremonies & work',
                            AppColors.deepSoilGreen,
                            true,
                            isDark,
                          ),
                          _buildChoghadiyaTypeItem(
                            '💰 Labh',
                            'Profitable, great for business & transactions',
                            AppColors.deepSoilGreen,
                            true,
                            isDark,
                          ),
                          _buildChoghadiyaTypeItem(
                            '🚶 Char',
                            'Dynamic, good for travel & movement',
                            AppColors.harvestAmber,
                            true,
                            isDark,
                          ),
                          _buildChoghadiyaTypeItem(
                            '🤒 Rog',
                            'Inauspicious, may cause illness/hurdles',
                            AppColors.rawEarth,
                            false,
                            isDark,
                          ),
                          _buildChoghadiyaTypeItem(
                            '⚫ Kaal',
                            'Very inauspicious, ruled by Saturn - avoid',
                            AppColors.rawEarth,
                            false,
                            isDark,
                          ),
                          _buildChoghadiyaTypeItem(
                            '😰 Udveg',
                            'Causes anxiety and fear, ruled by Sun - avoid',
                            AppColors.rawEarth,
                            false,
                            isDark,
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

  Widget _buildChoghadiyaTypeItem(
    String name,
    String desc,
    Color color,
    bool isGood,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: (isDark ? AppColors.darkSurface : AppColors.softCream),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          children: [
            AutoSizeText(
              name.split(' ')[0],
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AutoSizeText(
                        name.split(' ').sublist(1).join(' '),
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.pureWhite : AppColors.charcoal,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isGood
                                  ? AppColors.deepSoilGreen.withValues(alpha: 0.15)
                                  : AppColors.rawEarth.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: AutoSizeText(
                          isGood ? 'Auspicious' : 'Avoid',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isGood ? AppColors.deepSoilGreen : AppColors.rawEarth,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  AutoSizeText(
                    desc,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.65),
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
}

class _PlanetData {
  final String name, sanskrit, symbol, emoji, deity, day, nature, significance;
  final Color color;
  final List<Color> gradientColors;
  const _PlanetData({
    required this.name,
    required this.sanskrit,
    required this.symbol,
    required this.emoji,
    required this.color,
    required this.gradientColors,
    required this.deity,
    required this.day,
    required this.nature,
    required this.significance,
  });
}

class _ChoghadiyaData {
  final String name, emoji, description;
  final Color color;
  final bool isAuspicious;
  const _ChoghadiyaData(
    this.name,
    this.emoji,
    this.color,
    this.isAuspicious,
    this.description,
  );
}
