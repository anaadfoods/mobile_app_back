import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:grocery_app/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:grocery_app/features/cart/presentation/cubit/cart_state.dart';
import 'package:grocery_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:grocery_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:grocery_app/features/favorites/presentation/cubit/favorites_cubit.dart';
import 'package:grocery_app/features/home/presentation/cubit/home_cubit.dart';
import 'package:grocery_app/features/products/presentation/cubit/product_cubit.dart';
import 'package:grocery_app/helpers/snackbar_helper.dart';
import 'package:grocery_app/service_locator.dart';
import 'package:grocery_app/services/notification_service.dart';
import '../widgets/dashboard_navigation_bar.dart';

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

  // Swipe Navigation State
  late AnimationController _slideController;
  double _dragOffset = 0.0;
  bool _isAnimating = false;
  double _animStartOffset = 0.0;
  double _animEndOffset = 0.0;
  int? _pendingTabIndex;
  Curve _activeCurve = Curves.fastOutSlowIn;

  DateTime? lastTimeBackPressed;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fabFloatController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    )
      ..addListener(_onSlideAnimation)
      ..addStatusListener(_onSlideAnimationStatus);

    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        getIt<NotificationService>().requestNotificationPermission();
      }
    });

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
    _slideController.removeListener(_onSlideAnimation);
    _slideController.removeStatusListener(_onSlideAnimationStatus);
    _slideController.dispose();
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
    if (_isAnimating) return;

    HapticFeedback.selectionClick();
    _bounceController.forward(from: 0);

    final currentIndex = widget.navigationShell.currentIndex;
    final screenWidth = MediaQuery.sizeOf(context).width;

    _isAnimating = true;
    _pendingTabIndex = index;
    _animStartOffset = 0.0;
    _animEndOffset = index > currentIndex ? -screenWidth * 0.4 : screenWidth * 0.4;
    _activeCurve = Curves.decelerate;
    
    _slideController.duration = const Duration(milliseconds: 160);
    _slideController.forward(from: 0);
  }

  void _onSlideAnimation() {
    setState(() {
      _dragOffset = lerpDouble(
        _animStartOffset,
        _animEndOffset,
        _activeCurve.transform(_slideController.value),
      )!;
    });
  }

  void _onSlideAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      if (_pendingTabIndex != null) {
        final targetTab = _pendingTabIndex!;
        _pendingTabIndex = null;

        HapticFeedback.selectionClick();
        _bounceController.forward(from: 0);
        widget.navigationShell.goBranch(
          targetTab,
          initialLocation: targetTab == widget.navigationShell.currentIndex,
        );

        final screenWidth = MediaQuery.sizeOf(context).width;
        _animStartOffset =
            _dragOffset > 0 ? -screenWidth * 0.2 : screenWidth * 0.2;
        _animEndOffset = 0.0;
        _dragOffset = _animStartOffset;
        _activeCurve = Curves.decelerate;
        _slideController.duration = const Duration(milliseconds: 220);
        _slideController.forward(from: 0);
      } else {
        setState(() {
          _isAnimating = false;
          _dragOffset = 0.0;
        });
      }
    }
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    if (_isAnimating) {
      _slideController.stop();
      _isAnimating = false;
    }
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (_isAnimating) return;

    final delta = details.primaryDelta ?? 0;
    final currentIndex = widget.navigationShell.currentIndex;
    final totalTabs = navigatorItems.length;
    final isAtStart = currentIndex == 0;
    final isAtEnd = currentIndex == totalTabs - 1;

    setState(() {
      _dragOffset += delta;
      if ((isAtStart && _dragOffset > 0) || (isAtEnd && _dragOffset < 0)) {
        _dragOffset -= delta * 0.75;
      }
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_isAnimating) return;

    final velocity = details.primaryVelocity ?? 0;
    final absVelocity = velocity.abs();
    final currentIndex = widget.navigationShell.currentIndex;
    final totalTabs = navigatorItems.length;
    final screenWidth = MediaQuery.sizeOf(context).width;

    final dragThreshold = screenWidth * 0.20;
    int targetIndex = currentIndex;

    if (velocity < -250 || (_dragOffset < -dragThreshold && velocity <= 0)) {
      targetIndex = currentIndex + 1;
    } else if (velocity > 250 ||
        (_dragOffset > dragThreshold && velocity >= 0)) {
      targetIndex = currentIndex - 1;
    }

    targetIndex = targetIndex.clamp(0, totalTabs - 1);
    _isAnimating = true;

    if (targetIndex != currentIndex) {
      _pendingTabIndex = targetIndex;
      _animStartOffset = _dragOffset;
      _animEndOffset = targetIndex > currentIndex
          ? -screenWidth * 0.4
          : screenWidth * 0.4;

      final remainingDistance = (_animEndOffset - _animStartOffset).abs();
      final baseDuration = absVelocity > 500
          ? 120
          : absVelocity > 250
              ? 160
              : (remainingDistance / screenWidth * 280)
                  .clamp(100, 220)
                  .toInt();

      _activeCurve = Curves.decelerate;
      _slideController.duration = Duration(milliseconds: baseDuration);
      _slideController.forward(from: 0);
    } else {
      _animStartOffset = _dragOffset;
      _animEndOffset = 0.0;
      _pendingTabIndex = null;
      final springDuration =
          (_dragOffset.abs() / screenWidth * 300).clamp(120, 280).toInt();
      _activeCurve = Curves.fastOutSlowIn;
      _slideController.duration = Duration(milliseconds: springDuration);
      _slideController.forward(from: 0);
    }
  }

  void switchToTab(int index) {
    _onTabChanged(index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final currentIndex = widget.navigationShell.currentIndex;
    final pageOffset = currentIndex.toDouble();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        if (widget.navigationShell.currentIndex == 0 && !context.canPop()) {
          final now = DateTime.now();
          final isWarning = lastTimeBackPressed == null ||
              now.difference(lastTimeBackPressed!) >
                  const Duration(seconds: 2);

          if (isWarning) {
            lastTimeBackPressed = now;
            SnackBarHelper.showInfo(context, "Tap back again to exit 👋");
          } else {
            SystemNavigator.pop();
          }
        } else {
          if (context.canPop()) {
            context.pop();
          } else {
            widget.navigationShell.goBranch(0);
          }
        }
      },
      child: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, authState) {
          if (authState is Unauthenticated) {
            context.read<CartCubit>().clearCartState();
            context.read<FavoritesCubit>().clearFavoritesState();
            context.read<HomeCubit>().loadHomeData();
            context.read<ProductCubit>().loadHomePageData();
            
            // Switch to home tab on logout silently
            if (widget.navigationShell.currentIndex != 0) {
              widget.navigationShell.goBranch(0);
            }
          }
        },
        builder: (context, authState) {
          final isAuth = authState is Authenticated;
          final dynamicItems = List<NavigatorItem>.from(navigatorItems);
          
          if (!isAuth && dynamicItems.length > 4) {
             dynamicItems[4] = NavigatorItem(
               label: 'Login',
               icon: dynamicItems[4].icon,
               activeIcon: dynamicItems[4].activeIcon,
             );
          }

          return Scaffold(
            body: GestureDetector(
              onHorizontalDragStart: _onHorizontalDragStart,
              onHorizontalDragUpdate: _onHorizontalDragUpdate,
              onHorizontalDragEnd: _onHorizontalDragEnd,
              behavior: HitTestBehavior.translucent,
              child: ClipRect(
                child: Transform.translate(
                  offset: Offset(_dragOffset, 0),
                  child: widget.navigationShell,
                ),
              ),
            ),
            bottomNavigationBar: BlocBuilder<CartCubit, CartState>(
              builder: (context, cartState) {
                final cartCount =
                    (cartState is CartSuccess) ? cartState.cart.items.length : 0;

                return PremiumBottomNavBar(
                  currentIndex: currentIndex,
                  onTabChanged: _onTabChanged,
                  items: dynamicItems,
                  isDark: isDark,
                  colorScheme: colorScheme,
                  bounceController: _bounceController,
                  fabFloatController: _fabFloatController,
                  pageOffset: pageOffset,
                  cartBadgeCount: cartCount,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
