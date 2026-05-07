import 'package:grocery_app/core/theme/app_colors.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grocery_app/core/theme/theme.dart';

/// A modern, animated bottom sheet wrapper with floating particles and glassmorphism effects
class ModernBottomSheet extends StatefulWidget {
  final Widget child;
  final String? title;
  final String? subtitle;
  final IconData? headerIcon;
  final Color? accentColor;
  final bool showParticles;
  final bool showGradientHeader;
  final double? maxHeight;

  const ModernBottomSheet({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.headerIcon,
    this.accentColor,
    this.showParticles = true,
    this.showGradientHeader = false,
    this.maxHeight,
  });

  @override
  State<ModernBottomSheet> createState() => _ModernBottomSheetState();

  /// Show a modern bottom sheet with animations
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    String? subtitle,
    IconData? headerIcon,
    Color? accentColor,
    bool showParticles = true,
    bool showGradientHeader = false,
    double? maxHeight,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    HapticFeedback.lightImpact();

    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: AppColors.transparent,
      barrierColor: AppColors.charcoal.withValues(alpha: 0.5),
      builder:
          (context) => ModernBottomSheet(
            title: title,
            subtitle: subtitle,
            headerIcon: headerIcon,
            accentColor: accentColor,
            showParticles: showParticles,
            showGradientHeader: showGradientHeader,
            maxHeight: maxHeight,
            child: child,
          ),
    );
  }
}

class _ModernBottomSheetState extends State<ModernBottomSheet>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _particleController;
  late AnimationController _glowController;

  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _particleController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat();

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _particleController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accentColor = widget.accentColor ?? theme.colorScheme.primary;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: widget.maxHeight ?? screenHeight * 0.85,
          ),
          margin: EdgeInsets.only(bottom: bottomPadding),
          decoration: BoxDecoration(
            color: isDark ? AppColors.deepSoilGreen : AppColors.pureWhite,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.15),
                blurRadius: 30,
                offset: const Offset(0, -10),
              ),
              BoxShadow(
                color: AppColors.charcoal.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: Stack(
              children: [
                // Animated glow effect at top
                if (widget.showGradientHeader)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: AnimatedBuilder(
                      animation: _glowController,
                      builder: (context, child) {
                        return Container(
                          height: 120,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                accentColor.withValues(
                                  alpha: _glowAnimation.value * 0.4,
                                ),
                                accentColor.withValues(
                                  alpha: _glowAnimation.value * 0.1,
                                ),
                                AppColors.transparent,
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                // Floating particles
                if (widget.showParticles)
                  ...List.generate(
                    6,
                    (index) => _buildFloatingParticle(index, accentColor),
                  ),

                // Content
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle bar with glow
                    _buildHandleBar(theme, isDark, accentColor),

                    // Header if provided
                    if (widget.title != null)
                      _buildHeader(theme, isDark, accentColor),

                    // Child content
                    Flexible(child: widget.child),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHandleBar(ThemeData theme, bool isDark, Color accentColor) {
    return Container(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: AnimatedBuilder(
        animation: _glowController,
        builder: (context, child) {
          return Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accentColor.withValues(alpha: 0.3),
                  accentColor.withValues(alpha: 0.6),
                  accentColor.withValues(alpha: 0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(3),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(
                    alpha: _glowAnimation.value * 0.5,
                  ),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Row(
        children: [
          if (widget.headerIcon != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accentColor.withValues(alpha: 0.2),
                    accentColor.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: accentColor.withValues(alpha: 0.3)),
              ),
              child: Icon(widget.headerIcon, color: accentColor, size: 24),
            ),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title!,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingParticle(int index, Color accentColor) {
    final random = math.Random(index * 42);
    final size = 3.0 + random.nextDouble() * 5;
    final startX = random.nextDouble() * 400;
    final startY = random.nextDouble() * 150;

    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        final progress = (_particleController.value + index * 0.1) % 1.0;
        final x = startX + math.sin(progress * math.pi * 2) * 20;
        final y = startY + math.cos(progress * math.pi * 2) * 15;
        final opacity = 0.1 + math.sin(progress * math.pi * 2) * 0.15;

        return Positioned(
          left: x,
          top: y,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor.withValues(alpha: opacity.clamp(0.05, 0.25)),
            ),
          ),
        );
      },
    );
  }
}

/// A modern selection option card for bottom sheets
class ModernSelectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? trailingText;
  final String? trailingSubtext;
  final IconData? icon;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback? onTap;
  final Color? accentColor;
  final Widget? expandedContent;

  const ModernSelectionCard({
    super.key,
    required this.title,
    this.subtitle,
    this.trailingText,
    this.trailingSubtext,
    this.icon,
    this.isSelected = false,
    this.isEnabled = true,
    this.onTap,
    this.accentColor,
    this.expandedContent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = accentColor ?? theme.colorScheme.primary;

    return GestureDetector(
      onTap:
          isEnabled
              ? () {
                HapticFeedback.selectionClick();
                onTap?.call();
              }
              : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient:
              isSelected
                  ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color, color.withValues(alpha: 0.85)],
                  )
                  : null,
          color:
              isSelected
                  ? null
                  : (isDark ? AppColors.charcoal : AppColors.parchment),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color:
                isSelected
                    ? color.withValues(alpha: 0.5)
                    : (isDark ? AppColors.charcoal87 : AppColors.parchment),
            width: isSelected ? 2 : 1,
          ),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                  : null,
        ),
        child: Opacity(
          opacity: isEnabled ? 1.0 : 0.5,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  // Selection indicator
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          isSelected
                              ? AppColors.parchment.withValues(alpha: 0.2)
                              : AppColors.transparent,
                      border: Border.all(
                        color:
                            isSelected
                                ? AppColors.parchment
                                : (isDark
                                    ? AppColors.rawEarth70
                                    : AppColors.rawEarth26),
                        width: 2,
                      ),
                    ),
                    child:
                        isSelected
                            ? const Icon(
                              Icons.check,
                              size: 14,
                              color: AppColors.parchment,
                            )
                            : null,
                  ),
                  const SizedBox(width: 14),

                  // Icon if provided
                  if (icon != null) ...[
                    Icon(
                      icon,
                      color: isSelected ? AppColors.parchment : color,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                  ],

                  // Title & Subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? AppColors.parchment : null,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color:
                                  isSelected
                                      ? AppColors.parchment.withValues(
                                        alpha: 0.8,
                                      )
                                      : theme.hintColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Trailing text
                  if (trailingText != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          trailingText!,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? AppColors.parchment : color,
                          ),
                        ),
                        if (trailingSubtext != null)
                          Text(
                            trailingSubtext!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color:
                                  isSelected
                                      ? AppColors.parchment.withValues(
                                        alpha: 0.7,
                                      )
                                      : theme.hintColor,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                      ],
                    ),
                ],
              ),

              // Expanded content
              if (expandedContent != null && isSelected)
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  child: expandedContent!,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A modern quantity selector for bottom sheets
class ModernQuantitySelector extends StatelessWidget {
  final int quantity;
  final ValueChanged<int> onChanged;
  final int minQuantity;
  final int maxQuantity;
  final Color? accentColor;

  const ModernQuantitySelector({
    super.key,
    required this.quantity,
    required this.onChanged,
    this.minQuantity = 1,
    this.maxQuantity = 99,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.charcoal87 : AppColors.parchment,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildButton(
            icon: Icons.remove,
            onTap:
                quantity > minQuantity ? () => onChanged(quantity - 1) : null,
            theme: theme,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '$quantity',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildButton(
            icon: Icons.add,
            onTap:
                quantity < maxQuantity ? () => onChanged(quantity + 1) : null,
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required IconData icon,
    required VoidCallback? onTap,
    required ThemeData theme,
  }) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap:
            onTap != null
                ? () {
                  HapticFeedback.selectionClick();
                  onTap();
                }
                : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 18,
            color:
                onTap != null ? theme.colorScheme.primary : theme.disabledColor,
          ),
        ),
      ),
    );
  }
}

