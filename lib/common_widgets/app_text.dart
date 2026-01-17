import 'package:flutter/material.dart';

class AppText extends StatelessWidget {
  final String text;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? color;
  final TextAlign? textAlign;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  const AppText({
    super.key,
    required this.text,
    this.fontSize,
    this.fontWeight,
    this.color,
    this.textAlign,
    this.style,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Get the default text style from the current theme.
    final baseStyle = style ?? Theme.of(context).textTheme.bodyLarge;

    // 2. Use .copyWith() to apply specific overrides without losing theme defaults.
    final finalStyle = baseStyle?.copyWith(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );

    return Text(
      text,
      textAlign: textAlign,
      style: finalStyle,
      maxLines: maxLines,
      overflow: overflow ?? (maxLines != null ? TextOverflow.ellipsis : null),
    );
  }
}
