import 'package:grocery_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:grocery_app/core/theme/theme.dart';

/// A glassmorphic icon button used in animated screen headers.
///
/// Replaces the `_buildIconButton` method that was duplicated across multiple screens.
///
/// Usage:
/// ```dart
/// GlassmorphicIconButton(
///   icon: Icons.notifications_none_rounded,
///   onTap: () => Navigator.push(...),
/// )
/// ```
class GlassmorphicIconButton extends StatelessWidget {
  /// The icon to display
  final IconData icon;

  /// Callback when tapped
  final VoidCallback onTap;

  /// Background opacity (default: 0.2)
  final double backgroundOpacity;

  /// Icon color (default: white)
  final Color iconColor;

  /// Icon size (default: 24)
  final double iconSize;

  /// Border radius (default: 12)
  final double borderRadius;

  /// Padding around the icon (default: 10)
  final double padding;

  const GlassmorphicIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.backgroundOpacity = 0.2,
    this.iconColor = AppColors.parchment,
    this.iconSize = 24,
    this.borderRadius = AppColors.radiusM,
    this.padding = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.parchment.withValues(alpha: backgroundOpacity),
      borderRadius: BorderRadius.circular(borderRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Icon(icon, color: iconColor, size: iconSize),
        ),
      ),
    );
  }
}
