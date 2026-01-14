import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../cubits/panchang/panchang_guidance_cubit.dart';
import '../../../cubits/panchang/panchang_guidance_state.dart';
import '../../../models/panchang/panchang_guidance_models.dart';
import '../../../repositories/panchang_repository.dart';
import 'panchang_guidance_profile_screen.dart';

/// Today's Guidance Screen
/// Shows personalized recommendations based on Panchang data
class PanchangGuidanceScreen extends StatefulWidget {
  const PanchangGuidanceScreen({super.key});

  @override
  State<PanchangGuidanceScreen> createState() => _PanchangGuidanceScreenState();
}

class _PanchangGuidanceScreenState extends State<PanchangGuidanceScreen>
    with SingleTickerProviderStateMixin {
  late final PanchangGuidanceCubit _cubit;
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _cubit = PanchangGuidanceCubit(repository: PanchangRepository());
    _animController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _animController.forward();
    _cubit.loadTodayGuidance();
  }

  @override
  void dispose() {
    _animController.dispose();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F0F23) : const Color(0xFFF5F5F5),
        body: BlocBuilder<PanchangGuidanceCubit, PanchangGuidanceState>(
          builder: (context, state) {
            if (state is PanchangGuidanceLoading) {
              return _buildLoadingState(isDark);
            }

            if (state is PanchangGuidanceError) {
              return _buildErrorState(state.message, isDark);
            }

            if (state is PanchangGuidanceSuccess) {
              return _buildSuccessState(state.guidance, isDark);
            }

            return _buildLoadingState(isDark);
          },
        ),
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
                colors: [Colors.blue.shade400, Colors.purple.shade400],
              ),
            ),
            child: const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading Today\'s Guidance...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to load guidance',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _cubit.loadTodayGuidance(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessState(GuidanceTodayResponse guidance, bool isDark) {
    return CustomScrollView(
      slivers: [
        _buildAppBar(guidance, isDark),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Source Info Card
                    _buildSourceCard(guidance.source, isDark),
                    const SizedBox(height: 20),
                    // Recommendations
                    ...guidance.recommendations.asMap().entries.map((entry) {
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: entry.key < guidance.recommendations.length - 1 ? 16 : 0,
                        ),
                        child: _buildRecommendationCard(entry.value, isDark, entry.key),
                      );
                    }),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar(GuidanceTodayResponse guidance, bool isDark) {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_rounded,
          color: isDark ? Colors.white : Colors.black87,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.settings_rounded,
            color: isDark ? Colors.white : Colors.black87,
          ),
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: _cubit,
                  child: const PanchangGuidanceProfileScreen(),
                ),
              ),
            );
            // Reload guidance after returning from settings
            _cubit.loadTodayGuidance();
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today\'s Guidance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            Text(
              DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
              style: TextStyle(
                fontSize: 11,
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.6),
              ),
            ),
          ],
        ),
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                  : [Colors.white, const Color(0xFFF0F4FF)],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSourceCard(GuidanceSource source, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF2D2D5A), const Color(0xFF1A1A3E)]
              : [const Color(0xFFE8EAFF), const Color(0xFFF5F6FF)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.blue.shade400),
                    const SizedBox(width: 8),
                    Text(
                      source.tithi,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.wb_sunny_outlined, size: 16, color: Colors.orange.shade400),
                    const SizedBox(width: 8),
                    Text(
                      source.vara,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🌅', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      source.formattedSunrise,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🌇', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      source.formattedSunset,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(GuidanceRecommendation rec, bool isDark, int index) {
    final verdictData = _getVerdictData(rec.verdict);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: verdictData.color.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: verdictData.color.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    verdictData.color.withOpacity(isDark ? 0.2 : 0.1),
                    verdictData.color.withOpacity(isDark ? 0.1 : 0.05),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: verdictData.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getTypeEmoji(rec.type),
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rec.title,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: verdictData.color,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            verdictData.label,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recommended Windows
                  if (rec.recommendedWindows.isNotEmpty) ...[
                    _buildWindowsSection(
                      title: '✅ Recommended Times',
                      windows: rec.recommendedWindows,
                      color: Colors.green,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                  ],
                  // Avoid Windows
                  if (rec.avoidWindows.isNotEmpty) ...[
                    _buildWindowsSection(
                      title: '⛔ Avoid These Times',
                      windows: rec.avoidWindows,
                      color: Colors.red,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                  ],
                  // Notes
                  if (rec.notesList.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(isDark ? 0.15 : 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.amber.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('💡', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              rec.notesList.join('\n'),
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.4,
                                color: isDark ? Colors.amber.shade200 : Colors.amber.shade800,
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
    );
  }

  Widget _buildWindowsSection({
    required String title,
    required List<GuidanceTimeWindow> windows,
    required Color color,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        ...windows.map((window) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildTimeWindowItem(window, color, isDark),
            )),
      ],
    );
  }

  Widget _buildTimeWindowItem(GuidanceTimeWindow window, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: window.isCurrent
            ? color.withOpacity(isDark ? 0.25 : 0.15)
            : color.withOpacity(isDark ? 0.1 : 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: window.isCurrent ? color : color.withOpacity(0.2),
          width: window.isCurrent ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        window.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    if (window.isCurrent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'NOW',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Text(
            window.formattedTimeRange,
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

  _VerdictData _getVerdictData(String verdict) {
    switch (verdict.toLowerCase()) {
      case 'best':
        return _VerdictData('BEST', Colors.green.shade600);
      case 'good':
        return _VerdictData('GOOD', Colors.teal.shade500);
      case 'recommended':
        return _VerdictData('RECOMMENDED', Colors.blue.shade500);
      case 'ok_with_caution':
        return _VerdictData('OK WITH CAUTION', Colors.orange.shade600);
      case 'optional':
        return _VerdictData('OPTIONAL', Colors.purple.shade400);
      case 'none':
        return _VerdictData('NOT APPLICABLE', Colors.grey.shade500);
      default:
        return _VerdictData(verdict.toUpperCase(), Colors.grey.shade500);
    }
  }

  String _getTypeEmoji(String type) {
    switch (type.toLowerCase()) {
      case 'work':
        return '💼';
      case 'travel':
        return '✈️';
      case 'fasting':
        return '🙏';
      case 'meditation':
        return '🧘';
      case 'study':
        return '📚';
      case 'finance':
        return '💰';
      case 'health':
        return '❤️';
      default:
        return '✨';
    }
  }
}

class _VerdictData {
  final String label;
  final Color color;

  _VerdictData(this.label, this.color);
}

