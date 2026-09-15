import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grocery_app/core/theme/app_colors.dart';

class ExpandableAnaadFab extends StatefulWidget {
  final VoidCallback onAiChatPressed;
  final VoidCallback onMemoryPressed;

  const ExpandableAnaadFab({
    super.key,
    required this.onAiChatPressed,
    required this.onMemoryPressed,
  });

  @override
  State<ExpandableAnaadFab> createState() => _ExpandableAnaadFabState();
}

class _ExpandableAnaadFabState extends State<ExpandableAnaadFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isOpen = false;
  OverlayEntry? _overlayEntry;
  final GlobalKey _fabKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.lightImpact();
    if (_isOpen) {
      _controller.reverse().then((_) {
        _removeOverlay();
        if (mounted) setState(() => _isOpen = false);
      });
    } else {
      setState(() => _isOpen = true);
      _showOverlay();
      _controller.forward();
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showOverlay() {
    final overlay = Overlay.of(context);
    final renderBox = _fabKey.currentContext!.findRenderObject() as RenderBox;
    final fabPosition = renderBox.localToGlobal(Offset.zero);
    final fabSize = renderBox.size;
    final fabCenter = Offset(
      fabPosition.dx + fabSize.width / 2,
      fabPosition.dy + fabSize.height / 2,
    );

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            // Scrim
            GestureDetector(
              onTap: _toggle,
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: _controller,
                  curve: Curves.easeOut,
                ),
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                ),
              ),
            ),

            // Sub-buttons
            ..._buildExpandedButtons(fabCenter),
          ],
        );
      },
    );

    overlay.insert(_overlayEntry!);
  }

  List<Widget> _buildExpandedButtons(Offset center) {
    const double distance = 70.0;

    // AI Chat: roughly 135° (top-left)
    final angle1 = 135.0 * (math.pi / 180.0);
    // Memory: roughly 200° (left, slightly down)
    final angle2 = 200.0 * (math.pi / 180.0);

    return [
      _buildSubButton(
        center: center,
        angle: angle2,
        distance: distance,
        icon: Icons.psychology_rounded,
        label: 'Memory',
        interval: const Interval(0.15, 0.85),
        onPressed: () {
          _toggle();
          widget.onMemoryPressed();
        },
      ),
      _buildSubButton(
        center: center,
        angle: angle1,
        distance: distance,
        icon: Icons.auto_awesome,
        label: 'AI Chat',
        interval: const Interval(0.0, 0.7),
        onPressed: () {
          _toggle();
          widget.onAiChatPressed();
        },
      ),
    ];
  }

  Widget _buildSubButton({
    required Offset center,
    required double angle,
    required double distance,
    required IconData icon,
    required String label,
    required Interval interval,
    required VoidCallback onPressed,
  }) {
    final dx = distance * math.cos(angle);
    final dy = distance * math.sin(angle);

    final startLeft = center.dx - 22; // 22 is half of 44dp
    final startTop = center.dy - 22;

    return Positioned(
      left: startLeft,
      top: startTop,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final animation = CurvedAnimation(
            parent: _controller,
            curve: interval,
          );
          final progress = Curves.easeOutBack.transform(animation.value);

          return Transform.translate(
            offset: Offset(dx * progress, -dy * progress),
            child: Transform.scale(
              scale: progress.clamp(0.0, 2.0),
              child: Opacity(
                opacity: animation.value.clamp(0.0, 1.0),
                child: child,
              ),
            ),
          );
        },
        child: Material(
          type: MaterialType.circle,
          color: AppColors.pureWhite,
          elevation: 4,
          child: Tooltip(
            message: label,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onPressed,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  icon,
                  color: AppColors.deepSoilGreen,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: _fabKey,
      width: 56,
      height: 56,
      child: Material(
        type: MaterialType.circle,
        color: AppColors.deepSoilGreen,
        elevation: 4,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: _toggle,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.rotate(
                angle: _controller.value * math.pi,
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Opacity(
                        opacity: (1.0 - _controller.value).clamp(0.0, 1.0),
                        child: Transform.rotate(
                          angle: -_controller.value * math.pi,
                          child: const Text(
                            'A',
                            style: TextStyle(
                              color: AppColors.pureWhite,
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),
                        ),
                      ),
                      Opacity(
                        opacity: _controller.value.clamp(0.0, 1.0),
                        child: const Icon(
                          Icons.close,
                          color: AppColors.pureWhite,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