/// A modern action button for bottom sheets
class ModernBottomSheetButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final IconData? icon;
  final Color? color;
  final bool isOutlined;

  const ModernBottomSheetButton({
    super.key,
    required this.label,
    this.onTap,
    this.isLoading = false,
    this.icon,
    this.color,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonColor = color ?? theme.colorScheme.primary;

    return GestureDetector(
      onTap:
          isLoading
              ? null
              : () {
                HapticFeedback.mediumImpact();
                onTap?.call();
              },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        decoration: BoxDecoration(
          gradient:
              isOutlined
                  ? null
                  : LinearGradient(
                    colors: [buttonColor, buttonColor.withValues(alpha: 0.85)],
                  ),
          color: isOutlined ? AppColors.transparent : null,
          borderRadius: BorderRadius.circular(16),
          border: isOutlined ? Border.all(color: buttonColor, width: 2) : null,
          boxShadow:
              isOutlined
                  ? null
                  : [
                    BoxShadow(
                      color: buttonColor.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
        ),
        child: Center(
          child:
              isLoading
                  ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: isOutlined ? buttonColor : AppColors.parchment,
                    ),
                  )
                  : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(
                          icon,
                          color: isOutlined ? buttonColor : AppColors.parchment,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                      ],
                      Text(
                        label,
                        style: TextStyle(
                          color: isOutlined ? buttonColor : AppColors.parchment,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
        ),
      ),
    );
  }
}
