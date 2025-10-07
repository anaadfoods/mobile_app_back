import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class FillImageWithColor extends StatelessWidget {
  final String imageUrl;
  final Color fillColor;
  final Color baseColor;
  final int percentage;

  const FillImageWithColor({super.key, 
    required this.imageUrl,
    required this.fillColor,
    required this.baseColor,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    final fillGradient = LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [fillColor, baseColor],
      stops: [percentage / 100, percentage / 100],
    );

    return Stack(
      children: [
        SvgPicture.asset(imageUrl, color: baseColor),
        ShaderMask(
          shaderCallback: (bounds) => fillGradient.createShader(bounds),
          blendMode: BlendMode.srcATop,
          child: SvgPicture.asset(imageUrl, color: fillColor),
        ),
      ],
    );
  }
}
