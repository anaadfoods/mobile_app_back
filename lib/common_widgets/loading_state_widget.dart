import 'package:flutter/material.dart';
import 'package:grocery_app/common_widgets/shimmer_loading.dart';

/// A reusable loading state widget for showing shimmer placeholders.
///
/// Consolidates the various `_buildLoadingState` implementations across the app.
///
/// Usage:
/// ```dart
/// LoadingStateWidget()                          // default list
/// LoadingStateWidget.grid()                     // grid layout
/// LoadingStateWidget(itemCount: 6, itemHeight: 80)  // customized
/// ```
class LoadingStateWidget extends StatelessWidget {
  /// Number of shimmer placeholder items (default: 4)
  final int itemCount;

  /// Height of each placeholder item (default: 100)
  final double itemHeight;

  /// Border radius of placeholder items (default: 20)
  final double borderRadius;

  /// Padding around the list (default: 16)
  final double padding;

  /// Space between items (default: 12)
  final double spacing;

  /// Whether to use grid layout
  final bool isGrid;

  /// Grid cross-axis count (only used if isGrid is true)
  final int gridCrossAxisCount;

  const LoadingStateWidget({
    super.key,
    this.itemCount = 4,
    this.itemHeight = 100,
    this.borderRadius = 20,
    this.padding = 16,
    this.spacing = 12,
    this.isGrid = false,
    this.gridCrossAxisCount = 2,
  });

  /// Creates a grid-style loading state
  const LoadingStateWidget.grid({
    super.key,
    this.itemCount = 6,
    this.itemHeight = 160,
    this.borderRadius = 16,
    this.padding = 16,
    this.spacing = 12,
    this.gridCrossAxisCount = 2,
  }) : isGrid = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isGrid) {
      return Padding(
        padding: EdgeInsets.all(padding),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: gridCrossAxisCount,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            childAspectRatio: 1.0,
          ),
          itemCount: itemCount,
          itemBuilder:
              (context, index) => ShimmerLoading(
                isLoading: true,
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(borderRadius),
                  ),
                ),
              ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.all(padding),
      child: Column(
        children: List.generate(
          itemCount,
          (index) => Padding(
            padding: EdgeInsets.only(bottom: spacing),
            child: ShimmerLoading(
              isLoading: true,
              child: Container(
                height: itemHeight,
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(borderRadius),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
