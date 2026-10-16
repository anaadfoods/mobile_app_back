import 'package:flutter/material.dart';

/// Design tokens from the Stitch DESIGN.md for the RFP feature.
///
/// These map exactly to the Stitch color palette, typography, spacing,
/// and shape tokens. Used by all RFP screens and widgets.
class RfpTheme {
  RfpTheme._();

  // ─── Colors (from Stitch DESIGN.md) ──────────────────────────────────────
  static const Color primary = Color(0xFF003629);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF1B4D3E);
  static const Color onPrimaryContainer = Color(0xFF8ABDA9);

  static const Color secondary = Color(0xFF486730);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFC9EEA9);
  static const Color onSecondaryContainer = Color(0xFF4E6D36);

  static const Color tertiary = Color(0xFF5A1701);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFF782D13);
  static const Color onTertiaryContainer = Color(0xFFFF9776);

  static const Color surface = Color(0xFFFAF9F7);
  static const Color surfaceDim = Color(0xFFDADAD8);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF4F3F1);
  static const Color surfaceContainer = Color(0xFFEFEEEC);
  static const Color surfaceContainerHigh = Color(0xFFE9E8E6);
  static const Color surfaceContainerHighest = Color(0xFFE3E2E0);

  static const Color onSurface = Color(0xFF1A1C1B);
  static const Color onSurfaceVariant = Color(0xFF404945);
  static const Color outline = Color(0xFF707974);
  static const Color outlineVariant = Color(0xFFC0C9C3);

  static const Color inverseSurface = Color(0xFF2F3130);
  static const Color inverseOnSurface = Color(0xFFF1F1EF);
  static const Color inversePrimary = Color(0xFF9ED1BD);

  static const Color primaryFixed = Color(0xFFBAEED9);
  static const Color primaryFixedDim = Color(0xFF9ED1BD);
  static const Color onPrimaryFixed = Color(0xFF002117);

  static const Color secondaryFixed = Color(0xFFC9EEA9);
  static const Color secondaryFixedDim = Color(0xFFAED18F);

  static const Color tertiaryFixed = Color(0xFFFFDBD0);
  static const Color tertiaryFixedDim = Color(0xFFFFB59E);

  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);

  // ─── Typography ──────────────────────────────────────────────────────────
  // Using existing app font family for consistency
  static const TextStyle headlineXl = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: -0.5,
    color: onSurface,
  );
  static const TextStyle headlineLg = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.25,
    letterSpacing: -0.3,
    color: onSurface,
  );
  static const TextStyle headlineMd = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w500,
    height: 1.33,
    color: onSurface,
  );
  static const TextStyle headlineSm = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: onSurface,
  );
  static const TextStyle bodyLg = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.56,
    color: onSurface,
  );
  static const TextStyle bodyMd = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: onSurface,
  );
  static const TextStyle bodySm = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.43,
    color: onSurface,
  );
  static const TextStyle labelMd = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.43,
    letterSpacing: 0.1,
    color: onSurface,
  );
  static const TextStyle labelSm = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.33,
    letterSpacing: 0.2,
    color: onSurface,
  );

  // ─── Spacing ─────────────────────────────────────────────────────────────
  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 16;
  static const double spaceLg = 24;
  static const double spaceXl = 40;
  static const double gutter = 24;

  // ─── Shapes ──────────────────────────────────────────────────────────────
  static const double radiusSm = 4;
  static const double radiusMd = 8;
  static const double radiusLg = 12;
  static const double radiusXl = 16;
  static const double radiusFull = 999;

  // ─── Shadows ─────────────────────────────────────────────────────────────
  static List<BoxShadow> get shadowSm => [
    BoxShadow(
      color: const Color(0xFF003629).withValues(alpha: 0.06),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get shadowMd => [
    BoxShadow(
      color: const Color(0xFF003629).withValues(alpha: 0.10),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];
}
