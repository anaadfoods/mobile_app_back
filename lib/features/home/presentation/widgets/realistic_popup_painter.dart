import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

const double _popupTilt = 0.38;
const double _popupDepthScale = 0.28;
const double _popupDepthBright = 0.25;

class _PPlan {
  final String name;
  final double orbit;
  final double radius;
  final double period;
  final double start;
  final Color color;
  final Color colorDark;
  final Color? atmosphere;
  final bool hasRings;
  final List<List<double>>? bands;

  const _PPlan({
    required this.name,
    required this.orbit,
    required this.radius,
    required this.period,
    required this.start,
    required this.color,
    required this.colorDark,
    this.atmosphere,
    this.hasRings = false,
    this.bands,
  });
}

const List<_PPlan> _pPlanets = [
  _PPlan(
    name: 'Mercury',
    orbit: 0.18,
    radius: 4.5,
    period: 3.5,
    start: 0.5,
    color: Color(0xFFB0BEC5),
    colorDark: Color(0xFF37474F),
  ),
  _PPlan(
    name: 'Venus',
    orbit: 0.28,
    radius: 7.2,
    period: 7.5,
    start: 2.1,
    color: Color(0xFFFFD54F),
    colorDark: Color(0xFFE65100),
    atmosphere: Color(0x33FFB300),
  ),
  _PPlan(
    name: 'Earth',
    orbit: 0.42,
    radius: 8.5,
    period: 14.0,
    start: 4.3,
    color: Color(0xFF29B6F6),
    colorDark: Color(0xFF0D47A1),
    atmosphere: Color(0x3303A9F4),
  ),
  _PPlan(
    name: 'Mars',
    orbit: 0.58,
    radius: 6.0,
    period: 24.0,
    start: 1.0,
    color: Color(0xFFFF7043),
    colorDark: Color(0xFFBF360C),
  ),
  _PPlan(
    name: 'Jupiter',
    orbit: 0.76,
    radius: 17.0,
    period: 52.0,
    start: 5.5,
    color: Color(0xFFFFB74D),
    colorDark: Color(0xFF5D4037),
    bands: [
      [0xFF8D6E63, -0.4, 3.5],
      [0xFFD7CCC8, -0.15, 2.5],
      [0xFFE0F7FA, 0.05, 1.8],
      [0xFFA1887F, 0.25, 3.0],
    ],
  ),
  _PPlan(
    name: 'Saturn',
    orbit: 0.94,
    radius: 14.0,
    period: 110.0,
    start: 3.2,
    color: Color(0xFFFFE082),
    colorDark: Color(0xFF6D4C41),
    hasRings: true,
  ),
];

class _PPos {
  final int idx;
  final double angle;
  final double scale;
  final double bright;
  final Offset screen;

  const _PPos({
    required this.idx,
    required this.angle,
    required this.scale,
    required this.bright,
    required this.screen,
  });
}

class RealisticPopupPainter extends CustomPainter {
  final double t;
  const RealisticPopupPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.44;
    final maxOrbit = size.width * 0.49;

    canvas.drawCircle(
      Offset(cx, cy),
      maxOrbit * 1.02,
      Paint()
        ..color = const Color(0xFF030810)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
    );

    _drawSun(canvas, Offset(cx, cy), maxOrbit * 0.08);

    final List<_PPos> all = [];
    for (int i = 0; i < _pPlanets.length; i++) {
      final p = _pPlanets[i];
      final orbitR = p.orbit * maxOrbit;
      final angle = (t / p.period) * 2 * math.pi + p.start;

      final dx = orbitR * math.cos(angle);
      final dy = orbitR * math.sin(angle) * _popupTilt;

      final scale = 1.0 + (dy / orbitR) * _popupDepthScale;
      final bright = 1.0 + (dy / orbitR) * _popupDepthBright;

      all.add(
        _PPos(
          idx: i,
          angle: angle,
          scale: scale,
          bright: bright,
          screen: Offset(cx + dx, cy + dy),
        ),
      );
    }

    all.sort((a, b) => a.screen.dy.compareTo(b.screen.dy));

    for (final pp in all) {
      _drawOrbitTrail(canvas, Offset(cx, cy), pp, maxOrbit);
    }

