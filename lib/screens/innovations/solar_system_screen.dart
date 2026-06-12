import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grocery_app/core/theme/app_colors.dart';
import 'package:grocery_app/common_widgets/anaad_logo_mark.dart';

// ═══════════════════════════════════════════════════════════════
//  3D perspective constants
// ═══════════════════════════════════════════════════════════════
const double _tiltFactor = 0.38; // Y-axis squeeze (0 = edge-on, 1 = top-down)
const double _depthScale = 0.28; // how much z affects apparent size
const double _depthBright = 0.25; // how much z affects brightness

// ═══════════════════════════════════════════════════════════════
//  Planet Data
// ═══════════════════════════════════════════════════════════════
class _PlanetData {
  final String name;
  final Color color;
  final Color colorDark;
  final double visualRadius;
  final double orbitFraction;
  final double periodSeconds;
  final double startAngle;
  final bool hasRings;
  final List<_Band>? bands;
  final Color? atmosphere;

  const _PlanetData({
    required this.name,
    required this.color,
    required this.colorDark,
    required this.visualRadius,
    required this.orbitFraction,
    required this.periodSeconds,
    required this.startAngle,
    this.hasRings = false,
    this.bands,
    this.atmosphere,
  });
}

class _Band {
  final Color color;
  final double yOffset;
  final double height;
  const _Band(this.color, this.yOffset, this.height);
}

const _planets = <_PlanetData>[
  _PlanetData(
    name: 'Mercury',
    color: AppColors.parchment,
    colorDark: AppColors.parchment,
    visualRadius: 4.0,
    orbitFraction: 0.092,
    periodSeconds: 4.8,
    startAngle: 0.7,
  ),
  _PlanetData(
    name: 'Venus',
    color: AppColors.parchment,
    colorDark: AppColors.parchment,
    visualRadius: 6.2,
    orbitFraction: 0.138,
    periodSeconds: 7.8,
    startAngle: 2.4,
    atmosphere: AppColors.parchment,
  ),
  _PlanetData(
    name: 'Earth',
    color: AppColors.parchment,
    colorDark: AppColors.parchment,
    visualRadius: 6.8,
    orbitFraction: 0.195,
    periodSeconds: 12.0,
    startAngle: 4.9,
    atmosphere: AppColors.parchment,
  ),
  _PlanetData(
    name: 'Mars',
    color: AppColors.parchment,
    colorDark: AppColors.parchment,
    visualRadius: 5.0,
    orbitFraction: 0.255,
    periodSeconds: 20.0,
    startAngle: 1.1,
    atmosphere: AppColors.parchment,
  ),
  _PlanetData(
    name: 'Jupiter',
    color: AppColors.parchment,
    colorDark: AppColors.parchment,
    visualRadius: 14.0,
    orbitFraction: 0.430,
    periodSeconds: 36.0,
    startAngle: 3.5,
    bands: [
      _Band(AppColors.parchment, -0.35, 0.20),
      _Band(AppColors.parchment, 0.0, 0.15),
      _Band(AppColors.parchment, 0.30, 0.22),
      _Band(AppColors.parchment, -0.60, 0.12),
    ],
  ),
  _PlanetData(
    name: 'Saturn',
    color: AppColors.parchment,
    colorDark: AppColors.parchment,
    visualRadius: 11.5,
    orbitFraction: 0.575,
    periodSeconds: 58.0,
    startAngle: 5.6,
    hasRings: true,
  ),
  _PlanetData(
    name: 'Uranus',
    color: AppColors.parchment,
    colorDark: AppColors.parchment,
    visualRadius: 8.5,
    orbitFraction: 0.760,
    periodSeconds: 82.0,
    startAngle: 0.2,
    atmosphere: AppColors.parchment,
  ),
  _PlanetData(
    name: 'Neptune',
    color: AppColors.parchment,
    colorDark: AppColors.parchment,
    visualRadius: 7.8,
    orbitFraction: 0.950,
    periodSeconds: 118.0,
    startAngle: 2.8,
    atmosphere: AppColors.parchment,
  ),
];

