// lib/features/panchang/presentation/widgets/kundli/north_indian_chart_painter.dart
import 'package:flutter/material.dart';
import '../../../domain/entities/kundli_entities.dart';

class NorthIndianChartPainter extends CustomPainter {
  final KundliEntity kundli;
  final Color borderColor;
  final Color primaryColor;
  final Color textColor;
  final Color houseNumberColor;
  final Color backgroundColor;

  NorthIndianChartPainter({
    required this.kundli,
    this.borderColor = const Color(0xFFD4AF37),
    this.primaryColor = const Color(0xFF2E6B34),
    this.textColor = const Color(0xFF1B2E1D),
    this.houseNumberColor = const Color(0xFF8C7A3E),
    this.backgroundColor = const Color(0xFFFAF7EE),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final borderPaint = Paint()
      ..color = borderColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final linePaint = Paint()
      ..color = borderColor.withOpacity(0.7)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    // Outer Rectangle
    final rect = Rect.fromLTWH(0, 0, w, h);
    canvas.drawRect(rect, bgPaint);
    canvas.drawRect(rect, borderPaint);

    // Diagonal Lines
    canvas.drawLine(Offset(0, 0), Offset(w, h), linePaint);
    canvas.drawLine(Offset(w, 0), Offset(0, h), linePaint);

    // Inner Diamond
    final diamondPath = Path()
      ..moveTo(w / 2, 0)
      ..lineTo(w, h / 2)
      ..lineTo(w / 2, h)
      ..lineTo(0, h / 2)
      ..close();
    canvas.drawPath(diamondPath, linePaint);

    // Map planets to houses
    final housePlanets = <int, List<String>>{};
    for (final p in kundli.planets) {
      final shortName = _getShortName(p.name);
      housePlanets.putIfAbsent(p.house, () => []).add(shortName);
    }

    // 12 House Centers (North Indian fixed house positions)
    final houseCenters = <int, Offset>{
      1: Offset(w / 2, h * 0.25),
      2: Offset(w * 0.25, h * 0.12),
      3: Offset(w * 0.12, h * 0.25),
      4: Offset(w * 0.25, h / 2),
      5: Offset(w * 0.12, h * 0.75),
      6: Offset(w * 0.25, h * 0.88),
      7: Offset(w / 2, h * 0.75),
      8: Offset(w * 0.75, h * 0.88),
      9: Offset(w * 0.88, h * 0.75),
      10: Offset(w * 0.75, h / 2),
      11: Offset(w * 0.88, h * 0.25),
      12: Offset(w * 0.75, h * 0.12),
    };

    final lagnaSign = kundli.lagna.sign;
    final rashiNames = [
      'Mesha', 'Vrishabha', 'Mithuna', 'Karka', 'Simha', 'Kanya',
      'Tula', 'Vrishchika', 'Dhanu', 'Makara', 'Kumbha', 'Meena'
    ];
    final lagnaIdx = rashiNames.indexOf(lagnaSign) != -1 ? rashiNames.indexOf(lagnaSign) + 1 : 1;

    for (int hNum = 1; hNum <= 12; hNum++) {
      final center = houseCenters[hNum]!;
      final rashiNumber = ((lagnaIdx + hNum - 2) % 12) + 1;

      // Draw Rashi Number
      _drawText(
        canvas: canvas,
        text: '$rashiNumber',
        offset: Offset(center.dx, center.dy - 12),
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: houseNumberColor,
      );

      // Draw Planets in House
      final planets = housePlanets[hNum] ?? [];
      if (planets.isNotEmpty) {
        final planetStr = planets.join(' ');
        _drawText(
          canvas: canvas,
          text: planetStr,
          offset: Offset(center.dx, center.dy + 4),
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: primaryColor,
        );
      }
    }
  }

  String _getShortName(String name) {
    switch (name) {
      case 'Sun': return 'Su';
      case 'Moon': return 'Mo';
      case 'Mars': return 'Ma';
      case 'Mercury': return 'Me';
      case 'Jupiter': return 'Ju';
      case 'Venus': return 'Ve';
      case 'Saturn': return 'Sa';
      case 'Rahu': return 'Ra';
      case 'Ketu': return 'Ke';
      default: return name.substring(0, 2);
    }
  }

  void _drawText({
    required Canvas canvas,
    required String text,
    required Offset offset,
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
  }) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
        fontFamily: 'serif',
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();

    final drawOffset = Offset(
      offset.dx - textPainter.width / 2,
      offset.dy - textPainter.height / 2,
    );
    textPainter.paint(canvas, drawOffset);
  }

  @override
  bool shouldRepaint(covariant NorthIndianChartPainter oldDelegate) {
    return oldDelegate.kundli != kundli;
  }
}
