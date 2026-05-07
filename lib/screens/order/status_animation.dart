import 'package:flutter/material.dart';

class LiveStatusIcon extends StatefulWidget {
  final IconData icon;
  final Color color;

  const LiveStatusIcon({super.key, required this.icon, required this.color});

  @override
  _LiveStatusIconState createState() => _LiveStatusIconState();
}

class _LiveStatusIconState extends State<LiveStatusIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    )..repeat(reverse: true); // Repeats the animation back and forth

    _animation = Tween<double>(
      begin: 0.9,
      end: 1.3,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: Icon(widget.icon, color: widget.color, size: 18),
    );
  }
}
