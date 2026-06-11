import 'package:flutter/material.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// AppColors — Single source of truth for every color in the application.
/// Strictly conforms to the ANAAD Premium Edition Guideline - Version 1.0
///
/// Rules:
///   • NEVER use inline Color(0x…) or Colors.xxx in widget code.
///   • No non-palette colors are allowed.
/// ═══════════════════════════════════════════════════════════════════════════
class AppColors {
  AppColors._(); // Prevent instantiation

  // ─── The 5 Core Premium Colors ─────────────────────────────────────────────
  static const Color deepSoilGreen = Color(0xFF2C4A1E); // Primary Identity Anchor
  static const Color parchment = Color(0xFFF5F0E8);      // Dominant Canvas Floor
  static const Color charcoal = Color(0xFF1A1A1A);       // Typography Voice
  static const Color rawEarth = Color(0xFF6B4226);       // Secondary Depth Layer
  static const Color harvestAmber = Color(0xFFC9943A);   // Tertiary Luxury Signal

  // Only allowed pure color for internal UI cards (Rule 5.1 & 7.4)
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color pureBlack = Color(0xFF000000);
  // Structural Transparent Layer
  static const Color transparent = Color(0x00000000);

  // ─── Light Theme Semantic Colors ───────────────────────────────────────────
  // Golden spectrum for banners, highlights, active states
  static const Color softGold = Color(0xFFF0D78C);        // Muted golden for banner fills
  static const Color warmGold = Color(0xFFDBA94D);         // Rich gold for CTA emphasis
  static const Color lightGold = Color(0xFFFDF6E3);        // Subtle golden tint bg
  static const Color goldenGlow = Color(0xFFE8C362);       // Medium intensity gold

  // Clean whites for cards, popups, floating surfaces
  static const Color snowWhite = Color(0xFFFCFCFC);        // Near-white for banners
  static const Color softCream = Color(0xFFFAF7F2);        // Warm white for popups

  // Success / Status greens (within brand range)
  static const Color successGreen = Color(0xFF3A6B24);     // Vivid leaf green for success
  static const Color mintGreen = Color(0xFFE8F5E2);        // Light success bg

  // Error / Warning tones (brand-safe)
  static const Color softRed = Color(0xFFB8433A);          // Muted terracotta red
  static const Color softRedBg = Color(0xFFFBEDEB);        // Light error bg
  static const Color amberWarn = Color(0xFFD4920A);        // Rich amber warning
  static const Color amberWarnBg = Color(0xFFFFF8E7);      // Light warning bg

  // Price Amber tones (high-contrast branding)
  static const Color priceAmberLight = Color(0xFFD4920A);   // Rich amber warning/gold for light canvas
  static const Color priceAmberDark = Color(0xFFFFC107);    // Amber/yellow for dark canvas

  /// Dynamic helper to retrieve price color based on theme brightness.
  static Color getPriceColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? priceAmberDark
        : priceAmberLight;
  }

  // Info tones (brand-safe)
  static const Color infoTeal = Color(0xFF2A7B7B);         // Deep teal for info
  static const Color infoBg = Color(0xFFE7F5F5);           // Light info bg

  // ─── Dark Theme Semantic Colors ────────────────────────────────────────────
  static const Color darkCanvas = Color(0xFF121212);       // Deepest background for dark mode
  static const Color darkSurface = Color(0xFF1E1E1E);      // Elevated surfaces (cards, dialogues)
  static const Color darkSurfaceElevated = Color(0xFF2C2C2C); // Higher elevation surfaces

  // Dark golden spectrum
  static const Color darkSoftGold = Color(0xFFD4AF37);     // Metallic gold for dark mode highlights
  static const Color darkWarmGold = Color(0xFFB8860B);     // Dark goldenrod for active states

  // Dark success/error/info
  static const Color darkSuccessGreen = Color(0xFF4CAF50); // Accessible green on dark
  static const Color darkMintGreen = Color(0xFF1B3B22);    // Dark green background
  static const Color darkSoftRed = Color(0xFFE57373);      // Accessible red on dark
  static const Color darkSoftRedBg = Color(0xFF3B1C1C);    // Dark red background
  static const Color darkInfoTeal = Color(0xFF4DB6AC);     // Accessible teal on dark
  static const Color darkInfoBg = Color(0xFF163333);       // Dark teal background

  // ─── Compile-Time Opacity Constants ────────────────────────────────────────
  // To avoid const evaluation errors, opacities of the 5 colors must be static 
  static const Color parchment10 = Color(0x1AF5F0E8);
  static const Color parchment24 = Color(0x3DF5F0E8);
  static const Color parchment54 = Color(0x8AF5F0E8);
  static const Color parchment60 = Color(0x99F5F0E8);
  static const Color parchment70 = Color(0xB3F5F0E8);

  static const Color charcoal12 = Color(0x1F1A1A1A);
  static const Color charcoal26 = Color(0x421A1A1A);
  static const Color charcoal38 = Color(0x611A1A1A);
  static const Color charcoal40 = Color(0x661A1A1A);
  static const Color charcoal45 = Color(0x731A1A1A);
  static const Color charcoal54 = Color(0x8A1A1A1A);
  static const Color charcoal60 = Color(0x991A1A1A);
  static const Color charcoal70 = Color(0xB31A1A1A);
  static const Color charcoal87 = Color(0xDD1A1A1A);

  static const Color rawEarth12 = Color(0x1F6B4226);
  static const Color rawEarth26 = Color(0x426B4226);
  static const Color rawEarth54 = Color(0x8A6B4226);
  static const Color rawEarth70 = Color(0xB36B4226);

  static const Color harvestAmber40 = Color(0x66C9943A);

  // ─── Semantic Aliases for Backward Compatibility ──────────────────────────
  static const Color primaryColor = deepSoilGreen;  // Primary brand color
  static const Color error = softRed;               // Error/negative action color

  // ─── Border Radius Presets ─────────────────────────────────────────────────
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusRound = 30.0;

  // ─── Animation Durations (ms) ──────────────────────────────────────────────
  static const int animFast = 150;
  static const int animMedium = 200;
  static const int animSlow = 300;

  // ─── Shadow Opacity ────────────────────────────────────────────────────────
  static const double shadowOpacityLight = 0.05;
  static const double shadowOpacityMedium = 0.1;
  static const double shadowOpacityHeavy = 0.15;

  // ─── Spacing Core System ───────────────────────────────────────────────────
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 12.0;
  static const double spacingL = 16.0;
  static const double spacingXL = 24.0;
  static const double spacingXXL = 32.0;
}
