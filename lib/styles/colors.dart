import 'dart:ui';

import 'package:flutter/material.dart';

class AppColors {
  //One instance, needs factory
  static AppColors? _instance;
  factory AppColors() => _instance ??= AppColors._();

  AppColors._();

  // Primary Colors
  static const primaryColor = Color(0xff53B175);
  static const primaryLight = Color(0xff7BC48F);
  static const primaryDark = Color(0xff3A8C54);

  // Secondary Colors
  static const secondaryColor = Color(0xffF8F8F8);
  static const secondaryLight = Color(0xffFFFFFF);
  static const secondaryDark = Color(0xffE8E8E8);

  // Text Colors
  static const textPrimary = Color(0xff181725);
  static const textSecondary = Color(0xff7C7C7C);
  static const textLight = Color(0xffB3B3B3);

  // Background Colors
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
}
