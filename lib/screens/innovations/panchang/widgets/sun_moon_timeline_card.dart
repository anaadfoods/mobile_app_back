import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:grocery_app/models/panchang/panchang_day_models.dart';

class SunMoonTimelineCard extends StatefulWidget {
  final PanchangSunMoonTimings timings;
  final bool isDark;

  const SunMoonTimelineCard({
    super.key,
    required this.timings,
    required this.isDark,
  });

  @override
  State<SunMoonTimelineCard> createState() => _SunMoonTimelineCardState();
}

class _SunMoonTimelineCardState extends State<SunMoonTimelineCard>
    with TickerProviderStateMixin {
  late final AnimationController _floatingController;
  late final AnimationController _shimmerController;
  late final Animation<double> _floatingAnimation;
  late final Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    // Floating animation
    _floatingController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _floatingAnimation = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );

    // Shimmer/glow animation
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);

    _shimmerAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatingController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  String _formatTime(dynamic time) {
    if (time is String) {
      try {
        final parts = time.split(':');
        if (parts.length >= 2) {
          final hour = int.parse(parts[0]);
          final minute = int.parse(parts[1]);
          final period = hour >= 12 ? 'PM' : 'AM';
          final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
          return '$hour12:${minute.toString().padLeft(2, '0')} $period';
        }
      } catch (_) {
        return time;
      }
      return time;
    }
    if (time is DateTime) {
      final indianTime = time.toLocal();
      final hour = indianTime.hour;
      final minute = indianTime.minute;
      final period = hour >= 12 ? 'PM' : 'AM';
      final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      return '$hour12:${minute.toString().padLeft(2, '0')} $period';
    }
    return '--:--';
  }

  @override
  Widget build(BuildContext context) {
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
                        color: const Color(0xFFFFD700).withValues(
                          alpha: 0.45 * _shimmerAnimation.value,
                        ),
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
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Color(0xFFE8760A), // saffron sunrise
                AppColors.deepSoilGreen, // forest green transition
                Color(0xFF0D1B2A), // deep night sunset side
              ],
              stops: [0.0, 0.48, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Sun radial glow (left)
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
              // Moon soft halo (right)
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
              // Stars (right half)
              Positioned(top: 10, right: 28, child: _buildStarDot(3.0, 0.90)),
              Positioned(top: 22, right: 62, child: _buildStarDot(1.8, 0.60)),
              Positioned(top: 6, right: 90, child: _buildStarDot(1.5, 0.50)),
              Positioned(top: 42, right: 48, child: _buildStarDot(2.2, 0.75)),
              Positioned(top: 18, right: 115, child: _buildStarDot(1.2, 0.40)),
              Positioned(bottom: 18, right: 32, child: _buildStarDot(2.5, 0.85)),
              Positioned(bottom: 30, right: 70, child: _buildStarDot(1.5, 0.55)),
              Positioned(bottom: 10, right: 95, child: _buildStarDot(1.0, 0.40)),
              Positioned(top: 35, right: 20, child: _buildStarDot(1.2, 0.45)),
              // Content
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
                          time: _formatTime(widget.timings.sunrise),
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
                            const AutoSizeText(
                              '☀️🌙',
                              style: TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                        _buildTimeItem(
                          icon: Icons.nightlight_round,
                          label: 'Sunset',
                          time: _formatTime(widget.timings.sunset),
                        ),
                      ],
                    ),
                    if (widget.timings.solarNoon != null) ...[
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
                              color: widget.isDark
                                  ? AppColors.pureWhite
                                  : AppColors.parchment,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            AutoSizeText(
                              'Solar Noon: ${_formatTime(widget.timings.solarNoon)}',
                              style: TextStyle(
                                color: widget.isDark
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
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.pureWhite
                : AppColors.parchment,
            size: 32,
          ),
          const SizedBox(height: 8),
          AutoSizeText(
            label,
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
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
              color: Theme.of(context).brightness == Brightness.dark
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
}
