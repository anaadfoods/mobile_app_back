import 'package:flutter/material.dart';

/// Keeps scrolling native to the current platform while removing the default
/// overscroll glow. This feels more at home on both Android and iOS than
/// forcing a single physics implementation everywhere in the application.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return switch (Theme.of(context).platform) {
      TargetPlatform.iOS || TargetPlatform.macOS =>
        const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      _ => const ClampingScrollPhysics(),
    };
  }
}
