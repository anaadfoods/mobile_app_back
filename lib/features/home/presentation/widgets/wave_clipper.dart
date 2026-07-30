import 'package:flutter/material.dart';

class WaveClipper extends CustomClipper<Path> {
  final double notchRadius;
  final double notchMargin;

  WaveClipper({this.notchRadius = 28.0, this.notchMargin = 6.0});

  @override
  Path getClip(Size size) {
    final path = Path();
    final centerX = size.width / 2;
    final notchTotalRadius = notchRadius + notchMargin;

    path.moveTo(0, 16);
    path.quadraticBezierTo(0, 0, 16, 0);
    path.lineTo(centerX - notchTotalRadius - 16, 0);
    path.quadraticBezierTo(
      centerX - notchTotalRadius,
      0,
      centerX - notchTotalRadius,
      6,
    );
    path.arcToPoint(
      Offset(centerX - notchRadius + 4, notchTotalRadius - 4),
      radius: Radius.circular(notchRadius * 0.5),
      clockwise: false,
    );
    path.arcToPoint(
      Offset(centerX + notchRadius - 4, notchTotalRadius - 4),
      radius: Radius.circular(notchRadius + 4),
      clockwise: true,
    );
    path.arcToPoint(
      Offset(centerX + notchTotalRadius, 6),
      radius: Radius.circular(notchRadius * 0.5),
      clockwise: false,
    );
    path.quadraticBezierTo(
      centerX + notchTotalRadius,
      0,
      centerX + notchTotalRadius + 16,
      0,
    );
    path.lineTo(size.width - 16, 0);
    path.quadraticBezierTo(size.width, 0, size.width, 16);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
