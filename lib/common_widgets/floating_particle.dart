import 'package:grocery_app/core/theme/app_colors.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:grocery_app/core/theme/theme.dart';

/// A reusable floating particle widget for animated screen headers.
///
/// Replaces the `_buildFloatingParticle` method that was duplicated in 13+ screens.
///
/// Usage:
/// ```dart
/// Stack(
///   children: [
///     ...List.generate(8, (i) => FloatingParticle(
///       index: i,
///       controller: _particleController,
///     )),
///   ],
/// )
/// ```
class FloatingParticle extends StatelessWidget {
  /// Index of this particle (used for deterministic randomization)
  final int index;

  /// Animation controller driving the particle motion
  final Animation<double> controller;

  /// Maximum horizontal spread area
  final double areaWidth;

  /// Maximum vertical spread area
  final double areaHeight;

  /// Maximum particle size
  final double maxSize;

  /// Minimum particle size
  final double minSize;

  /// Horizontal sway amplitude
  final double swayX;

  /// Vertical sway amplitude
  final double swayY;

  /// Particle color (defaults to white)
  final Color color;

  const FloatingParticle({
    super.key,
    required this.index,
    required this.controller,
    this.areaWidth = 400,
    this.areaHeight = 220,
    this.maxSize = 12,
    this.minSize = 4,
    this.swayX = 30,
    this.swayY = 20,
    this.color = AppColors.parchment,
  });

  @override
  Widget build(BuildContext context) {
    final random = math.Random(index);
    final size = minSize + random.nextDouble() * (maxSize - minSize);
    final startX = random.nextDouble() * areaWidth;
    final startY = random.nextDouble() * areaHeight;
    final duration = 10 + random.nextInt(10);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final progress = (controller.value * duration) % 1.0;
        final x = startX + math.sin(progress * math.pi * 2 + index) * swayX;
        final y = startY + math.cos(progress * math.pi * 2 + index) * swayY;
        final opacity = 0.1 + (math.sin(progress * math.pi * 2) * 0.15);

        return Positioned(
          left: x,
          top: y,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: opacity.clamp(0.05, 0.3)),
            ),
          ),
        );
      },
    );
  }
}
