import 'package:flutter/material.dart';
import 'package:grocery_app/core/theme/app_colors.dart';

class AnaadLogoMark extends StatelessWidget {
  final double size;
  final double logoSize;
  final VoidCallback? onTap;
  final double backgroundOpacity;
  final bool showShadow;
  final String? logoPath;

  const AnaadLogoMark({
    super.key,
    this.size = 54,
    this.logoSize = 40,
    this.onTap,
    this.backgroundOpacity = 0.16,
    this.showShadow = true,
    this.logoPath = "assets/images/OnBoarding/logo.png",
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppColors.radiusM);

    final logo = Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.15),
      decoration: BoxDecoration(
        // color: AppColors.parchment.withValues(alpha: backgroundOpacity),
        borderRadius: radius,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppColors.radiusS),
        child: Image.asset(
          logoPath!,
          width: logoSize,
          height: logoSize,
          fit: BoxFit.contain,
        ),
      ),
    );

    if (onTap == null) return logo;

    return Material(
      color: AppColors.transparent,
      borderRadius: radius,
      child: InkWell(onTap: onTap, borderRadius: radius, child: logo),
    );
  }
}
