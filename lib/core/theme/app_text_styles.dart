import 'package:flutter/material.dart';
import 'app_colors.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// AppTextStyles — Consistent, reusable typography tokens.
///
/// Usage:
///   Text('Hello', style: AppTextStyles.heading)
///   Text('Sub', style: AppTextStyles.subheading)
///
/// Rules:
///   • NEVER use inline TextStyle(fontSize: …, fontWeight: …) in widgets.
///   • Always reference AppTextStyles or context.text (TextTheme from theme).
///   • If you need a one-off override, use .copyWith() on an existing style.
/// ═══════════════════════════════════════════════════════════════════════════
class AppTextStyles {
  AppTextStyles._(); // Prevent instantiation

  static const String fontFamily = 'Gilroy';

  // ─── Display / Heading ─────────────────────────────────────────────────────
  /// 32px bold — Page titles, hero sections
  static const TextStyle heading = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
    height: 1.25,
  );

  /// 24px bold — Section headers
  static const TextStyle subheading = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.3,
    height: 1.3,
  );

  /// 20px semi-bold — Card titles, sub-section labels
  static const TextStyle title = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  // ─── Body ──────────────────────────────────────────────────────────────────
  /// 16px normal — Primary body text
  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  /// 14px normal — Secondary body text, descriptions
  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  // ─── Caption / Label ───────────────────────────────────────────────────────
  /// 12px normal — Captions, timestamps, hints
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.normal,
    height: 1.4,
  );

  /// 14px semi-bold — Button labels
  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.parchment,
    letterSpacing: 0.5,
    height: 1.4,
  );

  /// 14px medium — Input field labels
  static const TextStyle label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  /// 18px semi-bold — AppBar titles
  static const TextStyle appBarTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );
}
