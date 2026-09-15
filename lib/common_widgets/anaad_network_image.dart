import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:grocery_app/core/theme/theme.dart';

/// The shared image treatment for remote product and content images.
///
/// It prevents loading spinners from jumping layouts and gives every failed
/// image a calm, recognisable fallback instead of a broken-image icon.
class AnaadNetworkImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final String? semanticLabel;
  final Widget? fallback;

  const AnaadNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.semanticLabel,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final image = CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 160),
      placeholder: (_, __) => const _ImagePlaceholder(),
      errorWidget: (_, __, ___) => fallback ?? const _ImageFallback(),
    );

    final child = semanticLabel == null
        ? image
        : Semantics(image: true, label: semanticLabel, child: image);

    if (borderRadius == null) return child;
    return ClipRRect(borderRadius: borderRadius!, child: child);
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.softCream,
      child: Center(
        child: SizedBox(
          height: 22,
          width: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.lightGold,
      child: Center(
        child: Icon(
          Icons.eco_outlined,
          size: 34,
          color: AppColors.deepSoilGreen,
        ),
      ),
    );
  }
}
