import 'package:flutter/material.dart';
import 'package:grocery_app/core/theme/app_colors.dart';

/// Clean Gemini-style AI Processing Indicator Widget.
///
/// Displays "Formulating personalized response..." with a subtle pulsing icon
/// during initial thinking, and hides automatically as soon as AI begins writing text.
class ChatStageIndicator extends StatefulWidget {
  final bool isVisible;

  const ChatStageIndicator({Key? key, this.isVisible = false})
    : super(key: key);

  @override
  State<ChatStageIndicator> createState() => _ChatStageIndicatorState();
}

class _ChatStageIndicatorState extends State<ChatStageIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceElevated : AppColors.pureWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.harvestAmber.withValues(alpha: 0.35),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.harvestAmber.withValues(alpha: 0.15),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.harvestAmber,
                  size: 16,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              "Formulating personalized response...",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.harvestAmber,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
