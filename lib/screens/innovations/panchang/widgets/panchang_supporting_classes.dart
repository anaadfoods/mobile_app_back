import 'package:grocery_app/common_widgets/global_import.dart';

class PanchangItemData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String secondaryLabel;

  const PanchangItemData(
    this.label,
    this.value,
    this.icon,
    this.color,
    this.secondaryLabel,
  );
}

class BackgroundPatternPainter extends CustomPainter {
  final bool isDark;

  BackgroundPatternPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = (isDark ? AppColors.pureWhite : AppColors.charcoal)
              .withValues(alpha: 0.02)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;

    for (int i = 0; i < 10; i++) {
      canvas.drawCircle(
        Offset(size.width * (i / 10), size.height * 0.2),
        50 + (i * 10),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class AnimatedScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const AnimatedScaleButton({super.key, required this.child, required this.onTap});

  @override
  State<AnimatedScaleButton> createState() => _AnimatedScaleButtonState();
}

class _AnimatedScaleButtonState extends State<AnimatedScaleButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
    );
  }
}
