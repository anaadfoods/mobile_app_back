import 'dart:math' as math;
import 'dart:ui';
import 'package:grocery_app/common_widgets/global_import.dart';
import 'navigator_item.dart';

class DashboardScreen extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const DashboardScreen({super.key, required this.navigationShell});

  @override
  DashboardScreenState createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _bounceController;
  late AnimationController _fabFloatController;
  bool _fabAnimationActive = true;

  // For double-back to exit
  DateTime? lastTimeBackPressed;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    // Floating animation for center FAB
    _fabFloatController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    WidgetsBinding.instance.addObserver(this);

    Future.delayed(const Duration(seconds: 6), () {
      if (mounted) {
        _fabAnimationActive = false;
        _fabFloatController.stop();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bounceController.dispose();
    _fabFloatController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _fabFloatController.stop();
    } else if (state == AppLifecycleState.resumed) {
      if (_fabAnimationActive) {
        _fabFloatController.repeat(reverse: true);
      }
    }
  }

  void _onTabChanged(int index) {
    if (index == widget.navigationShell.currentIndex) return;

    // Haptic feedback on tap
    HapticFeedback.selectionClick();

    // Trigger bounce animation
    _bounceController.forward(from: 0);

    // GoRouter handles the switch
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  /// Public method to switch tabs from child screens (kept for backward compatibility if accessed via key)
  void switchToTab(int index) {
    _onTabChanged(index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final currentIndex = widget.navigationShell.currentIndex;
    final pageOffset =
        currentIndex
            .toDouble(); // Approximated since there's no continuous scroll with ShellRoute

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        // Determine if we should exit the app when back button is pressed on Home tab
        if (widget.navigationShell.currentIndex == 0 && !context.canPop()) {
          final now = DateTime.now();
          final isWarning =
              lastTimeBackPressed == null ||
              now.difference(lastTimeBackPressed!) > const Duration(seconds: 2);

          if (isWarning) {
            lastTimeBackPressed = now;
            SnackBarHelper.showInfo(context, "Tap back again to exit 👋");
          } else {
            SystemNavigator.pop(); // Native exit since there is no route left
          }
        } else {
          // Otherwise let the router handle the back navigation (e.g pop nested route or go to home branch if on another tab)
          if (context.canPop()) {
            context.pop();
          } else {
            widget.navigationShell.goBranch(0); // Go back to home tab
          }
        }
      },
      child: Scaffold(
        body: widget.navigationShell,
        bottomNavigationBar: _PremiumBottomNavBar(
          currentIndex: currentIndex,
          onTabChanged: _onTabChanged,
          items: navigatorItems,
          isDark: isDark,
          colorScheme: colorScheme,
          bounceController: _bounceController,
          fabFloatController: _fabFloatController,
          pageOffset: pageOffset,
        ),
      ),
    );
  }
}

/// Custom clipper for wave-shaped navigation bar with center notch
class _WaveClipper extends CustomClipper<Path> {
  final double notchRadius;
  final double notchMargin;

  _WaveClipper({this.notchRadius = 28.0, this.notchMargin = 6.0});

