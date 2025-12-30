import 'dart:ui';
import 'package:flutter/material.dart';

/// A reusable glassmorphic container with backdrop blur effect.
/// 
/// Consolidates the common BackdropFilter + Container pattern used in:
/// - App bars
/// - Cards
/// - Overlays
/// - Badges
/// 
/// Usage:
/// ```dart
/// GlassmorphicContainer(
///   child: YourContent(),
/// )
/// ```
class GlassmorphicContainer extends StatelessWidget {
  /// The child widget
  final Widget child;
  
  /// Blur sigma value (default: 10)
  final double blurSigma;
  
  /// Background color opacity (default: 0.2)
  final double opacity;
  
  /// Border radius (default: 20)
  final double borderRadius;
  
  /// Padding inside the container
  final EdgeInsetsGeometry? padding;
  
  /// Margin around the container
  final EdgeInsetsGeometry? margin;
  
  /// Border color (default: white with 0.3 opacity)
  final Color? borderColor;
  
  /// Border width (default: 1.5)
  final double borderWidth;
  
  /// Background color (will be applied with opacity)
  final Color? backgroundColor;
  
  /// Custom decoration to merge with glassmorphic effect
  final BoxDecoration? decoration;
  
  /// Width of the container
  final double? width;
  
  /// Height of the container
  final double? height;

  const GlassmorphicContainer({
    super.key,
    required this.child,
    this.blurSigma = 10,
    this.opacity = 0.2,
    this.borderRadius = 20,
    this.padding,
    this.margin,
    this.borderColor,
    this.borderWidth = 1.5,
    this.backgroundColor,
    this.decoration,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = backgroundColor ?? (isDark ? Colors.white : Colors.black);
    final border = borderColor ?? Colors.white.withOpacity(0.3);
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          width: width,
          height: height,
          margin: margin,
          padding: padding,
          decoration: BoxDecoration(
            color: bgColor.withOpacity(opacity),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: border,
              width: borderWidth,
            ),
          ).copyWith(
            gradient: decoration?.gradient,
            boxShadow: decoration?.boxShadow,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Light preset for glassmorphic containers
class GlassmorphicLight extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;

  const GlassmorphicLight({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return GlassmorphicContainer(
      opacity: 0.15,
      blurSigma: 8,
      borderRadius: borderRadius,
      padding: padding,
      backgroundColor: Colors.white,
      borderColor: Colors.white.withOpacity(0.2),
      child: child,
    );
  }
}

/// Dark preset for glassmorphic containers
class GlassmorphicDark extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;

  const GlassmorphicDark({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return GlassmorphicContainer(
      opacity: 0.3,
      blurSigma: 15,
      borderRadius: borderRadius,
      padding: padding,
      backgroundColor: Colors.black,
      borderColor: Colors.white.withOpacity(0.1),
      child: child,
    );
  }
}
