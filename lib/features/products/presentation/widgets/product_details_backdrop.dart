import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:grocery_app/core/theme/app_colors.dart';

class ProductDetailsBackdrop extends StatelessWidget {
  final String backgroundImage;
  final bool isDark;

  const ProductDetailsBackdrop({
    super.key,
    required this.backgroundImage,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: CachedNetworkImageProvider(backgroundImage),
          fit: BoxFit.cover,
        ),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                isDark
                    ? AppColors.darkCanvas.withValues(alpha: 0.7)
                    : AppColors.parchment.withValues(alpha: 0.85),
                isDark
                    ? AppColors.darkCanvas.withValues(alpha: 0.85)
                    : AppColors.parchment.withValues(alpha: 0.95),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
