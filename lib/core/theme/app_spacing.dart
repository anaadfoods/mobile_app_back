import 'package:flutter/material.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// AppSpacing — Consistent spacing scale (based on a 4px grid).
///
/// Usage:
///   Padding(padding: AppSpacing.paddingMd)
///   SizedBox(height: AppSpacing.md)
///   EdgeInsets.all(AppSpacing.lg)
///
/// Rules:
///   • NEVER use magic numbers like EdgeInsets.all(17) in widget code.
///   • Always use AppSpacing constants for margin, padding, and gaps.
/// ═══════════════════════════════════════════════════════════════════════════
class AppSpacing {
  AppSpacing._(); // Prevent instantiation

  // ─── Raw Values (4px grid) ─────────────────────────────────────────────────
  /// 4px — Compact spacing, icon gaps
  static const double xs = 4.0;

  /// 8px — Small gaps, tight padding
  static const double sm = 8.0;

  /// 12px — Default gap between related elements
  static const double md = 12.0;

  /// 16px — Standard section padding
  static const double lg = 16.0;

  /// 24px — Generous spacing between sections
  static const double xl = 24.0;

  /// 32px — Major section separators, page margins
  static const double xxl = 32.0;

  /// 48px — Hero-level spacing
  static const double xxxl = 48.0;

  // ─── Pre-built EdgeInsets ──────────────────────────────────────────────────
  // Horizontal
  static const EdgeInsets paddingHorizontalXs =
      EdgeInsets.symmetric(horizontal: xs);
  static const EdgeInsets paddingHorizontalSm =
      EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets paddingHorizontalMd =
      EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets paddingHorizontalLg =
      EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets paddingHorizontalXl =
      EdgeInsets.symmetric(horizontal: xl);

  // Vertical
  static const EdgeInsets paddingVerticalXs =
      EdgeInsets.symmetric(vertical: xs);
  static const EdgeInsets paddingVerticalSm =
      EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets paddingVerticalMd =
      EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets paddingVerticalLg =
      EdgeInsets.symmetric(vertical: lg);
  static const EdgeInsets paddingVerticalXl =
      EdgeInsets.symmetric(vertical: xl);

  // All-sides
  static const EdgeInsets paddingXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingMd = EdgeInsets.all(md);
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);
  static const EdgeInsets paddingXl = EdgeInsets.all(xl);
  static const EdgeInsets paddingXxl = EdgeInsets.all(xxl);

  // ─── SizedBox Gap Widgets (use in Column / Row) ────────────────────────────
  static const SizedBox verticalXs = SizedBox(height: xs);
  static const SizedBox verticalSm = SizedBox(height: sm);
  static const SizedBox verticalMd = SizedBox(height: md);
  static const SizedBox verticalLg = SizedBox(height: lg);
  static const SizedBox verticalXl = SizedBox(height: xl);
  static const SizedBox verticalXxl = SizedBox(height: xxl);

  static const SizedBox horizontalXs = SizedBox(width: xs);
  static const SizedBox horizontalSm = SizedBox(width: sm);
  static const SizedBox horizontalMd = SizedBox(width: md);
  static const SizedBox horizontalLg = SizedBox(width: lg);
  static const SizedBox horizontalXl = SizedBox(width: xl);
  static const SizedBox horizontalXxl = SizedBox(width: xxl);
}
