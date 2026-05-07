import 'package:flutter/material.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// BuildContext Extensions — Ergonomic shortcuts to theme properties.
///
/// Usage:
///   context.text          → TextTheme
///   context.colors        → ColorScheme
///   context.theme         → ThemeData
///   context.isDark        → bool
///   context.screenWidth   → double
///   context.screenHeight  → double
///
/// These eliminate verbose `Theme.of(context).textTheme` calls.
/// ═══════════════════════════════════════════════════════════════════════════
extension ThemeExtensions on BuildContext {
  /// Full ThemeData. Use when you need direct access to component themes.
  ThemeData get theme => Theme.of(this);

  /// Quick access to TextTheme — use for all text styling.
  TextTheme get text => Theme.of(this).textTheme;

  /// Quick access to ColorScheme — theme-aware colors (light/dark).
  ColorScheme get colors => Theme.of(this).colorScheme;

  /// Whether the current theme brightness is dark.
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  /// Screen width via MediaQuery.
  double get screenWidth => MediaQuery.sizeOf(this).width;

  /// Screen height via MediaQuery.
  double get screenHeight => MediaQuery.sizeOf(this).height;

  /// Top safe-area padding (status bar height).
  double get topPadding => MediaQuery.paddingOf(this).top;

  /// Bottom safe-area padding (navigation bar / home indicator).
  double get bottomPadding => MediaQuery.paddingOf(this).bottom;
}
