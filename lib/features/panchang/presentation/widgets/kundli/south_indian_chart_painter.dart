// lib/features/panchang/presentation/widgets/kundli/south_indian_chart_painter.dart
import 'package:flutter/material.dart';
import '../../../domain/entities/kundli_entities.dart';

class SouthIndianChartPainter extends CustomPainter {
  final KundliEntity kundli;
  final Color borderColor;
  final Color primaryColor;
  final Color textColor;
  final Color backgroundColor;
  final Color centerColor;

  SouthIndianChartPainter({
    required this.kundli,
    this.borderColor = const Color(0xFFD4AF37),
    this.primaryColor = const Color(0xFF2E6B34),
    this.textColor = const Color(0xFF1B2E1D),
    this.backgroundColor = const Color(0xFFFAF7EE),
    this.centerColor = const Color(0xFFF3EED9),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cellW = w / 4;
    final cellH = h / 4;

    final borderPaint = Paint()
      ..color = borderColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    // Outer
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), borderPaint);

    // Grid lines for 4x4
    for (int i = 1; i < 4; i++) {
      canvas.drawLine(Offset(cellW * i, 0), Offset(cellW * i, h), borderPaint);
      canvas.drawLine(Offset(0, cellH * i), Offset(w, cellH * i), borderPaint);
    }

    // Fill center 2x2 empty box
    final centerRect = Rect.fromLTWH(cellW, cellH, cellW * 2, cellH * 2);
    canvas.drawRect(centerRect, Paint()..color = centerColor);
    canvas.drawRect(centerRect, borderPaint);

    // South Indian fixed sign grid coordinates (12 perimeter boxes)
    // 0: Pisces (row 0, col 0) ... 11: Aquarius
    final rashiCoords = <int, Rect>{
      11: Rect.fromLTWH(0, 0, cellW, cellH),          // Meena (Pisces)
      0: Rect.fromLTWH(cellW, 0, cellW, cellH),        // Mesha (Aries)
      1: Rect.fromLTWH(cellW * 2, 0, cellW, cellH),    // Vrishabha
      2: Rect.fromLTWH(cellW * 3, 0, cellW, cellH),    // Mithuna
      3: Rect.fromLTWH(cellW * 3, cellH, cellW, cellH),// Karka
      4: Rect.fromLTWH(cellW * 3, cellH * 2, cellW, cellH), // Simha
      5: Rect.fromLTWH(cellW * 3, cellH * 3, cellW, cellH), // Kanya
      6: Rect.fromLTWH(cellW * 2, cellH * 3, cellW, cellH), // Tula
      7: Rect.fromLTWH(cellW, cellH * 3, cellW, cellH),     // Vrishchika
      8: Rect.fromLTWH(0, cellH * 3, cellW, cellH),         // Dhanu
      9: Rect.fromLTWH(0, cellH * 2, cellW, cellH),         // Makara
      10: Rect.fromLTWH(0, cellH, cellW, cellH),            // Kumbha
    };

    // Draw Lagna indicator (ASC / L)
    final rashiNames = [
      'Mesha', 'Vrishabha', 'Mithuna', 'Karka', 'Simha', 'Kanya',
      'Tula', 'Vrishchika', 'Dhanu', 'Makara', 'Kumbha', 'Meena'
    ];
    final lagnaIdx = rashiNames.indexOf(kundli.lagna.sign);
    if (lagnaIdx != -1 && rashiCoords.containsKey(lagnaIdx)) {
      final r = rashiCoords[lagnaIdx]!;
      _drawText(canvas, 'LAGNA', Offset(r.left + cellW / 2, r.top + 10), 9, FontWeight.bold, Colors.red.shade800);
    }

    // Map planets into rashis
    for (final p in kundli.planets) {
      final rIdx = p.rashiIndex;
      if (rashiCoords.containsKey(rIdx)) {
        final r = rashiCoords[rIdx]!;
        _drawText(
          canvas,
          _getShortName(p.name),
          Offset(r.left + cellW / 2, r.top + 26 + (p.house % 2 * 12)),
          10,
          FontWeight.w600,
          primaryColor,
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

  void _drawText(Canvas canvas, String text, Offset offset, double size, FontWeight weight, Color color) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: size, fontWeight: weight)),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(offset.dx - tp.width / 2, offset.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant SouthIndianChartPainter oldDelegate) {
    return oldDelegate.kundli != kundli;
  }
}
