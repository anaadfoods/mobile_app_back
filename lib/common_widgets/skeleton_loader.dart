import 'package:flutter/material.dart';
import 'package:grocery_app/helpers/responsive_helper.dart';

class SkeletonContainer extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const SkeletonContainer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
    );
  }
}

class SkeletonAnimation extends StatefulWidget {
  final Widget child;
  final bool isLoading;
  final Widget? loadingWidget;

  const SkeletonAnimation({
    super.key,
    required this.child,
    required this.isLoading,
    this.loadingWidget,
  });

  @override
  _SkeletonAnimationState createState() => _SkeletonAnimationState();
}

class _SkeletonAnimationState extends State<SkeletonAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: widget.loadingWidget ?? widget.child,
        );
      },
    );
  }
}

class SubscriptionSkeletonLoader extends StatelessWidget {
  const SubscriptionSkeletonLoader({super.key, required ResponsiveHelper responsive});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: 1, // Show 3 skeleton cards
      itemBuilder: (context, index) => _buildSkeletonCard(),
    );
  }

  Widget _buildSkeletonCard() {
    return Card(
      elevation: 4,
      margin: EdgeInsets.all(8),
      child: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            SkeletonContainer(width: 150, height: 24),
            SizedBox(height: 8),
            SkeletonContainer(width: 100, height: 16),
            SizedBox(height: 16),

            // Info rows
            ...List.generate(
              5,
              (index) => Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SkeletonContainer(width: 100, height: 16),
                    SkeletonContainer(width: 80, height: 16),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),
            // Product limits section
            SkeletonContainer(width: 120, height: 20),
            SizedBox(height: 8),
            ...List.generate(
              2,
              (index) => Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SkeletonContainer(width: 120, height: 16),
                    SkeletonContainer(width: 60, height: 16),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),
            // Description
            SkeletonContainer(width: double.infinity, height: 40),
            SizedBox(height: 16),
            // Button
            SkeletonContainer(
              width: double.infinity,
              height: 48,
              borderRadius: BorderRadius.circular(8),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductSkeletonLoader extends StatelessWidget {
  const ProductSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 6, // Show 6 skeleton items
      itemBuilder: (context, index) => _buildSkeletonProduct(),
    );
  }

  Widget _buildSkeletonProduct() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            SkeletonContainer(
              width: double.infinity,
              height: 120,
              borderRadius: BorderRadius.circular(8),
            ),
            SizedBox(height: 8),
            // Title
            SkeletonContainer(width: 100, height: 16),
            SizedBox(height: 4),
            // Category
            SkeletonContainer(width: 80, height: 14),
            SizedBox(height: 8),
            // Price
            SkeletonContainer(width: 60, height: 16),
            Spacer(),
            // Add to cart button
            SkeletonContainer(
              width: double.infinity,
              height: 36,
              borderRadius: BorderRadius.circular(8),
            ),
          ],
        ),
      ),
    );
  }
}

class FavoriteSkeletonLoader extends StatelessWidget {
  const FavoriteSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: 5, // Show 5 skeleton items
      itemBuilder: (context, index) => _buildSkeletonFavorite(),
    );
  }

  Widget _buildSkeletonFavorite() {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: SkeletonContainer(
          width: 60,
          height: 60,
          borderRadius: BorderRadius.circular(8),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonContainer(width: 120, height: 16),
            SizedBox(height: 4),
            SkeletonContainer(width: 80, height: 14),
          ],
        ),
        trailing: SkeletonContainer(width: 24, height: 24),
      ),
    );
  }
} 