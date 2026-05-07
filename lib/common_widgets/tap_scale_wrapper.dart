import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A reusable wrapper widget that provides tap-to-scale animation effect.
///
/// This widget consolidates the common pattern of:
/// - GestureDetector with onTapDown/onTapUp/onTapCancel
/// - AnimatedScale for press feedback
/// - Optional haptic feedback
///
/// Usage:
/// ```dart
/// TapScaleWrapper(
///   onTap: () => doSomething(),
///   child: YourWidget(),
/// )
/// ```
class TapScaleWrapper extends StatefulWidget {
  /// The child widget to wrap with tap-scale animation
  final Widget child;

  /// Callback when the widget is tapped
  final VoidCallback? onTap;

  /// The scale factor when pressed (default: 0.98)
  final double pressedScale;

  /// Animation duration (default: 150ms)
  final Duration duration;

  /// Animation curve (default: Curves.easeInOut)
  final Curve curve;

  /// Whether to trigger haptic feedback on tap (default: true)
  final bool enableHaptic;

  /// Type of haptic feedback (default: light)
  final HapticType hapticType;

  const TapScaleWrapper({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.98,
    this.duration = const Duration(milliseconds: 150),
    this.curve = Curves.easeInOut,
    this.enableHaptic = true,
    this.hapticType = HapticType.light,
  });

  @override
  State<TapScaleWrapper> createState() => _TapScaleWrapperState();
}

class _TapScaleWrapperState extends State<TapScaleWrapper> {
  bool _isPressed = false;

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    if (widget.enableHaptic) {
      _triggerHaptic();
    }
    widget.onTap?.call();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
  }

  void _triggerHaptic() {
    switch (widget.hapticType) {
      case HapticType.light:
        HapticFeedback.lightImpact();
        break;
      case HapticType.medium:
        HapticFeedback.mediumImpact();
        break;
      case HapticType.heavy:
        HapticFeedback.heavyImpact();
        break;
      case HapticType.selection:
        HapticFeedback.selectionClick();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed ? widget.pressedScale : 1.0,
        duration: widget.duration,
        curve: widget.curve,
        child: widget.child,
      ),
    );
  }
}

/// Types of haptic feedback available
enum HapticType { light, medium, heavy, selection }
