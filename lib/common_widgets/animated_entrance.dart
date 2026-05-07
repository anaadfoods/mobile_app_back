import 'package:flutter/material.dart';

/// Reusable animated entrance widget for fade, scale, and slide animations.
///
/// Consolidates the common TweenAnimationBuilder pattern used for:
/// - Staggered list animations
/// - Fade-in effects
/// - Scale-in effects
/// - Slide-in effects
///
/// Usage:
/// ```dart
/// AnimatedEntrance(
///   index: 0, // for staggered delay
///   child: YourWidget(),
/// )
/// ```
class AnimatedEntrance extends StatelessWidget {
  /// The child widget to animate
  final Widget child;

  /// Index for staggered delay calculation (default: 0)
  final int index;

  /// Base duration for the animation (default: 400ms)
  final Duration baseDuration;

  /// Delay per item for staggered animations (default: 50ms)
  final Duration staggerDelay;

  /// Whether to apply fade animation (default: true)
  final bool fade;

  /// Whether to apply scale animation (default: false)
  final bool scale;

  /// Whether to apply vertical slide animation (default: true)
  final bool slideUp;

  /// Scale begin value (default: 0.95)
  final double scaleBegin;

  /// Slide offset in pixels (default: 20)
  final double slideOffset;

  /// Animation curve (default: Curves.easeOutCubic)
  final Curve curve;

  const AnimatedEntrance({
    super.key,
    required this.child,
    this.index = 0,
    this.baseDuration = const Duration(milliseconds: 400),
    this.staggerDelay = const Duration(milliseconds: 50),
    this.fade = true,
    this.scale = false,
    this.slideUp = true,
    this.scaleBegin = 0.95,
    this.slideOffset = 20,
    this.curve = Curves.easeOutCubic,
  });

  @override
  Widget build(BuildContext context) {
    final totalDuration = Duration(
      milliseconds:
          baseDuration.inMilliseconds + (index * staggerDelay.inMilliseconds),
    );

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: totalDuration,
      curve: curve,
      builder: (context, value, child) {
        Widget result = child!;

        if (slideUp) {
          result = Transform.translate(
            offset: Offset(0, slideOffset * (1 - value)),
            child: result,
          );
        }

        if (scale) {
          final scaleValue = scaleBegin + ((1.0 - scaleBegin) * value);
          result = Transform.scale(scale: scaleValue, child: result);
        }

        if (fade) {
          result = Opacity(opacity: value.clamp(0.0, 1.0), child: result);
        }

        return result;
      },
      child: child,
    );
  }
}

/// Predefined animation presets for common use cases
class AnimatedEntrancePresets {
  /// Fade and slide up - most common
  static AnimatedEntrance fadeSlideUp({required Widget child, int index = 0}) {
    return AnimatedEntrance(
      index: index,
      fade: true,
      slideUp: true,
      scale: false,
      child: child,
    );
  }

  /// Fade and scale - for cards
  static AnimatedEntrance fadeScale({required Widget child, int index = 0}) {
    return AnimatedEntrance(
      index: index,
      fade: true,
      slideUp: false,
      scale: true,
      child: child,
    );
  }

  /// All effects combined - for hero elements
  static AnimatedEntrance hero({required Widget child, int index = 0}) {
    return AnimatedEntrance(
      index: index,
      fade: true,
      slideUp: true,
      scale: true,
      baseDuration: const Duration(milliseconds: 600),
      child: child,
    );
  }
}
