import 'package:grocery_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:grocery_app/core/theme/theme.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerLoading extends StatelessWidget {
  final Widget child;
  final bool isLoading;

  const ShimmerLoading({super.key, required this.child, this.isLoading = true});

  @override
  Widget build(BuildContext context) {
    if (!isLoading) {
      return child;
    }

    final isDark = context.isDark;

    return Shimmer.fromColors(
      baseColor: isDark ? AppColors.charcoal87 : AppColors.rawEarth12,
      highlightColor: isDark ? AppColors.charcoal60 : AppColors.parchment,
      child: child,
    );
  }
}
