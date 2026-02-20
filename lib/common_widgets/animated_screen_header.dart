import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:grocery_app/common_widgets/floating_particle.dart';
import 'package:grocery_app/common_widgets/glassmorphic_icon_button.dart';

class AnimatedScreenHeader extends StatefulWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final bool showBack;
  final bool hasParticles;
  final double? height;
  final AnimationController? animationController;
  final bool centerTitle;

  const AnimatedScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.onBack,
    this.actions,
    this.showBack = true,
    this.hasParticles = false,
    this.height,
    this.animationController,
    this.centerTitle = false,
  });

  @override
  State<AnimatedScreenHeader> createState() => _AnimatedScreenHeaderState();
}

class _AnimatedScreenHeaderState extends State<AnimatedScreenHeader>
    with TickerProviderStateMixin {
  late AnimationController _localController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late AnimationController _particleController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    // Use provided controller or create local one
    _localController =
        widget.animationController ??
        AnimationController(
          duration: const Duration(milliseconds: 800),
          vsync: this,
        );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _localController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: -20.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _localController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    if (widget.hasParticles) {
      _particleController = AnimationController(
        duration: const Duration(seconds: 10),
        vsync: this,
      )..repeat();
    }

    _pulseController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    if (widget.animationController == null) {
      _localController.forward();
    }
  }

  @override
  void dispose() {
    if (widget.animationController == null) {
      _localController.dispose();
    }
    if (widget.hasParticles) {
      _particleController.dispose();
    }
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);
    final statusBarHeight = mediaQuery.padding.top;
    final screenHeight = mediaQuery.size.height;

    // Dynamic header height calculation if not provided
    final calculatedHeight =
        widget.height ??
        (statusBarHeight + 140).clamp(
          180.0,
          math.max(180.0, screenHeight * 0.28).toDouble(),
        );

    return AnimatedBuilder(
      animation: _localController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(opacity: _fadeAnimation.value, child: child),
        );
      },
      child: Container(
        height: calculatedHeight,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withOpacity(0.85),
              isDark
                  ? theme.colorScheme.primary.withOpacity(0.7)
                  : Colors.green.shade400,
            ],
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Floating Particles
            if (widget.hasParticles)
              ...List.generate(
                10,
                (index) => FloatingParticle(
                  index: index,
                  controller: _particleController,
                  areaHeight: calculatedHeight,
                  maxSize: 10,
                  swayX: 25,
                  swayY: 15,
                ),
              ),

            // Decorative circles
            Positioned(
              top: -30,
              right: -30,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 + (_pulseController.value * 0.1),
                    child: child,
                  );
                },
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: -40,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),

            // Header Content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row with Back Button, Title (if centered), and Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (widget.showBack && Navigator.canPop(context))
                          GlassmorphicIconButton(
                            icon: Icons.arrow_back_ios_new_rounded,
                            onTap:
                                widget.onBack ??
                                () {
                                  HapticFeedback.lightImpact();
                                  Navigator.pop(context);
                                },
                          )
                        else
                          const SizedBox(width: 44),

                        if (widget.centerTitle)
                          Expanded(
                            child: Text(
                              widget.title,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                        if (widget.actions != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: widget.actions!,
                          )
                        else if (widget.centerTitle)
                          const SizedBox(width: 44) // Balance the back button
                        else
                          const SizedBox.shrink(),
                      ],
                    ),
                    if (!widget.centerTitle) ...[
                      const Spacer(),
                      // Title Row (Bottom)
                      Row(
                        children: [
                          if (widget.icon != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                widget.icon,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                          ],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.title,
                                  style: theme.textTheme.headlineMedium
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                if (widget.subtitle != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.subtitle!,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
