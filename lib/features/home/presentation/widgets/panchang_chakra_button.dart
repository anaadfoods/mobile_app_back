import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'solar_popup_content.dart';

class PanchangChakraButton extends StatefulWidget {
  final ThemeData theme;
  final VoidCallback onTap;
  const PanchangChakraButton({super.key, required this.theme, required this.onTap});

  @override
  State<PanchangChakraButton> createState() => _PanchangChakraButtonState();
}

class _PanchangChakraButtonState extends State<PanchangChakraButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ticker;
  late final Stopwatch _sw;

  @override
  void initState() {
    super.initState();
    _sw = Stopwatch()..start();
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..repeat();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _showSolarSystemPopup(BuildContext context) {
    HapticFeedback.heavyImpact();
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Solar System',
      barrierColor: Colors.black.withValues(alpha: 0.75),
      transitionDuration: const Duration(milliseconds: 550),
      pageBuilder: (ctx, _, __) => const SolarPopupContent(),
      transitionBuilder: (ctx, animation, secondaryAnimation, child) {
        final scale = Tween<double>(begin: 0.4, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
        );
        final opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
          ),
        );
        return FadeTransition(
          opacity: opacity,
          child: ScaleTransition(scale: scale, child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      onLongPress: () => _showSolarSystemPopup(context),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: widget.theme.colorScheme.onPrimary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: widget.theme.colorScheme.onPrimary.withValues(
                  alpha: 0.1,
                ),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFCA28).withValues(alpha: 0.22),
                  blurRadius: 16,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: AnimatedBuilder(
              animation: _ticker,
              builder: (context, _) {
                final t = _sw.elapsed.inMilliseconds / 1000.0;
                return CustomPaint(
                  size: const Size(24, 24),
                  painter: MiniSolarPainter(t: t),
                );
              },
            ),
          ),
          Positioned(
            bottom: -13,
            child: AnimatedBuilder(
              animation: _ticker,
              builder: (context, _) {
                final t = _sw.elapsed.inMilliseconds / 1000.0;
                final pulse = 0.35 + 0.35 * math.sin(t * 1.1).abs();
                return Text(
                  'hold',
                  style: TextStyle(
                    color: const Color(0xFFFFCA28).withOpacity(pulse),
                    fontSize: 7,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 1.5,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

const _miniPlanets = [
  [0.22, 4.8, 0.70, 0xFFA8A8A8],
  [0.40, 10.0, 2.40, 0xFFE8C060],
  [0.60, 20.0, 4.90, 0xFF42A5F5],
  [0.82, 38.0, 1.10, 0xFFEF5350],
];

class MiniSolarPainter extends CustomPainter {
  final double t;
  const MiniSolarPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final max = cx * 0.96;

    canvas.drawCircle(
      Offset(cx, cy),
      max,
      Paint()
        ..shader = RadialGradient(
          colors: const [Color(0xFF0D1B2A), Color(0xFF030810)],
          radius: 1.0,
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: max)),
    );

    for (final p in _miniPlanets) {
      final orbitR = (p[0] as double) * max;
      canvas.drawCircle(
        Offset(cx, cy),
        orbitR,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.12)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.35,
      );
    }

    final sunR = max * 0.18;
    canvas.drawCircle(
      Offset(cx, cy),
      sunR * 2.0,
      Paint()
        ..color = const Color(0xFFFFCA28).withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(
      Offset(cx, cy),
      sunR,
      Paint()
        ..shader = RadialGradient(
          colors: const [
            Color(0xFFFFFDE7),
            Color(0xFFFFCA28),
            Color(0xFFFF8F00),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: sunR)),
    );

    for (final p in _miniPlanets) {
      final orbitR = (p[0] as double) * max;
      final period = p[1] as double;
      final start = p[2] as double;
      final color = Color(p[3] as int);
      final pr = 0.9 + orbitR * 0.055;

      final angle = (t / period) * 2 * math.pi + start;
      final px = cx + orbitR * math.cos(angle);
      final py = cy + orbitR * math.sin(angle);

      canvas.drawCircle(
        Offset(px, py),
        pr * 2.2,
        Paint()
          ..color = color.withValues(alpha: 0.28)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
      canvas.drawCircle(Offset(px, py), pr, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(MiniSolarPainter old) => old.t != t;
}
