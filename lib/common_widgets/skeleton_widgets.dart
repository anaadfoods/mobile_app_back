import 'package:grocery_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:grocery_app/common_widgets/shimmer_loading.dart';
import 'package:grocery_app/core/theme/theme.dart';

class SkeletonContainer extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const SkeletonContainer._({
    this.width = double.infinity,
    this.height = double.infinity,
    this.borderRadius,
  });

  const SkeletonContainer.square({
    required double size,
    BorderRadius? borderRadius,
  }) : this._(width: size, height: size, borderRadius: borderRadius);

  const SkeletonContainer.rounded({
    required double width,
    required double height,
    BorderRadius? borderRadius,
  }) : this._(
         width: width,
         height: height,
         borderRadius:
             borderRadius ?? const BorderRadius.all(Radius.circular(12)),
       );

  const SkeletonContainer.circular({required double size})
    : this._(
        width: size,
        height: size,
        borderRadius: const BorderRadius.all(Radius.circular(999)),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ShimmerLoading(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isDark ? AppColors.charcoal87 : AppColors.rawEarth12,
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class SkeletonProductItem extends StatelessWidget {
  const SkeletonProductItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        children: [
          const SkeletonContainer.square(
            size: 80,
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonContainer.rounded(
                  width: double.infinity,
                  height: 16,
                ),
                const SizedBox(height: 8),
                const SkeletonContainer.rounded(width: 100, height: 12),
                const SizedBox(height: 8),
                const SkeletonContainer.rounded(width: 60, height: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SkeletonOrderCard extends StatelessWidget {
  const SkeletonOrderCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              SkeletonContainer.rounded(width: 100, height: 16),
              SkeletonContainer.rounded(
                width: 80,
                height: 24,
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const SkeletonContainer.rounded(width: 150, height: 14),
          const SizedBox(height: 8),
          const SkeletonContainer.rounded(width: 120, height: 14),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              SkeletonContainer.rounded(width: 60, height: 14),
              SkeletonContainer.rounded(width: 80, height: 18),
            ],
          ),
        ],
      ),
    );
  }
}

class SkeletonOrderDetail extends StatelessWidget {
  const SkeletonOrderDetail({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(
            height: 200,
            child: SkeletonContainer.rounded(
              width: double.infinity,
              height: 200,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const SkeletonContainer.rounded(
                  width: double.infinity,
                  height: 100,
                ), // Timeline
                const SizedBox(height: 16),
                const SkeletonContainer.rounded(
                  width: double.infinity,
                  height: 150,
                ), // Products
                const SizedBox(height: 16),
                const SkeletonContainer.rounded(
                  width: double.infinity,
                  height: 120,
                ), // Summary
              ],
            ),
          ),
        ],
      ),
    );
  }
}
