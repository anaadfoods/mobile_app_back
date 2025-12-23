import 'package:flutter/material.dart';

// Breakpoints for different screen sizes
const double kTabletBreakpoint = 768.0;
const double kDesktopBreakpoint = 1200.0;

class ResponsiveHelper {
  final BuildContext context;
  final BoxConstraints constraints;

  ResponsiveHelper(this.context, this.constraints);

  // Getters to check the current screen type
  bool get isMobile => constraints.maxWidth < kTabletBreakpoint;
  bool get isTablet => constraints.maxWidth >= kTabletBreakpoint && constraints.maxWidth < kDesktopBreakpoint;
  bool get isDesktop => constraints.maxWidth >= kDesktopBreakpoint;

  // Generic method to return a value based on screen size
  T value<T>({required T mobile, T? tablet, T? desktop}) {
    if (isDesktop && desktop != null) return desktop;
    if (isTablet && tablet != null) return tablet;
    return mobile;
  }

  // Common responsive values you can use throughout your app
  
  // FONT SIZES
  double get headline1 => value(mobile: 22, tablet: 26);
  double get headline2 => value(mobile: 20, tablet: 24);
  double get headline3 => value(mobile: 18, tablet: 22);
  double get bodyText1 => value(mobile: 14, tablet: 16);
  double get bodyText2 => value(mobile: 12, tablet: 14);
  double get smallText => value(mobile: 10, tablet: 12);

  // PADDING & MARGINS
  double get screenPadding => value(mobile: 16, tablet: 24);
  double get cardMarginVertical => value(mobile: 12, tablet: 16);
  
  // SPACING
  double get S => value(mobile: 8, tablet: 10);
  double get M => value(mobile: 16, tablet: 20);
  double get L => value(mobile: 24, tablet: 32);

  // GRID/LAYOUT
  int get categoryCrossAxisCount => value(mobile: 2, tablet: 3, desktop: 4);

  Null get screenHeight => null;
}