// ═══════════════════════════════════════════════════════════════
//  Computed planet position (for z-sorting)
// ═══════════════════════════════════════════════════════════════
class _PlanetPos {
  final int index;
  final Offset screenPos;
  final double z;
  final double angle;
  final double scale;
  final double brightness;
  const _PlanetPos(
    this.index,
    this.screenPos,
    this.z,
    this.angle,
    this.scale,
    this.brightness,
  );
}

// ═══════════════════════════════════════════════════════════════
//  Screen
// ═══════════════════════════════════════════════════════════════
class SolarSystemScreen extends StatefulWidget {
  const SolarSystemScreen({super.key});

  @override
  State<SolarSystemScreen> createState() => _SolarSystemScreenState();
}

class _SolarSystemScreenState extends State<SolarSystemScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Stopwatch _stopwatch;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    _stopwatch = Stopwatch()..start();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.charcoal,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: AppColors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.parchment60),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'SOLAR SYSTEM',
          style: TextStyle(
            color: AppColors.parchment60,
            fontWeight: FontWeight.w200,
            fontSize: 13,
            letterSpacing: 6,
          ),
        ),
        centerTitle: true,
      ),
      body: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _stopwatch.elapsed.inMilliseconds / 1000.0;
            return CustomPaint(
              painter: _SolarSystemPainter(t: t),
              child: const SizedBox.expand(),
            );
          },
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Painter — 3D perspective, focused on solar system
// ═══════════════════════════════════════════════════════════════
class _SolarSystemPainter extends CustomPainter {
  final double t;
  const _SolarSystemPainter({required this.t});

  _PlanetPos _project(int idx, Offset center, double maxOrbit) {
    final p = _planets[idx];
    final orbitR = p.orbitFraction * maxOrbit;
    final angle = (t / p.periodSeconds) * 2 * math.pi + p.startAngle;
    final x3d = orbitR * math.cos(angle);
    final z3d = orbitR * math.sin(angle);
    final sx = center.dx + x3d;
    final sy = center.dy + z3d * _tiltFactor;
    final zNorm = math.sin(angle);
    final scale = 1.0 + zNorm * _depthScale;
    final brightness = 1.0 + zNorm * _depthBright;
    return _PlanetPos(idx, Offset(sx, sy), zNorm, angle, scale, brightness);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final center = Offset(cx, cy);
    final maxOrbit = math.min(cx * 0.95, cy * 0.92);

    _drawBackground(canvas, size, center, maxOrbit);
    _drawOrbitalPlaneGrid(canvas, center, maxOrbit);
    _drawOrbits(canvas, center, maxOrbit);
    _drawAsteroidBelt(canvas, center, maxOrbit);

    final positions = <_PlanetPos>[];
    for (int i = 0; i < _planets.length; i++) {
      positions.add(_project(i, center, maxOrbit));
    }
    positions.sort((a, b) => a.z.compareTo(b.z));

    final sunR = maxOrbit * 0.055;
    final behindPlanets = positions.where((p) => p.z < -0.05).toList();
    final frontPlanets = positions.where((p) => p.z >= -0.05).toList();

    for (final pp in behindPlanets) {
      _drawOrbitTrail(canvas, center, _planets[pp.index], pp, maxOrbit);
      _drawFullPlanet(canvas, pp, center, sunR);
    }
    _drawSun(canvas, center, sunR);
    for (final pp in frontPlanets) {
      _drawOrbitTrail(canvas, center, _planets[pp.index], pp, maxOrbit);
      _drawFullPlanet(canvas, pp, center, sunR);
    }

    _drawMoon(canvas, center, maxOrbit);
  }

