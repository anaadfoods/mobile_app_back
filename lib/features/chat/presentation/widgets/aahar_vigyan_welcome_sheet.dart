import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:grocery_app/core/theme/app_colors.dart';
import 'package:grocery_app/services/content_config_service.dart';
import 'package:grocery_app/services/token_service.dart';
import 'package:grocery_app/service_locator.dart';

/// Aahar Vigyan Welcome Sheet — Design System v2.0
///
/// Introduces the 3 pillars of personalized food intelligence:
/// 1. Ayurveda (Prakriti Assessment)
/// 2. Panchang (Daily Cosmic Elements)
/// 3. Jyotish (Planetary Food Affinities)
class AaharVigyanWelcomeSheet extends StatefulWidget {
  final VoidCallback? onDismiss;
  final VoidCallback? onStartJourney;

  const AaharVigyanWelcomeSheet({
    super.key,
    this.onDismiss,
    this.onStartJourney,
  });

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => const AaharVigyanWelcomeSheet(),
    );
  }

  @override
  State<AaharVigyanWelcomeSheet> createState() => _AaharVigyanWelcomeSheetState();
}

class _AaharVigyanWelcomeSheetState extends State<AaharVigyanWelcomeSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  Map<String, String> _contentMap = {};

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 45),
      vsync: this,
    )..repeat();
    _loadContent();
  }

  Future<void> _loadContent() async {
    try {
      final token = await getIt<TokenService>().getAccessToken();
      if (token == null) return;
      final blocks = await ContentConfigService()
          .fetchContentBlocks(token: token, screen: 'onboarding');
      if (blocks.isNotEmpty && mounted) {
        final map = <String, String>{};
        for (final b in blocks) {
          final key = b['block_key'] as String?;
          final content = b['content_en'] as String?;
          if (key != null && content != null) {
            map[key] = content;
          }
        }
        setState(() => _contentMap = map);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'GOOD MORNING';
    if (hour < 17) return 'GOOD AFTERNOON';
    return 'GOOD EVENING';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.90,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.warmWhite,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 32,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : AppColors.charcoal)
                    .withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Scrollable Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ── Hero Header with Animated Mandala Background ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.forest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Subtle rotating mandala overlay
                        Positioned(
                          right: -30,
                          top: -30,
                          child: AnimatedBuilder(
                            animation: _rotationController,
                            builder: (context, child) {
                              return Transform.rotate(
                                angle: _rotationController.value * 2 * math.pi,
                                child: Opacity(
                                  opacity: 0.10,
                                  child: CustomPaint(
                                    size: const Size(160, 160),
                                    painter: _MandalaPainter(),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        Column(
                          children: [
                            // Time-based Eyebrow
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                _getTimeGreeting(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.2,
                                  color: AppColors.goldLight,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Headline
                            Text(
                              _contentMap['headline'] ?? 'Welcome to\nAahar Vigyan.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Georgia',
                                fontSize: 26,
                                fontWeight: FontWeight.w600,
                                height: 1.15,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Subtitle
                            Text(
                              _contentMap['subtitle'] ?? 'Your personalised food intelligence — built from your body, your stars, and today\'s cosmic rhythm.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.45,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── 3 Journey Pillar Cards ──
                  _buildPillarCard(
                    isDark: isDark,
                    badgeText: _contentMap['pillar_1_subtitle'] ?? 'Step 1',
                    badgeColor: const Color(0xFFEEF5E8),
                    badgeTextColor: AppColors.forest,
                    iconBg: const Color(0xFFEEF5E8),
                    icon: Icons.spa_rounded,
                    iconColor: AppColors.forest,
                    title: _contentMap['pillar_1_title'] ?? 'Ayurveda',
                    titleColor: AppColors.forest,
                    description: _contentMap['pillar_1_description'] ??
                        'A 7-question body type test reveals your Prakriti — your constitutional blueprint since birth. This shapes your food forever.',
                  ),
                  const SizedBox(height: 12),

                  _buildPillarCard(
                    isDark: isDark,
                    badgeText: _contentMap['pillar_2_subtitle'] ?? 'Daily',
                    badgeColor: const Color(0xFFFFF8E8),
                    badgeTextColor: const Color(0xFF8A6010),
                    iconBg: const Color(0xFFFFF8E8),
                    icon: Icons.wb_sunny_rounded,
                    iconColor: AppColors.gold,
                    title: _contentMap['pillar_2_title'] ?? 'Panchang',
                    titleColor: isDark ? AppColors.goldLight : const Color(0xFF8A6010),
                    description: _contentMap['pillar_2_description'] ??
                        'Every morning the five cosmic elements of today\'s Panchang shape what your body needs. Your guide updates daily.',
                  ),
                  const SizedBox(height: 12),

                  _buildPillarCard(
                    isDark: isDark,
                    badgeText: _contentMap['pillar_3_subtitle'] ?? 'Step 2',
                    badgeColor: const Color(0xFFEEEAF8),
                    badgeTextColor: AppColors.jyotish,
                    iconBg: const Color(0xFFEEEAF8),
                    icon: Icons.auto_awesome_rounded,
                    iconColor: AppColors.jyotish,
                    title: _contentMap['pillar_3_title'] ?? 'Jyotish',
                    titleColor: isDark ? const Color(0xFF9E9ED4) : AppColors.jyotish,
                    description: _contentMap['pillar_3_description'] ??
                        'Your birth chart reveals your planetary food affinities — which foods align with your cosmic constitution.',
                  ),

                  const SizedBox(height: 20),

                  // Meta Info
                  Text(
                    _contentMap['duration_text'] ?? 'Takes about 7 minutes · Free to start',
                    style: TextStyle(
                      fontSize: 12,
                      color: (isDark ? Colors.white : AppColors.charcoal)
                          .withValues(alpha: 0.6),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── Actions ──
                  // Primary CTA
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        if (widget.onStartJourney != null) {
                          widget.onStartJourney!();
                        } else {
                          context.push('/prakriti-quiz');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.forest,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _contentMap['cta_primary'] ?? 'Start My Journey →',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Secondary Action (Dismiss / Direct to Chat)
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onDismiss?.call();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: (isDark ? Colors.white : AppColors.charcoal)
                          .withValues(alpha: 0.6),
                    ),
                    child: Text(
                      _contentMap['cta_secondary'] ?? 'Continue to Chat First',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
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

  Widget _buildPillarCard({
    required bool isDark,
    required String badgeText,
    required Color badgeColor,
    required Color badgeTextColor,
    required Color iconBg,
    required IconData icon,
    required Color iconColor,
    required String title,
    required Color titleColor,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isDark ? Colors.white : AppColors.charcoal).withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pillar Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? iconColor.withValues(alpha: 0.15) : iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),

          // Pillar Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? badgeTextColor.withValues(alpha: 0.15)
                            : badgeColor,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: badgeTextColor.withValues(alpha: 0.25),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: badgeTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    color: (isDark ? Colors.white : AppColors.charcoal)
                        .withValues(alpha: 0.70),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for sacred geometry mandala
class _MandalaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(center, size.width * 0.45, paint);
    canvas.drawCircle(center, size.width * 0.30, paint);

    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);
      canvas.drawOval(
        Rect.fromCenter(
          center: const Offset(0, -30),
          width: 25,
          height: 60,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
