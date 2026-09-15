import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grocery_app/core/theme/app_colors.dart';

enum _RefreshState { idle, pulling, refreshing, done }

class ShortPullToRefresh extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final Color headerColor;
  final double triggerHeight;
  final double loaderSize;

  const ShortPullToRefresh({
    super.key,
    required this.child,
    required this.onRefresh,
    this.headerColor = AppColors.charcoal,
    this.triggerHeight = 60.0,
    this.loaderSize = 24.0,
  });

  @override
  _ShortPullToRefreshState createState() => _ShortPullToRefreshState();
}

class _ShortPullToRefreshState extends State<ShortPullToRefresh>
    with SingleTickerProviderStateMixin {
  _RefreshState _state = _RefreshState.idle;
  double _dragOffset = 0.0;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // Maximum distance the content can be pulled down
  final double _maxDragOffset = 90.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _startRefresh() async {
    setState(() {
      _state = _RefreshState.refreshing;
    });
    // Snap to trigger height
    await _animateTo(widget.triggerHeight);

    // Haptic feedback
    HapticFeedback.mediumImpact();

    try {
      await widget.onRefresh();
    } finally {
      if (mounted) {
        setState(() {
          _state = _RefreshState.done;
        });
        // Slight delay to show done state or just finish smoothly
        await Future.delayed(const Duration(milliseconds: 200));
        await _animateTo(0.0);
        if (mounted) {
          setState(() {
            _state = _RefreshState.idle;
          });
        }
      }
    }
  }

  Future<void> _reset() async {
    await _animateTo(0.0);
    if (mounted) {
      setState(() {
        _state = _RefreshState.idle;
      });
    }
  }

  Future<void> _animateTo(double target) async {
    final start = _dragOffset;
    final dist = target - start;
    if (dist == 0) return;

    // Simple manual animation loop since we need to update state
    // Or we could use an AnimationController to drive a value
    // Let's use a temporary controller for smoothness if needed,
    // but a simple loop with the existing controller or a new one is fine.
    // For simplicity, let's just animate the controller if we were using it for offset,
    // but here offset is explicit.
    // We'll use the _animationController to drive standard animations,
    // but for offset reset we can just use a Ticker or a quick loop.

    // Better: animate a value and listen to it.
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    final anim = Tween<double>(
      begin: start,
      end: target,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));

    anim.addListener(() {
      setState(() {
        _dragOffset = anim.value;
      });
    });

    await controller.forward();
    controller.dispose();
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (_state == _RefreshState.refreshing || _state == _RefreshState.done) {
      return false;
    }

    if (notification is ScrollStartNotification) {
      // Logic if needed
    }

    if (notification is OverscrollNotification) {
      if (notification.overscroll < 0) {
        // User is pulling down (negative overscroll at top)
        // Note: overscroll value is how much it *wanted* to scroll but couldn't.
        // It is negative when pulling down at the top.

        // Add resistance
        final delta = notification.overscroll.abs() * 0.5;
        setState(() {
          _dragOffset += delta;
          if (_dragOffset > _maxDragOffset) {
            _dragOffset = _maxDragOffset;
          }
        });

        if (_state == _RefreshState.idle && _dragOffset > 0) {
          _state = _RefreshState.pulling;
          _animationController.forward();
        }
      } else if (notification.overscroll > 0 && _dragOffset > 0) {
        // pushing back up?
        setState(() {
          _dragOffset -= notification.overscroll;
          if (_dragOffset < 0) _dragOffset = 0;
        });
      }
    } else if (notification is ScrollUpdateNotification) {
      // If we have drag offset and user scrolls back up (positive scroll delta),
      // we should reduce drag offset first before scrolling content.
      if (_dragOffset > 0 &&
          notification.scrollDelta != null &&
          notification.scrollDelta! > 0) {
        // We are "scrolling up" but actually just reducing the overscroll gap
        // Use the delta to reduce dragOffset
        // This is tricky with ClampingPhysics as it might just scroll the list.
        // But if we are translated down, the list is effectively at 0.

        // If we want to intercept the scroll to reduce our offset:
        // We can't easily "cancel" the scroll in the child.
        // But visual alignment matters most.
      }
    } else if (notification is ScrollEndNotification) {
      if (_state == _RefreshState.pulling) {
        if (_dragOffset >= widget.triggerHeight) {
          _startRefresh();
        } else {
          _reset();
          _animationController.reverse();
        }
      } else if (_state == _RefreshState.idle && _dragOffset > 0) {
        _reset();
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Loader
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: widget.triggerHeight, // center in this area
          child: Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: SizedBox(
                width: widget.loaderSize,
                height: widget.loaderSize,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(widget.headerColor),
                ),
              ),
            ),
          ),
        ),

        // Content
        Transform.translate(
          offset: Offset(0, _dragOffset),
          child: NotificationListener<ScrollNotification>(
            onNotification: _handleScrollNotification,
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                physics: const ClampingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
              ),
              child: widget.child,
            ),
          ),
        ),
      ],
    );
  }
}
