import 'dart:ui';

import 'package:flutter/material.dart';

class AppColors {
  //One instance, needs factory
  static AppColors? _instance;
  factory AppColors() => _instance ??= AppColors._();

  AppColors._();

  // Primary Colors
  static const primaryColor = Color(0xff3f5e46);
  static const primaryLight = Color(0xff7BC48F);
  static const primaryDark = Color(0xff3A8C54);

  // Secondary Colors
  static const secondaryColor = Color(0xff6b1e1e);
  static const secondaryLight = Color(0xffFFFFFF);
  static const secondaryDark = Color(0xffE8E8E8);

  // Text Colors
  static const textPrimary = Color(0xff181725);
  static const textSecondary = Color(0xff7C7C7C);
  static const textLight = Color(0xffB3B3B3);

  static const cardColor = Color.fromARGB(255, 19, 18, 18);

  // Background Colors
  static const buttonBackgroundColor = Color(0xffad8441);
  static const background = Color(0xffFFFFFF);
  static const backgroundDark = Color(0xffF2F3F2);

  // Status Colors
  static const success = Color(0xff4CAF50);
  static const error = Color(0xffE53935);
  static const warning = Color(0xffFFC107);
  static const info = Color(0xff2196F3);

  // Border Colors
  static const border = Color(0xffE2E2E2);
  static const divider = Color(0xffF2F2F2);

  // Order Status Colors
  static const orderDelivered = Color(0xff4CAF50); // Green
  static const orderPlaced = Color(0xffFFA726); // Orange
  static const orderCancelled = Color(0xffEF5350); // Red
  static const orderProcessing = Color(0xff42A5F5); // Blue

  // ═══════════════════════════════════════════════════════════════════════════
  // DESIGN SYSTEM CONSTANTS
  // ═══════════════════════════════════════════════════════════════════════════

  // Spacing Scale (based on 4px grid)
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 12.0;
  static const double spacingL = 16.0;
  static const double spacingXL = 24.0;
  static const double spacingXXL = 32.0;

  // Border Radius Presets
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusRound = 30.0;

  // Animation Durations (in milliseconds)
  static const int animFast = 150;
  static const int animMedium = 200;
  static const int animSlow = 300;

  // Elevation/Shadow Opacity Values
  static const double shadowOpacityLight = 0.05;
  static const double shadowOpacityMedium = 0.1;
  static const double shadowOpacityHeavy = 0.15;
}
