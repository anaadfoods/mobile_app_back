import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:grocery_app/helpers/skelton.dart';

class HomeBannerSkeleton extends StatelessWidget {
  const HomeBannerSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: 180,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

class HomeCategorySkeleton extends StatelessWidget {
  const HomeCategorySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SizedBox(
        height: 90,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 5,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Column(
              children: const [
                Skeleton(width: 60, height: 60, isCircle: true),
                SizedBox(height: 6),
                Skeleton(width: 50, height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HomeProductSkeleton extends StatelessWidget {
  const HomeProductSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SizedBox(
        height: 220,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 4,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemBuilder: (context, index) => Container(
            width: 150,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Skeleton(width: 134, height: 110),
                SizedBox(height: 8),
                Skeleton(width: 100, height: 14),
                SizedBox(height: 6),
                Skeleton(width: 60, height: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HomeCommunitySkeleton extends StatelessWidget {
  const HomeCommunitySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: 140,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
