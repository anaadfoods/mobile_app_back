import 'package:flutter/material.dart';

/// A reusable "Coming Soon" badge widget with animation.
/// 
/// Consolidates the various coming soon badge implementations across the app.
/// 
/// Usage:
/// ```dart
/// ComingSoonBadge(
///   accentColor: Colors.purple,
/// )
/// ```
class ComingSoonBadge extends StatefulWidget {
  /// Accent color for the badge gradient
  final Color? accentColor;
  
  /// Secondary color for the gradient (optional)
  final Color? secondaryColor;
  
  /// Whether to animate with pulse effect (default: true)
  final bool animated;
  
  /// Badge text (default: 'COMING SOON')
  final String text;
  
  /// Whether to show the rocket icon (default: true)
  final bool showIcon;
  
  /// Icon to display (default: rocket_launch)
  final IconData icon;
  
  /// Size variant (default: medium)
  final ComingSoonBadgeSize size;

  const ComingSoonBadge({
    super.key,
    this.accentColor,
    this.secondaryColor,
    this.animated = true,
    this.text = 'COMING SOON',
    this.showIcon = true,
    this.icon = Icons.rocket_launch_rounded,
    this.size = ComingSoonBadgeSize.medium,
  });

  @override
  State<ComingSoonBadge> createState() => _ComingSoonBadgeState();
}

class _ComingSoonBadgeState extends State<ComingSoonBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (widget.animated) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = widget.accentColor ?? theme.colorScheme.primary;
    final secondary = widget.secondaryColor ?? primary.withOpacity(0.8);
    
    final config = _getSizeConfig();
    
    Widget badge = Container(
      padding: EdgeInsets.symmetric(
        horizontal: config.horizontalPadding,
        vertical: config.verticalPadding,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary, secondary],
        ),
        borderRadius: BorderRadius.circular(config.borderRadius),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showIcon) ...[
            Icon(
              widget.icon,
              size: config.iconSize,
              color: Colors.white,
            ),
            SizedBox(width: config.spacing),
          ],
          Text(
            widget.text,
            style: TextStyle(
              fontSize: config.fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
    
    if (widget.animated) {
      return AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: child,
          );
        },
        child: badge,
      );
    }
    
    return badge;
  }
  
  _BadgeSizeConfig _getSizeConfig() {
    switch (widget.size) {
      case ComingSoonBadgeSize.small:
        return _BadgeSizeConfig(
          horizontalPadding: 8,
          verticalPadding: 4,
          fontSize: 8,
          iconSize: 10,
          spacing: 3,
          borderRadius: 12,
        );
      case ComingSoonBadgeSize.medium:
        return _BadgeSizeConfig(
          horizontalPadding: 12,
          verticalPadding: 6,
          fontSize: 10,
          iconSize: 12,
          spacing: 4,
          borderRadius: 20,
        );
      case ComingSoonBadgeSize.large:
        return _BadgeSizeConfig(
          horizontalPadding: 16,
          verticalPadding: 8,
          fontSize: 12,
          iconSize: 14,
          spacing: 6,
          borderRadius: 25,
        );
    }
  }
}

/// Size variants for the coming soon badge
enum ComingSoonBadgeSize {
  small,
  medium,
  large,
}

class _BadgeSizeConfig {
  final double horizontalPadding;
  final double verticalPadding;
  final double fontSize;
  final double iconSize;
  final double spacing;
  final double borderRadius;
  
  const _BadgeSizeConfig({
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.fontSize,
    required this.iconSize,
    required this.spacing,
    required this.borderRadius,
  });
}

/// Simple non-animated version for inline use
class ComingSoonChip extends StatelessWidget {
  final Color? color;
  final String text;

  const ComingSoonChip({
    super.key,
    this.color,
    this.text = 'Soon',
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? Theme.of(context).colorScheme.primary;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: chipColor,
        ),
      ),
    );
  }
}

