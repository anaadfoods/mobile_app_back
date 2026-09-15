import 'package:flutter/material.dart';

class PPlan {
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

  const PPlan({
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

const List<PPlan> pPlanets = [
  PPlan(
    name: 'Mercury',
    orbit: 0.18,
    radius: 4.5,
    period: 3.5,
    start: 0.5,
    color: Color(0xFFB0BEC5),
    colorDark: Color(0xFF37474F),
  ),
  PPlan(
    name: 'Venus',
    orbit: 0.28,
    radius: 7.2,
    period: 7.5,
    start: 2.1,
    color: Color(0xFFFFD54F),
    colorDark: Color(0xFFE65100),
    atmosphere: Color(0x33FFB300),
  ),
  PPlan(
    name: 'Earth',
    orbit: 0.42,
    radius: 8.5,
    period: 14.0,
    start: 4.3,
    color: Color(0xFF29B6F6),
    colorDark: Color(0xFF0D47A1),
    atmosphere: Color(0x3303A9F4),
  ),
  PPlan(
    name: 'Mars',
    orbit: 0.58,
    radius: 6.0,
    period: 24.0,
    start: 1.0,
    color: Color(0xFFFF7043),
    colorDark: Color(0xFFBF360C),
  ),
  PPlan(
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
  PPlan(
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
