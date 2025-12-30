import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A reusable modern back button for app bars.
/// 
/// Consolidates the common back button pattern used across app bars.
/// 
/// Usage:
/// ```dart
/// ModernBackButton(
///   onPressed: () => Navigator.pop(context),
/// )
/// ```
class ModernBackButton extends StatelessWidget {
  /// Callback when the button is pressed (defaults to Navigator.pop)
  final VoidCallback? onPressed;
  
  /// Icon to display (default: arrow_back_ios_new_rounded)
  final IconData icon;
  
  /// Icon color (auto-detected from theme if not provided)
  final Color? iconColor;
  
  /// Background color (auto-detected from theme if not provided)
  final Color? backgroundColor;
  
  /// Border radius (default: 12)
  final double borderRadius;
  
  /// Size of the button (default: 40)
  final double size;
  
  /// Icon size (default: 20)
  final double iconSize;
  
  /// Whether to trigger haptic feedback (default: true)
  final bool enableHaptic;
  
  /// For use on gradient/image backgrounds
  final bool forLightBackground;

  const ModernBackButton({
    super.key,
    this.onPressed,
    this.icon = Icons.arrow_back_ios_new_rounded,
    this.iconColor,
    this.backgroundColor,
    this.borderRadius = 12,
    this.size = 40,
    this.iconSize = 20,
    this.enableHaptic = true,
    this.forLightBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final bgColor = backgroundColor ?? 
        (forLightBackground
            ? Colors.white.withOpacity(0.9)
            : (isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)));
    
    final fgColor = iconColor ?? 
        (forLightBackground
            ? theme.colorScheme.primary
            : (isDark ? Colors.white : Colors.black87));
    
    return GestureDetector(
      onTap: () {
        if (enableHaptic) {
          HapticFeedback.lightImpact();
        }
        if (onPressed != null) {
          onPressed!();
        } else {
          Navigator.of(context).pop();
        }
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Icon(
          icon,
          color: fgColor,
          size: iconSize,
        ),
      ),
    );
  }
}

/// A close button variant of ModernBackButton
class ModernCloseButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color? iconColor;
  final Color? backgroundColor;
  final double size;
  final bool forLightBackground;

  const ModernCloseButton({
    super.key,
    this.onPressed,
    this.iconColor,
    this.backgroundColor,
    this.size = 40,
    this.forLightBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    return ModernBackButton(
      onPressed: onPressed,
      icon: Icons.close_rounded,
      iconColor: iconColor,
      backgroundColor: backgroundColor,
      size: size,
      forLightBackground: forLightBackground,
    );
  }
}

/// App bar action button with consistent styling
class ModernActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? iconColor;
  final Color? backgroundColor;
  final double size;
  final double iconSize;
  final bool forLightBackground;
  final String? tooltip;
  final Widget? badge;

  const ModernActionButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.iconColor,
    this.backgroundColor,
    this.size = 40,
    this.iconSize = 22,
    this.forLightBackground = false,
    this.tooltip,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final bgColor = backgroundColor ?? 
        (forLightBackground
            ? Colors.white.withOpacity(0.9)
            : (isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)));
    
    final fgColor = iconColor ?? 
        (forLightBackground
            ? theme.colorScheme.primary
            : (isDark ? Colors.white : Colors.black87));
    
    Widget button = GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onPressed?.call();
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: fgColor,
          size: iconSize,
        ),
      ),
    );
    
    if (badge != null) {
      button = Stack(
        clipBehavior: Clip.none,
        children: [
          button,
          Positioned(
            right: -4,
            top: -4,
            child: badge!,
          ),
        ],
      );
    }
    
    if (tooltip != null) {
      return Tooltip(
        message: tooltip!,
        child: button,
      );
    }
    
    return button;
  }
}