  @override
  Path getClip(Size size) {
    final path = Path();
    final centerX = size.width / 2;
    final notchTotalRadius = notchRadius + notchMargin;

    // Start from top-left with wave curve
    path.moveTo(0, 16);

    // Left wave curve up
    path.quadraticBezierTo(0, 0, 16, 0);

    // Line to before notch
    path.lineTo(centerX - notchTotalRadius - 16, 0);

    // Smooth curve into notch
    path.quadraticBezierTo(
      centerX - notchTotalRadius,
      0,
      centerX - notchTotalRadius,
      6,
    );

    // Left side of notch curve
    path.arcToPoint(
      Offset(centerX - notchRadius + 4, notchTotalRadius - 4),
      radius: Radius.circular(notchRadius * 0.5),
      clockwise: false,
    );

    // Bottom of notch (arc around FAB)
    path.arcToPoint(
      Offset(centerX + notchRadius - 4, notchTotalRadius - 4),
      radius: Radius.circular(notchRadius + 4),
      clockwise: false,
    );

    // Right side of notch curve
    path.arcToPoint(
      Offset(centerX + notchTotalRadius, 6),
      radius: Radius.circular(notchRadius * 0.5),
      clockwise: false,
    );

    // Smooth curve out of notch
    path.quadraticBezierTo(
      centerX + notchTotalRadius,
      0,
      centerX + notchTotalRadius + 16,
      0,
    );

    // Line to top-right
    path.lineTo(size.width - 16, 0);

    // Right wave curve
    path.quadraticBezierTo(size.width, 0, size.width, 16);

    // Right edge
    path.lineTo(size.width, size.height);

    // Bottom edge
    path.lineTo(0, size.height);

    // Left edge back to start
    path.lineTo(0, 16);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(_WaveClipper oldClipper) =>
      notchRadius != oldClipper.notchRadius ||
      notchMargin != oldClipper.notchMargin;
}

/// Premium Bottom Navigation Bar with wave shape, floating FAB, and dock-style animations
class _PremiumBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabChanged;
  final List<NavigatorItem> items;
  final bool isDark;
  final ColorScheme colorScheme;
  final AnimationController bounceController;
  final AnimationController fabFloatController;
  final double pageOffset;

