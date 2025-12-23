import 'package:flutter/material.dart';

class Skeleton extends StatelessWidget {
  final double? width;
  final double? height;
  final bool isCircle;

  const Skeleton({super.key, this.width, this.height, this.isCircle = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle ? null : BorderRadius.circular(8),
      ),
    );
  }
}