    _drawMoon(canvas, Offset(cx, cy), maxOrbit);

    for (final pp in all) {
      _drawFullPlanet(canvas, pp, Offset(cx, cy), maxOrbit * 0.08, size);
    }
  }

  void _drawSun(Canvas canvas, Offset c, double r) {
    final pulse = 0.94 + 0.06 * math.sin(t * 1.5);
    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(
        c,
        r * (1.0 + i * 0.50) * pulse,
        Paint()
          ..color = const Color(0xFFFF9800).withValues(alpha: 0.025 * i)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10.0 + i * 3),
      );
    }
    canvas.drawCircle(
      c,
      r * 1.45,
      Paint()
        ..color = const Color(0xFFFFCC02).withValues(alpha: 0.20)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = ui.Gradient.radial(
          c,
          r,
          const [
            Color(0xFFFFFFE8),
            Color(0xFFFFF176),
            Color(0xFFFFCA28),
            Color(0xFFFF8F00),
            Color(0xFFE65100),
          ],
          const [0.0, 0.25, 0.55, 0.82, 1.0],
        ),
    );
    final spotA = t * 0.3;
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: c, radius: r)));
    canvas.drawCircle(
      Offset(
        c.dx + r * 0.35 * math.cos(spotA),
        c.dy + r * 0.15 * math.sin(spotA),
      ),
      r * 0.10,
      Paint()..color = const Color(0xFFCC7700).withValues(alpha: 0.32),
    );
    canvas.restore();
  }

  void _drawOrbitTrail(
    Canvas canvas,
    Offset center,
    _PPos pp,
    double maxOrbit,
  ) {
    final p = _pPlanets[pp.idx];
    final r = p.orbit * maxOrbit;
    const sweep = 0.50;
    final rect = Rect.fromCenter(
      center: center,
      width: r * 2,
      height: r * 2 * _popupTilt,
    );
    canvas.drawArc(
      rect,
      pp.angle - sweep,
      sweep,
      false,
      Paint()
        ..color = p.color.withValues(alpha: 0.10 * pp.bright.clamp(0.5, 1.5))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 * pp.scale
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawArc(
      rect,
      pp.angle - sweep * 0.5,
      sweep * 0.5,
      false,
      Paint()
        ..color = p.color.withValues(alpha: 0.20 * pp.bright.clamp(0.5, 1.5))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8 * pp.scale
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawFullPlanet(
    Canvas canvas,
    _PPos pp,
    Offset sunCenter,
    double sunR,
    Size size,
  ) {
    final p = _pPlanets[pp.idx];
    final r = p.radius * pp.scale;
    final pos = pp.screen;
    final bright = pp.bright.clamp(0.6, 1.4);

    final toSun = sunCenter - pos;
    final dist = toSun.distance.clamp(1.0, double.infinity);
    final ld = Offset(toSun.dx / dist, toSun.dy / dist);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(pos.dx + 1.5, pos.dy + r * 0.6),
        width: r * 2.0,
        height: r * 0.4,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.12 * bright)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.7),
    );

    if (p.atmosphere != null) {
      canvas.drawCircle(
        pos + ld * r * 0.12,
        r * 1.5,
        Paint()
          ..color = p.atmosphere!.withValues(alpha: 0.08 * bright)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.6),
      );
    }

    canvas.drawCircle(
      pos,
      r * 2.0,
      Paint()
        ..color = p.color.withValues(alpha: 0.12 * bright)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.8),
    );

    if (p.hasRings) _drawRing(canvas, pos, r, false);

    final litColor = Color.lerp(p.color, Colors.white, (bright - 1.0) * 0.15)!;
    final darkColor =
        Color.lerp(p.colorDark, Colors.black, (1.0 - bright) * 0.08)!;
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
      for (final b in p.bands!) {
        final by = pos.dy + r * b[1];
        final bh = r * b[2];
        canvas.drawRect(
          Rect.fromLTWH(pos.dx - r, by - bh / 2, r * 2, bh),
          Paint()..color = Color(b[0].toInt()).withValues(alpha: 0.50 * bright),
        );
      }
      canvas.restore();
    }

    canvas.drawCircle(
      pos + ld * r * 0.28,
      r * 0.35,
      Paint()
        ..shader = ui.Gradient.radial(pos + ld * r * 0.28, r * 0.35, [
          Colors.white.withValues(alpha: 0.40 * bright),
          Colors.white.withValues(alpha: 0.0),
        ]),
    );

    canvas.drawCircle(
      pos,
      r,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.06 * bright)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5,
    );

    if (p.hasRings) {
      _drawRing(canvas, pos, r, true);
      canvas.save();
      canvas.clipPath(Path()..addOval(Rect.fromCircle(center: pos, radius: r)));
      canvas.drawRect(
        Rect.fromCenter(
          center: pos + Offset(0, r * 0.08),
          width: r * 5,
          height: r * 0.25,
        ),
        Paint()..color = Colors.black.withOpacity(0.10),
      );
      canvas.restore();
    }

    final opacity = (0.60 * bright).clamp(0.3, 0.85);
    final tp = TextPainter(
      text: TextSpan(
        text: p.name,
        style: TextStyle(
          color: Colors.white.withValues(alpha: opacity),
          fontSize: 7.5 * (0.8 + bright * 0.2).clamp(0.8, 1.1),
          letterSpacing: 0.8,
          fontWeight: FontWeight.w400,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final lx = (pos.dx - tp.width / 2).clamp(3.0, size.width - tp.width - 3);
    final ly = (pos.dy + r + 4.0).clamp(3.0, size.height - tp.height - 3);
    canvas.drawRect(
      Rect.fromLTWH(lx - 2, ly - 1, tp.width + 4, tp.height + 2),
      Paint()
        ..color = p.color.withValues(alpha: 0.08 * bright)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    tp.paint(canvas, Offset(lx, ly));
  }

  void _drawRing(Canvas canvas, Offset pos, double r, bool front) {
    void arc(double th, Color c, double mul) {
      final rect = Rect.fromCenter(
        center: pos,
        width: r * 2.5 * mul * 2,
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

    arc(3.0, const Color(0xFFD4B896).withValues(alpha: 0.55), 1.0);
    arc(1.2, Colors.transparent, 0.88);
    arc(1.8, const Color(0xFFBDA882).withValues(alpha: 0.38), 0.80);
    arc(0.8, const Color(0xFFE8D0B0).withValues(alpha: 0.15), 1.18);
  }

  void _drawMoon(Canvas canvas, Offset center, double maxOrbit) {
    const i = 2;
    final ep = _pPlanets[i];
    final eOrbit = ep.orbit * maxOrbit;
    final eAngle = (t / ep.period) * 2 * math.pi + ep.start;
    final ex = center.dx + eOrbit * math.cos(eAngle);
    final ey = center.dy + eOrbit * math.sin(eAngle) * _popupTilt;
    final earthPos = Offset(ex, ey);
    final moonOrbit = eOrbit * 0.22;
    final moonAngle = (t / 2.5) * 2 * math.pi;
    final mx = ex + moonOrbit * math.cos(moonAngle);
    final my = ey + moonOrbit * math.sin(moonAngle) * _popupTilt;
    final moonPos = Offset(mx, my);
    canvas.drawOval(
      Rect.fromCenter(
        center: earthPos,
        width: moonOrbit * 2,
        height: moonOrbit * 2 * _popupTilt,
      ),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.06)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.3,
    );
    canvas.drawCircle(
      moonPos,
      3.0,
      Paint()
        ..color = const Color(0xFFCFD8DC).withValues(alpha: 0.14)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    final toSun = center - moonPos;
    final dist = toSun.distance.clamp(1.0, double.infinity);
    final ld = Offset(toSun.dx / dist, toSun.dy / dist);
    canvas.drawCircle(
      moonPos,
      1.5,
      Paint()
        ..shader = ui.Gradient.linear(
          moonPos + ld * 1.5,
          moonPos - ld * 1.5,
          const [Color(0xFFE0E4E8), Color(0xFF606868)],
        ),
    );
  }

  @override
  bool shouldRepaint(RealisticPopupPainter old) => old.t != t;
}