  const _PremiumBottomNavBar({
    required this.currentIndex,
    required this.onTabChanged,
    required this.items,
    required this.isDark,
    required this.colorScheme,
    required this.bounceController,
    required this.fabFloatController,
    required this.pageOffset,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Container(
      height: 75,
      margin: EdgeInsets.fromLTRB(12, 0, 12, 12 + bottomInset),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // Wave-shaped glass container
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipPath(
              clipper: _WaveClipper(notchRadius: 28, notchMargin: 6),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  height: 58,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors:
                          isDark
                              ? [
                                AppColors.darkSurface.withValues(alpha: 0.85),
                                AppColors.darkSurfaceElevated.withValues(alpha: 0.95),
                              ]
                              : [
                                AppColors.parchment.withValues(alpha: 0.85),
                                AppColors.parchment.withValues(alpha: 0.65),
                              ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            isDark
                                ? AppColors.charcoal.withValues(alpha: 0.4)
                                : AppColors.deepSoilGreen.withValues(
                                  alpha: 0.15,
                                ),
                        blurRadius: 50,
                        offset: const Offset(0, 20),
                        spreadRadius: -5,
                      ),
                      // Inner glow
                      BoxShadow(
                        color:
                            isDark
                                ? AppColors.parchment.withValues(alpha: 0.05)
                                : AppColors.parchment.withValues(alpha: 0.8),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                        spreadRadius: -10,
                      ),
                    ],
                  ),
                  child: CustomPaint(
                    painter: _GlassBorderPainter(isDark: isDark),
                    child: Stack(
                      children: [
                        // Navigation items (excluding center FAB)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(items.length, (index) {
                            if (items[index].isCenterFab) {
                              // Empty space for center FAB
                              return const Expanded(child: SizedBox());
                            }
                            return Expanded(
                              child: _DockNavItem(
                                item: items[index],
                                isActive: index == currentIndex,
                                onTap: () => onTabChanged(index),
                                colorScheme: colorScheme,
                                isDark: isDark,
                                currentIndex: currentIndex,
                                itemIndex: index,
                                pageOffset: pageOffset,
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Floating Center FAB
          Positioned(
            top: 5,
            child: _FloatingCartFab(
              item: items[centerFabIndex],
              isActive: currentIndex == centerFabIndex,
              onTap: () => onTabChanged(centerFabIndex),
              floatController: fabFloatController,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for glass border effect
class _GlassBorderPainter extends CustomPainter {
  final bool isDark;

  _GlassBorderPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors:
                isDark
                    ? [
                      AppColors.parchment.withValues(alpha: 0.15),
                      AppColors.parchment.withValues(alpha: 0.05),
                      AppColors.parchment.withValues(alpha: 0.02),
                    ]
                    : [
                      AppColors.parchment.withValues(alpha: 0.9),
                      AppColors.parchment.withValues(alpha: 0.5),
                      AppColors.parchment.withValues(alpha: 0.3),
                    ],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final clipper = _WaveClipper(notchRadius: 28, notchMargin: 6);
    final path = clipper.getClip(size);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_GlassBorderPainter oldDelegate) =>
      isDark != oldDelegate.isDark;
}

/// Floating Cart FAB with glow, badge, and floating animation
class _FloatingCartFab extends StatelessWidget {
  final NavigatorItem item;
  final bool isActive;
  final VoidCallback onTap;
  final AnimationController floatController;
  final bool isDark;

  const _FloatingCartFab({
    required this.item,
    required this.isActive,
    required this.onTap,
    required this.floatController,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: floatController,
      builder: (context, child) {
        // Gentle floating bob animation
        final floatOffset = math.sin(floatController.value * math.pi) * 2;

        return Transform.translate(
          offset: Offset(0, floatOffset),
          child: child,
        );
      },
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          onTap();
        },
        child: BlocBuilder<CartCubit, CartState>(
          builder: (context, cartState) {
            int itemCount = 0;
            if (cartState is CartSuccess) {
              itemCount = cartState.cart.totalItems;
            }

            return Stack(
              clipBehavior: Clip.none,
              children: [
                // Glow effect
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen).withValues(
                          alpha: isActive ? 0.5 : 0.25,
                        ),
                        blurRadius: isActive ? 20 : 12,
                        spreadRadius: isActive ? 1 : 0,
                      ),
                      if (isActive)
                        BoxShadow(
                        color: (isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen).withValues(alpha: 0.3),
                          blurRadius: 30,
                          spreadRadius: 3,
                        ),
                    ],
                  ),
                ),
                // FAB button
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutBack,
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                            AppColors.harvestAmber,
                            AppColors.harvestAmber.withValues(alpha: 0.85),
                          ]
                          : [
                            AppColors.deepSoilGreen,
                            AppColors.deepSoilGreen.withValues(alpha: 0.85),
                          ],
                    ),
                    border: Border.all(
                      color: AppColors.parchment.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                  ),
                  child: AnimatedScale(
                    scale: isActive ? 1.08 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutBack,
                    child: Icon(
                      isActive ? item.activeIcon : item.icon,
                      color: isDark && !isActive ? AppColors.charcoal : AppColors.parchment,
                      size: 24,
                    ),
                  ),
                ),
                // Badge
                if (itemCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: _AnimatedBadge(count: itemCount),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Animated badge with bounce effect
class _AnimatedBadge extends StatefulWidget {
  final int count;

  const _AnimatedBadge({required this.count});

  @override
  State<_AnimatedBadge> createState() => _AnimatedBadgeState();
}

class _AnimatedBadgeState extends State<_AnimatedBadge>
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
  void didUpdateWidget(_AnimatedBadge oldWidget) {
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

/// Dock-style navigation item with proximity-based scaling
class _DockNavItem extends StatefulWidget {
  final NavigatorItem item;
  final bool isActive;
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  final bool isDark;
  final int currentIndex;
  final int itemIndex;
  final double pageOffset;

  const _DockNavItem({
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
  State<_DockNavItem> createState() => _DockNavItemState();
}

class _DockNavItemState extends State<_DockNavItem>
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
    // Calculate distance from current page offset
    final distance = (widget.pageOffset - widget.itemIndex).abs();

    if (distance <= 0.1) {
      // Active item - full scale
      return 1.15;
    } else if (distance <= 1.1) {
      // Adjacent items - partial scale based on proximity
      final proximity = 1.0 - ((distance - 0.1) / 1.0);
      return 1.0 + (0.08 * proximity);
    } else {
      // Far items - base scale
      return 1.0;
    }
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
              // Icon with dock-style scaling
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
                        color:
                            widget.isActive
                                ? AppColors.parchment.withValues(alpha: 0.12)
                                : AppColors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        widget.isActive
                            ? widget.item.activeIcon
                            : widget.item.icon,
                        color:
                            widget.isActive
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
              // Label with animated visibility
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: widget.isActive ? 1.0 : 0.6,
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: widget.isActive ? 10 : 9,
                    fontWeight:
                        widget.isActive ? FontWeight.w600 : FontWeight.w500,
                    color:
                        widget.isActive
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
