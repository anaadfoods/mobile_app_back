import 'package:flutter/material.dart';

/// Centralized animation constants for consistent animations across the app.
/// 
/// Usage:
/// ```dart
/// AnimatedContainer(
///   duration: AppAnimations.fast,
///   curve: AppAnimations.defaultCurve,
/// )
/// ```
class AppAnimations {
  AppAnimations._();
  
  // ============ DURATIONS ============
  
  /// Very fast animations (100ms) - micro-interactions, button presses
  static const Duration fastest = Duration(milliseconds: 100);
  
  /// Fast animations (150ms) - button feedback, small transitions
  static const Duration fast = Duration(milliseconds: 150);
  
  /// Medium animations (300ms) - page transitions, card animations
  static const Duration medium = Duration(milliseconds: 300);
  
  /// Slow animations (500ms) - complex transitions, emphasis
  static const Duration slow = Duration(milliseconds: 500);
  
  /// Very slow animations (800ms) - entrance animations, hero transitions
  static const Duration slowest = Duration(milliseconds: 800);
  
  /// Standard stagger delay between items
  static const Duration staggerDelay = Duration(milliseconds: 50);
  
  // ============ CURVES ============
  
  /// Default curve for most animations
  static const Curve defaultCurve = Curves.easeInOut;
  
  /// Curve for entrance animations
  static const Curve entranceCurve = Curves.easeOutCubic;
  
  /// Curve for exit animations
  static const Curve exitCurve = Curves.easeInCubic;
  
  /// Curve for bounce effects
  static const Curve bounceCurve = Curves.elasticOut;
  
  /// Curve for overshoot effects
  static const Curve overshootCurve = Curves.easeOutBack;
  
  /// Curve for smooth deceleration
  static const Curve decelerateCurve = Curves.decelerate;
  
  // ============ SCALE VALUES ============
  
  /// Scale when pressed (default tap feedback)
  static const double pressedScale = 0.98;
  
  /// Scale when pressed (stronger feedback)
  static const double pressedScaleStrong = 0.95;
  
  /// Scale for entrance animations
  static const double entranceScale = 0.95;
  
  // ============ HELPERS ============
  
  /// Calculate staggered duration based on index
  static Duration staggered(int index, {Duration base = medium}) {
    return Duration(
      milliseconds: base.inMilliseconds + (index * staggerDelay.inMilliseconds),
    );
  }
  
  /// Calculate staggered delay for list items
  static Duration staggeredDelay(int index) {
    return Duration(milliseconds: index * staggerDelay.inMilliseconds);
  }
}

/// Centralized decoration constants for consistent styling across the app.
/// 
/// Usage:
/// ```dart
/// Container(
///   decoration: AppDecorations.cardDecoration(context),
/// )
/// ```
class AppDecorations {
  AppDecorations._();
  
  // ============ BORDER RADIUS ============
  
  static const double radiusXS = 4;
  static const double radiusS = 8;
  static const double radiusM = 12;
  static const double radiusL = 16;
  static const double radiusXL = 20;
  static const double radiusXXL = 24;
  static const double radiusRound = 100;
  
  // ============ SHADOWS ============
  
  /// Light shadow for cards
  static List<BoxShadow> shadowLight(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: (isDark ? Colors.black : Colors.black).withOpacity(isDark ? 0.3 : 0.08),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ];
  }
  
  /// Medium shadow for elevated elements
  static List<BoxShadow> shadowMedium(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: (isDark ? Colors.black : Colors.black).withOpacity(isDark ? 0.4 : 0.12),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
    ];
  }
  
  /// Strong shadow for floating elements
  static List<BoxShadow> shadowStrong(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: (isDark ? Colors.black : Colors.black).withOpacity(isDark ? 0.5 : 0.16),
        blurRadius: 24,
        offset: const Offset(0, 8),
      ),
    ];
  }
  
  /// Colored shadow with primary color
  static List<BoxShadow> shadowColored(BuildContext context, {Color? color}) {
    final primaryColor = color ?? Theme.of(context).colorScheme.primary;
    return [
      BoxShadow(
        color: primaryColor.withOpacity(0.3),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
    ];
  }
  
  // ============ CARD DECORATIONS ============
  
  /// Standard card decoration
  static BoxDecoration card(BuildContext context, {bool elevated = false}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return BoxDecoration(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(radiusL),
      border: Border.all(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        width: 1,
      ),
      boxShadow: elevated ? shadowMedium(context) : shadowLight(context),
    );
  }
  
  /// Gradient card decoration
  static BoxDecoration gradientCard({
    required List<Color> colors,
    double borderRadius = radiusXL,
    List<BoxShadow>? boxShadow,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
      ),
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: boxShadow,
    );
  }
  
  /// Outlined card decoration
  static BoxDecoration outlinedCard(BuildContext context, {Color? borderColor}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return BoxDecoration(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(radiusL),
      border: Border.all(
        color: borderColor ?? (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
        width: 1.5,
      ),
    );
  }
  
  // ============ GRADIENTS ============
  
  /// Primary gradient using theme colors
  static LinearGradient primaryGradient(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        colorScheme.primary,
        colorScheme.primary.withOpacity(0.8),
        colorScheme.secondary.withOpacity(0.6),
      ],
    );
  }
  
  /// Success gradient (green)
  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
  );
  
  /// Warning gradient (orange/yellow)
  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
  );
  
  /// Error gradient (red)
  static const LinearGradient errorGradient = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
  );
  
  /// Info gradient (blue)
  static const LinearGradient infoGradient = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
  );
  
  /// Purple gradient
  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
  );
}
