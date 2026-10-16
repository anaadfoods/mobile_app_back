import 'package:flutter/material.dart';

/// Dotted delivery van illustration with floating question marks matching the paused mockup.
class RfpPausedTruckIllustration extends StatelessWidget {
  const RfpPausedTruckIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      width: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Floating question marks
          Positioned(
            top: 4,
            left: 50,
            child: Text(
              '?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFC62828).withValues(alpha: 0.5),
              ),
            ),
          ),
          Positioned(
            top: 2,
            right: 46,
            child: Text(
              '?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFC62828).withValues(alpha: 0.5),
              ),
            ),
          ),
          // Truck graphic
          CustomPaint(
            size: const Size(190, 85),
            painter: _DashedTruckPainter(),
          ),
        ],
      ),
    );
  }
}

class _DashedTruckPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = const Color(0xFFC62828).withValues(alpha: 0.55)
          ..strokeWidth = 1.8
          ..style = PaintingStyle.stroke;

    final dashPaint =
        Paint()
          ..color = const Color(0xFFC62828).withValues(alpha: 0.55)
          ..strokeWidth = 1.8
          ..style = PaintingStyle.stroke;

    // Truck body cargo box: rectangle from (20, 20) to (130, 70)
    _drawDashedRect(canvas, const Rect.fromLTWH(20, 18, 110, 52), dashPaint);

    // Cab front
    final cabPath = Path();
    cabPath.moveTo(130, 36);
    cabPath.lineTo(155, 36);
    cabPath.lineTo(172, 54);
    cabPath.lineTo(172, 70);
    cabPath.lineTo(130, 70);
    _drawDashedPath(canvas, cabPath, dashPaint);

    // Cab window
    final winPath = Path();
    winPath.moveTo(136, 40);
    winPath.lineTo(152, 40);
    winPath.lineTo(164, 52);
    winPath.lineTo(136, 52);
    winPath.close();
    canvas.drawPath(winPath, paint);

    // Wheels
    _drawWheel(canvas, const Offset(55, 70), 11);
    _drawWheel(canvas, const Offset(148, 70), 11);

    // Speed / confusion dashes behind truck
    canvas.drawLine(const Offset(6, 42), const Offset(14, 42), paint);
    canvas.drawLine(const Offset(2, 52), const Offset(12, 52), paint);
    canvas.drawLine(const Offset(8, 62), const Offset(14, 62), paint);
  }

  void _drawWheel(Canvas canvas, Offset center, double radius) {
    final circlePaint =
        Paint()
          ..color = const Color(0xFFC62828).withValues(alpha: 0.7)
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;

    final innerCirclePaint =
        Paint()
          ..color = const Color(0xFFFFF0EF)
          ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, innerCirclePaint);
    canvas.drawCircle(center, radius, circlePaint);

    // Inner spoke hub
    final spokePaint =
        Paint()
          ..color = const Color(0xFFC62828).withValues(alpha: 0.7)
          ..strokeWidth = 1.4;

    canvas.drawLine(
      Offset(center.dx - radius + 3, center.dy),
      Offset(center.dx + radius - 3, center.dy),
      spokePaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - radius + 3),
      Offset(center.dx, center.dy + radius - 3),
      spokePaint,
    );
  }

  void _drawDashedRect(Canvas canvas, Rect rect, Paint paint) {
    final path =
        Path()
          ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)));
    _drawDashedPath(canvas, path, paint);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    const dashWidth = 5.0;
    const dashSpace = 3.5;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final length =
            (distance + dashWidth < metric.length)
                ? dashWidth
                : metric.length - distance;
        final extract = metric.extractPath(distance, distance + length);
        canvas.drawPath(extract, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