  void _drawBackground(
    Canvas canvas,
    Size size,
    Offset center,
    double maxOrbit,
  ) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ui.Gradient.radial(
          center,
          maxOrbit * 1.2,
          const [
            AppColors.parchment,
            AppColors.parchment,
            AppColors.parchment,
            AppColors.parchment,
          ],
          const [0.0, 0.35, 0.65, 1.0],
        ),
    );
    canvas.drawCircle(
      center,
      maxOrbit * 0.45,
      Paint()
        ..color = AppColors.parchment.withValues(alpha: 0.020)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, maxOrbit * 0.35),
    );
  }

  void _drawOrbitalPlaneGrid(Canvas canvas, Offset center, double maxOrbit) {
    final gridPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.3;
    for (int i = 1; i <= 14; i++) {
      final r = maxOrbit * (i / 14.0) * 1.05;
      final opacity = (0.025 * (1.0 - i / 16.0)).clamp(0.0, 1.0);
      gridPaint.color = AppColors.parchment.withValues(alpha: opacity);
      canvas.drawOval(
        Rect.fromCenter(
          center: center,
          width: r * 2,
          height: r * 2 * _tiltFactor,
        ),
        gridPaint,
      );
    }
    final radialPaint =
        Paint()
          ..color = AppColors.parchment.withValues(alpha: 0.012)
          ..strokeWidth = 0.4;
    for (int i = 0; i < 12; i++) {
      final angle = i * math.pi / 6;
      final far = maxOrbit * 1.05;
      canvas.drawLine(
        center,
        Offset(
          center.dx + far * math.cos(angle),
          center.dy + far * math.sin(angle) * _tiltFactor,
        ),
        radialPaint,
      );
    }
  }

  void _drawOrbits(Canvas canvas, Offset center, double maxOrbit) {
    for (final p in _planets) {
      final r = p.orbitFraction * maxOrbit;
      final rect = Rect.fromCenter(
        center: center,
        width: r * 2,
        height: r * 2 * _tiltFactor,
      );
      canvas.drawOval(
        rect,
        Paint()
          ..color = AppColors.parchment.withValues(alpha: 0.05)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.7,
      );
      canvas.drawOval(
        rect,
        Paint()
          ..color = AppColors.parchment.withValues(alpha: 0.025)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }
  }

  void _drawOrbitTrail(
    Canvas canvas,
    Offset center,
    _PlanetData p,
    _PlanetPos pp,
    double maxOrbit,
  ) {
    final r = p.orbitFraction * maxOrbit;
    const sweep = 0.50;
    final rect = Rect.fromCenter(
      center: center,
      width: r * 2,
      height: r * 2 * _tiltFactor,
    );
    canvas.drawArc(
      rect,
      pp.angle - sweep,
      sweep,
      false,
      Paint()
        ..color = p.color.withValues(
          alpha: 0.10 * pp.brightness.clamp(0.5, 1.5),
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0 * pp.scale
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawArc(
      rect,
      pp.angle - sweep * 0.5,
      sweep * 0.5,
      false,
      Paint()
        ..color = p.color.withValues(
          alpha: 0.20 * pp.brightness.clamp(0.5, 1.5),
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0 * pp.scale
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawSun(Canvas canvas, Offset c, double r) {
    final pulse = 1.0 + 0.03 * math.sin(t * 2.2);
    final pulse2 = 1.0 + 0.05 * math.sin(t * 1.4 + 1.0);

    canvas.drawCircle(
      c,
      r * 6.0 * pulse2,
      Paint()
        ..color = AppColors.parchment.withValues(alpha: 0.010)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 3),
    );

    for (int i = 0; i < 8; i++) {
      final rayAngle = i * math.pi / 4 + t * 0.05;
      final rayLen = r * (3.5 + 0.8 * math.sin(t * 1.8 + i));
      final dx = math.cos(rayAngle);
      final dy = math.sin(rayAngle);
      canvas.drawLine(
        Offset(c.dx + r * 0.6 * dx, c.dy + r * 0.6 * dy),
        Offset(c.dx + rayLen * dx, c.dy + rayLen * dy),
        Paint()
          ..color = AppColors.parchment.withValues(alpha: 0.04)
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }

    for (int i = 6; i >= 1; i--) {
      canvas.drawCircle(
        c,
        r * (1.0 + i * 0.45) * pulse,
        Paint()
          ..color = AppColors.parchment.withValues(alpha: 0.022 * i)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10.0 + i * 5),
      );
    }

    canvas.drawCircle(
      c,
      r * 1.5,
      Paint()
        ..color = AppColors.parchment.withValues(alpha: 0.24)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = ui.Gradient.radial(
          c,
          r,
          const [
            AppColors.parchment,
            AppColors.parchment,
            AppColors.parchment,
            AppColors.parchment,
            AppColors.parchment,
          ],
          const [0.0, 0.20, 0.50, 0.78, 1.0],
        ),
    );

    final spotA = t * 0.3;
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: c, radius: r)));
    canvas.drawCircle(
      Offset(
        c.dx + r * 0.35 * math.cos(spotA),
        c.dy + r * 0.18 * math.sin(spotA),
      ),
      r * 0.11,
      Paint()..color = AppColors.parchment.withValues(alpha: 0.30),
    );
    canvas.drawCircle(
      Offset(
        c.dx + r * 0.2 * math.cos(spotA + 2.2),
        c.dy + r * 0.30 * math.sin(spotA + 1.0),
      ),
      r * 0.07,
      Paint()..color = AppColors.parchment.withValues(alpha: 0.22),
    );
    canvas.restore();
  }

  void _drawFullPlanet(
    Canvas canvas,
    _PlanetPos pp,
    Offset sunCenter,
    double sunR,
  ) {
    final p = _planets[pp.index];
    final r = p.visualRadius * pp.scale;
    final pos = pp.screenPos;
    final bright = pp.brightness.clamp(0.6, 1.4);

    final toSun = sunCenter - pos;
    final dist = toSun.distance.clamp(1.0, double.infinity);
    final ld = Offset(toSun.dx / dist, toSun.dy / dist);

    // Shadow on orbital plane
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(pos.dx + 2, pos.dy + r * 0.7),
        width: r * 2.2,
        height: r * 0.5,
      ),
      Paint()
        ..color = AppColors.charcoal.withValues(alpha: 0.15 * bright)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.8),
    );

    if (p.atmosphere != null) {
      canvas.drawCircle(
        pos + ld * r * 0.12,
        r * 1.55,
        Paint()
          ..color = p.atmosphere!.withValues(alpha: 0.08 * bright)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.65),
      );
    }

    canvas.drawCircle(
      pos,
      r * 2.2,
      Paint()
        ..color = p.color.withValues(alpha: 0.12 * bright)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.9),
    );

    if (p.hasRings) _drawRings(canvas, pos, r, false);

    final litColor =
        Color.lerp(p.color, AppColors.parchment, (bright - 1.0) * 0.15)!;
    final darkColor =
        Color.lerp(p.colorDark, AppColors.charcoal, (1.0 - bright) * 0.08)!;
    canvas.drawCircle(
      pos,
      r,
      Paint()
        ..shader = ui.Gradient.linear(pos + ld * r, pos - ld * r, [
          litColor,
          darkColor,
        ]),
    );

    if (p.bands != null) {
      canvas.save();
      canvas.clipPath(Path()..addOval(Rect.fromCircle(center: pos, radius: r)));
      for (final band in p.bands!) {
        final by = pos.dy + r * band.yOffset;
        final bh = r * band.height;
        canvas.drawRect(
          Rect.fromLTWH(pos.dx - r, by - bh / 2, r * 2, bh),
          Paint()..color = band.color.withValues(alpha: 0.50 * bright),
        );
      }
      canvas.restore();
    }

    canvas.drawCircle(
      pos + ld * r * 0.28,
      r * 0.36,
      Paint()
        ..shader = ui.Gradient.radial(pos + ld * r * 0.28, r * 0.36, [
          AppColors.parchment.withValues(alpha: 0.42 * bright),
          AppColors.parchment.withValues(alpha: 0.0),
        ]),
    );

    canvas.drawCircle(
      pos,
      r,
      Paint()
        ..color = AppColors.parchment.withValues(alpha: 0.06 * bright)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6,
    );

    if (p.hasRings) {
      _drawRings(canvas, pos, r, true);
      canvas.save();
      canvas.clipPath(Path()..addOval(Rect.fromCircle(center: pos, radius: r)));
      canvas.drawRect(
        Rect.fromCenter(
          center: pos + Offset(0, r * 0.08),
          width: r * 5,
          height: r * 0.30,
        ),
        Paint()..color = AppColors.charcoal.withValues(alpha: 0.10),
      );
      canvas.restore();
    }

    _drawLabel(canvas, pos, p.name, r, p.color, bright);
  }

  void _drawRings(Canvas canvas, Offset pos, double r, bool front) {
    void arc(double th, Color c, double mul) {
      final rect = Rect.fromCenter(
        center: pos,
        width: r * 2.6 * mul * 2,
        height: r * 0.55 * mul * 2,
      );
      canvas.drawArc(
        rect,
        front ? 0 : math.pi,
        math.pi,
        false,
        Paint()
          ..color = c
          ..style = PaintingStyle.stroke
          ..strokeWidth = th,
      );
    }

    arc(4.5, AppColors.parchment.withValues(alpha: 0.55), 1.0);
    arc(1.5, AppColors.transparent, 0.90);
    arc(2.5, AppColors.parchment.withValues(alpha: 0.38), 0.83);
    arc(1.0, AppColors.parchment.withValues(alpha: 0.15), 1.20);
  }

  void _drawMoon(Canvas canvas, Offset center, double maxOrbit) {
    const i = 2;
    final earth = _planets[i];
    final eOrbit = earth.orbitFraction * maxOrbit;
    final eAngle = (t / earth.periodSeconds) * 2 * math.pi + earth.startAngle;
    final ex = center.dx + eOrbit * math.cos(eAngle);
    final ey = center.dy + eOrbit * math.sin(eAngle) * _tiltFactor;
    final earthPos = Offset(ex, ey);
    final moonOrbit = eOrbit * 0.20;
    final moonAngle = (t / 2.5) * 2 * math.pi;
    final mx = ex + moonOrbit * math.cos(moonAngle);
    final my = ey + moonOrbit * math.sin(moonAngle) * _tiltFactor;
    final moonPos = Offset(mx, my);

    canvas.drawOval(
      Rect.fromCenter(
        center: earthPos,
        width: moonOrbit * 2,
        height: moonOrbit * 2 * _tiltFactor,
      ),
      Paint()
        ..color = AppColors.parchment.withValues(alpha: 0.06)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.3,
    );

    canvas.drawCircle(
      moonPos,
      4.5,
      Paint()
        ..color = AppColors.parchment.withValues(alpha: 0.14)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    final toSun = center - moonPos;
    final dist = toSun.distance.clamp(1.0, double.infinity);
    final ld = Offset(toSun.dx / dist, toSun.dy / dist);
    canvas.drawCircle(
      moonPos,
      2.4,
      Paint()
        ..shader = ui.Gradient.linear(
          moonPos + ld * 2.4,
          moonPos - ld * 2.4,
          const [AppColors.parchment, AppColors.parchment],
        ),
    );
  }

  void _drawAsteroidBelt(Canvas canvas, Offset center, double maxOrbit) {
    final beltR = maxOrbit * 0.340;
    final rng = math.Random(31);
    for (int i = 0; i < 100; i++) {
      final angle = rng.nextDouble() * math.pi * 2 + t * 0.006;
      final rOff = beltR + (rng.nextDouble() - 0.5) * maxOrbit * 0.040;
      final ax = center.dx + rOff * math.cos(angle);
      final ay = center.dy + rOff * math.sin(angle) * _tiltFactor;
      final sz = rng.nextDouble() * 0.9 + 0.2;
      final zNorm = math.sin(angle);
      final depthOp = (0.5 + zNorm * 0.5).clamp(0.15, 1.0);
      canvas.drawCircle(
        Offset(ax, ay),
        sz * (1.0 + zNorm * 0.15),
        Paint()
          ..color = AppColors.parchment.withValues(
            alpha: (rng.nextDouble() * 0.08 + 0.02) * depthOp,
          ),
      );
    }
  }

  void _drawLabel(
    Canvas canvas,
    Offset pos,
    String name,
    double r,
    Color color,
    double bright,
  ) {
    final opacity = (0.65 * bright).clamp(0.3, 0.9);
    final tp = TextPainter(
      text: TextSpan(
        text: name,
        style: TextStyle(
          color: AppColors.parchment.withValues(alpha: opacity),
          fontSize: 9.0 * (0.8 + bright * 0.2).clamp(0.8, 1.1),
          letterSpacing: 1.4,
          fontWeight: FontWeight.w400,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final lx = pos.dx - tp.width / 2;
    final ly = pos.dy + r + 6.0;
    canvas.drawRect(
      Rect.fromLTWH(lx - 3, ly - 1, tp.width + 6, tp.height + 2),
      Paint()
        ..color = color.withValues(alpha: 0.10 * bright)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    tp.paint(canvas, Offset(lx, ly));
  }

  @override
  bool shouldRepaint(_SolarSystemPainter old) {
    return (t - old.t).abs() > 0.001;
  }
}
