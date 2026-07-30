import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grocery_app/core/theme/app_colors.dart';
import 'dashboard_navigation_bar.dart';

class DockNavItem extends StatefulWidget {
  final NavigatorItem item;
  final bool isActive;
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  final bool isDark;
  final int currentIndex;
  final int itemIndex;
  final double pageOffset;

  const DockNavItem({
    super.key,
    required this.item,
    required this.isActive,
    required this.onTap,
    required this.colorScheme,
    required this.isDark,
    required this.currentIndex,
    required this.itemIndex,
    required this.pageOffset,
  });

  @override
  State<DockNavItem> createState() => _DockNavItemState();
}

class _DockNavItemState extends State<DockNavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _pressAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _pressAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  double _calculateDockScale() {
    final distance = (widget.pageOffset - widget.itemIndex).abs();
    if (distance <= 0.1) return 1.15;
    if (distance <= 1.1) {
      final proximity = 1.0 - ((distance - 0.1) / 1.0);
      return 1.0 + (0.08 * proximity);
    }
    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    final dockScale = _calculateDockScale();

    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) {
        _pressController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _pressController.reverse(),
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _pressAnimation,
        builder: (context, child) {
          return Transform.scale(scale: _pressAnimation.value, child: child);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                tween: Tween(begin: 1.0, end: dockScale),
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: widget.isActive
                            ? AppColors.parchment.withValues(alpha: 0.12)
                            : AppColors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        widget.isActive
                            ? widget.item.activeIcon
                            : widget.item.icon,
                        color: widget.isActive
                            ? (widget.isDark
                                ? AppColors.harvestAmber
                                : AppColors.deepSoilGreen)
                            : (widget.isDark
                                ? AppColors.parchment.withValues(alpha: 0.4)
                                : AppColors.rawEarth70),
                        size: 22,
                      ),
                    ),
                  );
                },
              ),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: widget.isActive ? 1.0 : 0.6,
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: widget.isActive ? 10 : 9,
                    fontWeight:
                        widget.isActive ? FontWeight.w600 : FontWeight.w500,
                    color: widget.isActive
                        ? (widget.isDark
                            ? AppColors.harvestAmber
                            : AppColors.deepSoilGreen)
                        : (widget.isDark
                            ? AppColors.parchment.withValues(alpha: 0.4)
                            : AppColors.rawEarth70),
                    letterSpacing: widget.isActive ? 0.3 : 0,
                  ),
                  child: Text(widget.item.label),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DockCartNavItem extends StatelessWidget {
  final NavigatorItem item;
  final bool isActive;
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  final bool isDark;
  final int itemIndex;
  final double pageOffset;
  final int cartCount;

  const DockCartNavItem({
    super.key,
    required this.item,
    required this.isActive,
    required this.onTap,
    required this.colorScheme,
    required this.isDark,
    required this.itemIndex,
    required this.pageOffset,
    required this.cartCount,
  });

  @override
  Widget build(BuildContext context) {
    return const Expanded(
      child: SizedBox(width: 48),
    );
  }
}

class BuildCenterFab extends StatelessWidget {
  final AnimationController bounceController;
  final bool isCartActive;
  final VoidCallback onTap;
  final bool isDark;
  final int cartCount;

  const BuildCenterFab({
    super.key,
    required this.bounceController,
    required this.isCartActive,
    required this.onTap,
    required this.isDark,
    required this.cartCount,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 1.0, end: 1.12).animate(
        CurvedAnimation(parent: bounceController, curve: Curves.elasticOut),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isCartActive
                  ? [
                      AppColors.harvestAmber,
                      AppColors.harvestAmber.withValues(alpha: 0.85),
                    ]
                  : [
                      AppColors.deepSoilGreen,
                      AppColors.rawEarth,
                    ],
            ),
            boxShadow: [
              BoxShadow(
                color: (isCartActive
                        ? AppColors.harvestAmber
                        : AppColors.deepSoilGreen)
                    .withValues(alpha: 0.45),
                blurRadius: 14,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: AppColors.parchment, width: 2.5),
          ),
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Icon(
                isCartActive
                    ? Icons.shopping_cart_rounded
                    : Icons.shopping_cart_outlined,
                color: isCartActive
                    ? AppColors.deepSoilGreen
                    : AppColors.parchment,
                size: 24,
              ),
              if (cartCount > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: AnimatedBadge(count: cartCount),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class AnimatedBadge extends StatefulWidget {
  final int count;
  const AnimatedBadge({super.key, required this.count});

  @override
  State<AnimatedBadge> createState() => _AnimatedBadgeState();
}

class _AnimatedBadgeState extends State<AnimatedBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  int _previousCount = 0;

  @override
  void initState() {
    super.initState();
    _previousCount = widget.count;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 0.9), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(AnimatedBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.count != _previousCount) {
      _previousCount = widget.count;
      _controller.forward(from: 0);
      HapticFeedback.lightImpact();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.rawEarth,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.parchment, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.rawEarth.withValues(alpha: 0.3),
                  blurRadius: 6,
                  spreadRadius: 0,
                ),
              ],
            ),
            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
            child: Text(
              widget.count > 99 ? '99+' : widget.count.toString(),
              style: const TextStyle(
                color: AppColors.parchment,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }
}
