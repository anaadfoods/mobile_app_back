import 'package:flutter/material.dart';

class AppText extends StatelessWidget {
  final String text;
  final double? fontSize; // Now nullable
  final FontWeight? fontWeight; // Now nullable
  final Color? color; // Now nullable
  final TextAlign? textAlign;
  final TextStyle? style; // Optional: Pass a full TextStyle for complex cases
  final int? maxLines; // Optional: Maximum number of lines
  final TextOverflow? overflow; // Optional: How to handle text overflow

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
    //    bodyLarge is a good, readable default.
    final baseStyle = style ?? Theme.of(context).textTheme.bodyLarge;

    // 2. Use .copyWith() to apply specific overrides without losing theme defaults.
    //    If a parameter is null, the style from the theme is used.
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
