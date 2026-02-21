import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../common_widgets/error_state_widget.dart';
import '../../../cubits/panchang/panchang_home_cubit.dart';
import '../../../cubits/panchang/panchang_home_state.dart';
import '../../../models/panchang/panchang_day_models.dart';
import '../../../models/panchang/panchang_muhurats_models.dart';

/// Advanced Panchang Timings Screen with Vedic Planet Colors
class PanchangAdvancedTimingsScreen extends StatefulWidget {
  final DateTime selectedDate;

  const PanchangAdvancedTimingsScreen({super.key, required this.selectedDate});

  @override
  State<PanchangAdvancedTimingsScreen> createState() => _PanchangAdvancedTimingsScreenState();
}

class _PanchangAdvancedTimingsScreenState extends State<PanchangAdvancedTimingsScreen>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final AnimationController _pulseController;

  // Vedic Planet Data with authentic colors and symbols
  static const Map<String, _PlanetData> planetData = {
    'Sun': _PlanetData(
      name: 'Sun', sanskrit: 'सूर्य (Surya)', symbol: '☉', emoji: '☀️',
      color: Color(0xFFFF6B00), gradientColors: [Color(0xFFFF8C00), Color(0xFFFF4500)],
      deity: 'Surya Dev', day: 'Sunday', nature: 'Malefic (Krura)', significance: 'Soul, Authority, Father',
    ),
    'Moon': _PlanetData(
      name: 'Moon', sanskrit: 'चन्द्र (Chandra)', symbol: '☽', emoji: '🌙',
      color: Color(0xFFE8E8E8), gradientColors: [Color(0xFFFFFFFF), Color(0xFFB8C6DB)],
      deity: 'Chandra Dev', day: 'Monday', nature: 'Benefic (Saumya)', significance: 'Mind, Mother, Emotions',
    ),
    'Mars': _PlanetData(
      name: 'Mars', sanskrit: 'मंगल (Mangal)', symbol: '♂', emoji: '🔴',
      color: Color(0xFFDC143C), gradientColors: [Color(0xFFFF4444), Color(0xFFB22222)],
      deity: 'Mangal Dev', day: 'Tuesday', nature: 'Malefic (Krura)', significance: 'Courage, Energy, Siblings',
    ),
    'Mercury': _PlanetData(
      name: 'Mercury', sanskrit: 'बुध (Budha)', symbol: '☿', emoji: '🟢',
      color: Color(0xFF228B22), gradientColors: [Color(0xFF32CD32), Color(0xFF006400)],
      deity: 'Budha Dev', day: 'Wednesday', nature: 'Neutral (Mishra)', significance: 'Intelligence, Communication',
    ),
    'Jupiter': _PlanetData(
      name: 'Jupiter', sanskrit: 'गुरु (Guru)', symbol: '♃', emoji: '🟡',
      color: Color(0xFFFFD700), gradientColors: [Color(0xFFFFD700), Color(0xFFDAA520)],
      deity: 'Brihaspati', day: 'Thursday', nature: 'Benefic (Saumya)', significance: 'Wisdom, Fortune, Teacher',
    ),
    'Venus': _PlanetData(
      name: 'Venus', sanskrit: 'शुक्र (Shukra)', symbol: '♀', emoji: '💎',
      color: Color(0xFFFFB6C1), gradientColors: [Color(0xFFFFDAB9), Color(0xFFFF69B4)],
      deity: 'Shukra Dev', day: 'Friday', nature: 'Benefic (Saumya)', significance: 'Love, Beauty, Luxury',
    ),
    'Saturn': _PlanetData(
      name: 'Saturn', sanskrit: 'शनि (Shani)', symbol: '♄', emoji: '🔵',
      color: Color(0xFF191970), gradientColors: [Color(0xFF4169E1), Color(0xFF000080)],
      deity: 'Shani Dev', day: 'Saturday', nature: 'Malefic (Krura)', significance: 'Karma, Discipline, Longevity',
    ),
  };

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _pulseController = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this)..repeat(reverse: true);
    _controller.forward();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PanchangHomeCubit>().loadMuhurats(widget.selectedDate, types: ['hora', 'choghadiya']);
    });
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
      } catch (e) { return time; }
    } else if (time is DateTime) {
      dateTime = time.toLocal();
    } else { return '--:--'; }
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
      backgroundColor: isDark ? const Color(0xFF080D0A) : const Color(0xFFF4F8F4),
      body: BlocBuilder<PanchangHomeCubit, PanchangHomeState>(
        builder: (context, state) {
          if (state is PanchangMuhuratsLoading) return _buildLoadingState(isDark);
          if (state is PanchangHomeError) {
            return ErrorStateWidget(
              subtitle: state.message,
              onRetry: () => context.read<PanchangHomeCubit>().loadMuhurats(widget.selectedDate, types: ['hora', 'choghadiya']),
            );
          }
          if (state is! PanchangMuhuratsSuccess) return const Center(child: Text('No data available'));
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
                          if (muhurats.hora != null) _buildHoraCard(muhurats.hora!, isDark),
                          if (muhurats.hora != null) const SizedBox(height: 20),
                          if (muhurats.choghadiya != null) _buildChoghadiyaCard(muhurats.choghadiya!, isDark),
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
              gradient: LinearGradient(colors: isDark ? [const Color(0xFF6366F1), const Color(0xFF8B5CF6)] : [const Color(0xFF8B5CF6), const Color(0xFF6366F1)]),
              boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.4), blurRadius: 30, spreadRadius: 5)],
            ),
            child: const Icon(Icons.schedule_rounded, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 24),
          Text('Loading Planetary Hours...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildAppBar(bool isDark) {
    return SliverAppBar(
      expandedHeight: 180,
      floating: false,
      pinned: true,
      backgroundColor: isDark ? const Color(0xFF080D0A) : Colors.white,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: (isDark ? Colors.white : Colors.black).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: IconButton(icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : Colors.black87), onPressed: () => Navigator.pop(context)),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: (isDark ? Colors.white : Colors.black).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: IconButton(icon: Icon(Icons.info_outline_rounded, color: isDark ? Colors.white : Colors.black87), onPressed: () => _showHoraInfoDialog(context, isDark)),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Advanced Timings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
            Text(DateFormat('EEEE, d MMMM yyyy').format(widget.selectedDate), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: (isDark ? Colors.white : Colors.black).withOpacity(0.6))),
          ],
        ),
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
        background: Container(
          decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: isDark ? [const Color(0xFF0D1A0F), const Color(0xFF080D0A)] : [const Color(0xFFEDF4EE), const Color(0xFFF4F8F4)])),
          child: Stack(
            children: [
              Positioned(top: 30, right: 20, child: _buildDecorativePlanet('☉', const Color(0xFFFF6B00), 50)),
              Positioned(top: 60, right: 90, child: _buildDecorativePlanet('☽', const Color(0xFFB8C6DB), 35)),
              Positioned(top: 40, right: 150, child: _buildDecorativePlanet('♂', const Color(0xFFDC143C), 28)),
              Positioned(bottom: 60, right: 40, child: _buildDecorativePlanet('♃', const Color(0xFFFFD700), 32)),
              Positioned(bottom: 70, right: 100, child: _buildDecorativePlanet('♀', const Color(0xFFFFB6C1), 25)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDecorativePlanet(String symbol, Color color, double size) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.2), border: Border.all(color: color.withOpacity(0.5), width: 1)),
      child: Center(child: Text(symbol, style: TextStyle(fontSize: size * 0.5, color: color))),
    );
  }

  Widget _buildPlanetLegendCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: isDark ? [const Color(0xFF0D1A10), const Color(0xFF143318)] : [Colors.white, const Color(0xFFF5F3FF)]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withOpacity(isDark ? 0.3 : 0.15), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]), borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))]), child: const Icon(Icons.public, color: Colors.white, size: 24)),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Navagraha - Seven Planets', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)), Text('Vedic planetary rulers of time', style: TextStyle(fontSize: 12, color: (isDark ? Colors.white : Colors.black).withOpacity(0.6)))])),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(spacing: 10, runSpacing: 10, children: planetData.entries.map((entry) => _buildPlanetChip(entry.value, isDark)).toList()),
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
          gradient: LinearGradient(colors: [planet.gradientColors[0].withOpacity(isDark ? 0.3 : 0.2), planet.gradientColors[1].withOpacity(isDark ? 0.2 : 0.1)]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: planet.color.withOpacity(0.5), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: planet.gradientColors), boxShadow: [BoxShadow(color: planet.color.withOpacity(0.5), blurRadius: 8, spreadRadius: 1)]),
              child: Center(child: Text(planet.symbol, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: planet.name == 'Moon' || planet.name == 'Venus' ? Colors.black87 : Colors.white))),
            ),
            const SizedBox(width: 8),
            Text(planet.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
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
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: isDark ? [const Color(0xFF0D150E), const Color(0xFF0A1510)] : [Colors.white, const Color(0xFFFFFBEB)]),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.4), width: 2),
        boxShadow: [BoxShadow(color: const Color(0xFFFFD700).withOpacity(isDark ? 0.2 : 0.15), blurRadius: 25, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(gradient: LinearGradient(colors: [const Color(0xFFFFD700).withOpacity(isDark ? 0.2 : 0.15), const Color(0xFFF59E0B).withOpacity(isDark ? 0.1 : 0.05)]), borderRadius: const BorderRadius.vertical(top: Radius.circular(22))),
            child: Row(
              children: [
                Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFF59E0B)]), borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: const Color(0xFFFFD700).withOpacity(0.5), blurRadius: 15, offset: const Offset(0, 5))]), child: const Text('⏰', style: TextStyle(fontSize: 24))),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Hora Timings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)), Text('${horas.length} planetary hours • Each ~1 hour', style: TextStyle(fontSize: 12, color: (isDark ? Colors.white : Colors.black).withOpacity(0.6)))])),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: horas.asMap().entries.map((entry) => Padding(padding: EdgeInsets.only(bottom: entry.key < horas.length - 1 ? 12 : 0), child: _buildEnhancedHoraItem(entry.value, entry.value.isCurrent, isDark))).toList()),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedHoraItem(PanchangHoraSlot horaSlot, bool isCurrent, bool isDark) {
    final planet = planetData[horaSlot.planet] ?? planetData['Sun']!;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: isCurrent ? [planet.gradientColors[0].withOpacity(isDark ? 0.4 : 0.25), planet.gradientColors[1].withOpacity(isDark ? 0.2 : 0.1)] : [planet.color.withOpacity(isDark ? 0.15 : 0.08), planet.color.withOpacity(isDark ? 0.05 : 0.02)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isCurrent ? planet.color : planet.color.withOpacity(0.3), width: isCurrent ? 2.5 : 1.5),
        boxShadow: isCurrent ? [BoxShadow(color: planet.color.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 4))] : null,
      ),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: planet.gradientColors), boxShadow: [BoxShadow(color: planet.color.withOpacity(isCurrent ? 0.6 : 0.3), blurRadius: isCurrent ? 15 : 8, spreadRadius: isCurrent ? 2 : 0)]),
            child: Center(child: Text(planet.symbol, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: planet.name == 'Moon' || planet.name == 'Venus' ? Colors.black87 : Colors.white))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [Text(planet.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)), const SizedBox(width: 8), Text(planet.emoji, style: const TextStyle(fontSize: 16)), if (isCurrent) ...[const SizedBox(width: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: planet.color, borderRadius: BorderRadius.circular(8)), child: const Text('NOW', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)))]]),
                const SizedBox(height: 4),
                Text(planet.sanskrit, style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: planet.color)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: planet.color.withOpacity(isDark ? 0.3 : 0.15), borderRadius: BorderRadius.circular(10)), child: Text(formatTime(horaSlot.start), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white : planet.color))),
              const SizedBox(height: 4),
              Text('to ${formatTime(horaSlot.end)}', style: TextStyle(fontSize: 11, color: (isDark ? Colors.white : Colors.black).withOpacity(0.6))),
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
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: isDark ? [const Color(0xFF1A2E1A), const Color(0xFF0A1510)] : [Colors.white, const Color(0xFFF0FFF4)]),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4), width: 2),
        boxShadow: [BoxShadow(color: const Color(0xFF10B981).withOpacity(isDark ? 0.2 : 0.15), blurRadius: 25, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(gradient: LinearGradient(colors: [const Color(0xFF10B981).withOpacity(isDark ? 0.2 : 0.15), const Color(0xFF059669).withOpacity(isDark ? 0.1 : 0.05)]), borderRadius: const BorderRadius.vertical(top: Radius.circular(22))),
            child: Row(
              children: [
                Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]), borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: const Color(0xFF10B981).withOpacity(0.5), blurRadius: 15, offset: const Offset(0, 5))]), child: const Text('🕐', style: TextStyle(fontSize: 24))),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Choghadiya', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)), Text('Auspicious muhurat periods', style: TextStyle(fontSize: 12, color: (isDark ? Colors.white : Colors.black).withOpacity(0.6)))])),
                GestureDetector(onTap: () => _showChoghadiyaInfoDialog(context, isDark), child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.info_outline_rounded, color: isDark ? Colors.green.shade200 : Colors.green.shade700, size: 22))),
              ],
            ),
          ),
          if (dayChoghadiyas.isNotEmpty) ...[
            Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 8), child: Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)]), borderRadius: BorderRadius.circular(10)), child: const Text('☀️', style: TextStyle(fontSize: 18))), const SizedBox(width: 12), Text('Day Choghadiya', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706)))])),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Column(children: dayChoghadiyas.asMap().entries.map((entry) => Padding(padding: EdgeInsets.only(bottom: entry.key < dayChoghadiyas.length - 1 ? 10 : 0), child: _buildEnhancedChoghadiyaItem(entry.value, isDark))).toList())),
          ],
          if (nightChoghadiyas.isNotEmpty) ...[
            Padding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 8), child: Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF60A5FA), Color(0xFF3B82F6)]), borderRadius: BorderRadius.circular(10)), child: const Text('🌙', style: TextStyle(fontSize: 18))), const SizedBox(width: 12), Text('Night Choghadiya', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF3B82F6)))])),
            Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), child: Column(children: nightChoghadiyas.asMap().entries.map((entry) => Padding(padding: EdgeInsets.only(bottom: entry.key < nightChoghadiyas.length - 1 ? 10 : 0), child: _buildEnhancedChoghadiyaItem(entry.value, isDark))).toList())),
          ],
        ],
      ),
    );
  }

  Widget _buildEnhancedChoghadiyaItem(PanchangChoghadiyaSlot choghadiyaSlot, bool isDark) {
    final choghadiyaData = {
      'Amrit': _ChoghadiyaData('Amrit', '🍯', const Color(0xFF10B981), true, 'Most auspicious'),
      'Shubh': _ChoghadiyaData('Shubh', '✨', const Color(0xFF059669), true, 'Auspicious'),
      'Labh': _ChoghadiyaData('Labh', '💰', const Color(0xFF14B8A6), true, 'Profitable'),
      'Char': _ChoghadiyaData('Char', '🚶', const Color(0xFF0EA5E9), true, 'Good for travel'),
      'Rog': _ChoghadiyaData('Rog', '🤒', const Color(0xFFEF4444), false, 'Inauspicious'),
      'Kaal': _ChoghadiyaData('Kaal', '⚫', const Color(0xFF6B7280), false, 'Avoid'),
      'Udveg': _ChoghadiyaData('Udveg', '😰', const Color(0xFFF97316), false, 'Stressful'),
    };

    _ChoghadiyaData? data;
    for (var entry in choghadiyaData.entries) {
      if (choghadiyaSlot.name.toLowerCase().contains(entry.key.toLowerCase())) { data = entry.value; break; }
    }
    data ??= _ChoghadiyaData(choghadiyaSlot.name, '⏱️', const Color(0xFF9CA3AF), false, '');
    final isCurrent = choghadiyaSlot.isCurrent;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: isCurrent ? [data.color.withOpacity(isDark ? 0.4 : 0.25), data.color.withOpacity(isDark ? 0.2 : 0.1)] : [data.color.withOpacity(isDark ? 0.15 : 0.08), data.color.withOpacity(isDark ? 0.05 : 0.02)]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isCurrent ? data.color : data.color.withOpacity(0.3), width: isCurrent ? 2.5 : 1.5),
        boxShadow: isCurrent ? [BoxShadow(color: data.color.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))] : null,
      ),
      child: Row(
        children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(shape: BoxShape.circle, color: data.color.withOpacity(isDark ? 0.3 : 0.2), border: Border.all(color: data.color, width: 2)), child: Center(child: Text(data.emoji, style: const TextStyle(fontSize: 20)))),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [Text(choghadiyaSlot.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)), const SizedBox(width: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: data.isAuspicious ? Colors.green.withOpacity(isDark ? 0.3 : 0.15) : Colors.red.withOpacity(isDark ? 0.3 : 0.15), borderRadius: BorderRadius.circular(8)), child: Text(data.isAuspicious ? 'Good' : 'Avoid', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: data.isAuspicious ? (isDark ? Colors.green.shade200 : Colors.green.shade700) : (isDark ? Colors.red.shade200 : Colors.red.shade700)))), if (isCurrent) ...[const SizedBox(width: 6), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: data.color, borderRadius: BorderRadius.circular(8)), child: const Text('NOW', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)))]]),
                if (data.description.isNotEmpty) ...[const SizedBox(height: 4), Text(data.description, style: TextStyle(fontSize: 11, color: (isDark ? Colors.white : Colors.black).withOpacity(0.6)))],
              ],
            ),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(formatTime(choghadiyaSlot.start), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white : data.color)), Text('to ${formatTime(choghadiyaSlot.end)}', style: TextStyle(fontSize: 11, color: (isDark ? Colors.white : Colors.black).withOpacity(0.6)))]),
        ],
      ),
    );
  }

  void _showPlanetDetailDialog(BuildContext context, _PlanetData planet, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 350),
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: isDark ? [const Color(0xFF0D1A10), const Color(0xFF070C08)] : [Colors.white, const Color(0xFFF5F3FF)]),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: planet.color.withOpacity(0.5), width: 2),
            boxShadow: [BoxShadow(color: planet.color.withOpacity(0.3), blurRadius: 30, spreadRadius: 5)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(gradient: LinearGradient(colors: planet.gradientColors), borderRadius: const BorderRadius.vertical(top: Radius.circular(22))),
                child: Column(
                  children: [
                    Container(width: 80, height: 80, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.2), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 5))]), child: Center(child: Text(planet.symbol, style: TextStyle(fontSize: 40, color: planet.name == 'Moon' || planet.name == 'Venus' ? Colors.black87 : Colors.white)))),
                    const SizedBox(height: 16),
                    Text(planet.name, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: planet.name == 'Moon' || planet.name == 'Venus' ? Colors.black87 : Colors.white)),
                    Text(planet.sanskrit, style: TextStyle(fontSize: 14, color: (planet.name == 'Moon' || planet.name == 'Venus' ? Colors.black : Colors.white).withOpacity(0.8))),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(children: [_buildPlanetDetailRow(Icons.temple_hindu, 'Deity', planet.deity, planet.color, isDark), const SizedBox(height: 12), _buildPlanetDetailRow(Icons.calendar_today, 'Rules', planet.day, planet.color, isDark), const SizedBox(height: 12), _buildPlanetDetailRow(Icons.balance, 'Nature', planet.nature, planet.color, isDark), const SizedBox(height: 12), _buildPlanetDetailRow(Icons.star, 'Signifies', planet.significance, planet.color, isDark)]),
              ),
              Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 20), child: SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: planet.color, foregroundColor: planet.name == 'Moon' || planet.name == 'Venus' ? Colors.black87 : Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold))))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanetDetailRow(IconData icon, String label, String value, Color color, bool isDark) {
    return Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 20)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: TextStyle(fontSize: 11, color: (isDark ? Colors.white : Colors.black).withOpacity(0.6))), Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87))]))]);
  }

  void _showHoraInfoDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: isDark ? [const Color(0xFF0D1A10), const Color(0xFF070C08)] : [Colors.white, const Color(0xFFFFFBEB)]), borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: const Color(0xFFFFD700).withOpacity(0.3), blurRadius: 30, spreadRadius: 5)]),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFF59E0B)]), borderRadius: const BorderRadius.vertical(top: Radius.circular(24))), child: Row(children: [const Text('⏰', style: TextStyle(fontSize: 32)), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('What is Hora?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)), Text('Planetary hours in Vedic astrology', style: TextStyle(fontSize: 13, color: Colors.black.withOpacity(0.7)))])), IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.black54))])),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Hora divides each day into 24 planetary hours, with each hour ruled by one of the seven Vedic planets. The first hora of the day is ruled by the planet that rules that day.', style: TextStyle(fontSize: 14, height: 1.5, color: isDark ? Colors.white70 : Colors.black54)), const SizedBox(height: 20), Text('Best Activities by Planet:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)), const SizedBox(height: 12), _buildHoraActivityItem('☉ Sun', 'Government work, authority', const Color(0xFFFF6B00), isDark), _buildHoraActivityItem('☽ Moon', 'Creative work, travel', const Color(0xFFB8C6DB), isDark), _buildHoraActivityItem('♂ Mars', 'Property, machinery', const Color(0xFFDC143C), isDark), _buildHoraActivityItem('☿ Mercury', 'Business, studies', const Color(0xFF228B22), isDark), _buildHoraActivityItem('♃ Jupiter', 'Religious, education', const Color(0xFFFFD700), isDark), _buildHoraActivityItem('♀ Venus', 'Love, arts, luxury', const Color(0xFFFFB6C1), isDark), _buildHoraActivityItem('♄ Saturn', 'Agriculture, real estate', const Color(0xFF191970), isDark)]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHoraActivityItem(String planet, String activities, Color color, bool isDark) {
    return Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: 32, height: 32, decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.2), border: Border.all(color: color, width: 1.5)), child: Center(child: Text(planet.split(' ')[0], style: TextStyle(fontSize: 14, color: color)))), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(planet.split(' ')[1], style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)), Text(activities, style: TextStyle(fontSize: 12, color: (isDark ? Colors.white : Colors.black).withOpacity(0.6)))]))]));
  }

  void _showChoghadiyaInfoDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: isDark ? [const Color(0xFF1A2E1A), const Color(0xFF070C08)] : [Colors.white, const Color(0xFFF0FFF4)]), borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: const Color(0xFF10B981).withOpacity(0.3), blurRadius: 30, spreadRadius: 5)]),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]), borderRadius: const BorderRadius.vertical(top: Radius.circular(24))), child: Row(children: [const Text('🕐', style: TextStyle(fontSize: 32)), const SizedBox(width: 16), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('What is Choghadiya?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)), Text('Quick muhurat selection', style: TextStyle(fontSize: 13, color: Colors.white70))])), IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white70))])),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Choghadiya divides day and night into 8 periods each, totaling 16 muhurats. It\'s a quick way to check auspicious times.', style: TextStyle(fontSize: 14, height: 1.5, color: isDark ? Colors.white70 : Colors.black54)), const SizedBox(height: 20), Text('Types of Choghadiya:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)), const SizedBox(height: 12), _buildChoghadiyaTypeItem('🍯 Amrit', 'Best for all activities', const Color(0xFF10B981), true, isDark), _buildChoghadiyaTypeItem('✨ Shubh', 'Auspicious for most work', const Color(0xFF059669), true, isDark), _buildChoghadiyaTypeItem('💰 Labh', 'Profitable, good for business', const Color(0xFF14B8A6), true, isDark), _buildChoghadiyaTypeItem('🚶 Char', 'Good for travel', const Color(0xFF0EA5E9), true, isDark), _buildChoghadiyaTypeItem('🤒 Rog', 'Inauspicious', const Color(0xFFEF4444), false, isDark), _buildChoghadiyaTypeItem('⚫ Kaal', 'Very inauspicious', const Color(0xFF6B7280), false, isDark), _buildChoghadiyaTypeItem('😰 Udveg', 'Causes anxiety', const Color(0xFFF97316), false, isDark)]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChoghadiyaTypeItem(String name, String desc, Color color, bool isGood, bool isDark) {
    return Padding(padding: const EdgeInsets.only(bottom: 10), child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(isDark ? 0.15 : 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.3))), child: Row(children: [Text(name.split(' ')[0], style: const TextStyle(fontSize: 20)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Text(name.split(' ')[1], style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)), const SizedBox(width: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: isGood ? Colors.green : Colors.red, borderRadius: BorderRadius.circular(6)), child: Text(isGood ? '✓' : '✗', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)))]), Text(desc, style: TextStyle(fontSize: 12, color: (isDark ? Colors.white : Colors.black).withOpacity(0.6)))]))])));
  }
}

class _PlanetData {
  final String name, sanskrit, symbol, emoji, deity, day, nature, significance;
  final Color color;
  final List<Color> gradientColors;
  const _PlanetData({required this.name, required this.sanskrit, required this.symbol, required this.emoji, required this.color, required this.gradientColors, required this.deity, required this.day, required this.nature, required this.significance});
}

class _ChoghadiyaData {
  final String name, emoji, description;
  final Color color;
  final bool isAuspicious;
  const _ChoghadiyaData(this.name, this.emoji, this.color, this.isAuspicious, this.description);
}
