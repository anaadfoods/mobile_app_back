import 'package:grocery_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:grocery_app/core/theme/theme.dart';

class CustomInput extends StatefulWidget {
  final String hintText;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final BorderRadius? borderRadius;
  final String? Function(String?)? validator;
  final FocusNode? focusNode;
  final void Function(bool)? onValidationChanged;
  final double? width;
  final double? height;
  final Color? customBorderColor;

  final Color? fillColor;
  final bool onPrimary; // New flag to style for on-primary backgrounds

  const CustomInput({
    super.key,
    this.customBorderColor,

    required this.hintText,
    required this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
    this.prefixIcon,
    this.borderRadius,
    this.validator,
    this.focusNode,
    this.onValidationChanged,
    this.width,
    this.height,
    this.fillColor,
    this.onPrimary = false, // Default to normal background
  });

  @override
  State<CustomInput> createState() => _CustomInputState();
}

class _CustomInputState extends State<CustomInput> {
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final onPrimaryColor = colorScheme.onPrimary;
    final primaryColor = colorScheme.primary;

    final effectiveTextStyle =
        widget.onPrimary
            ? theme.textTheme.bodyLarge?.copyWith(color: onPrimaryColor)
            : theme.textTheme.bodyLarge;

    final effectiveHintStyle =
        widget.onPrimary
            ? theme.textTheme.bodyMedium?.copyWith(
              color: onPrimaryColor.withValues(alpha: 0.7),
            )
            : theme.inputDecorationTheme.hintStyle;

    final effectiveFillColor =
        widget.fillColor ??
        (widget.onPrimary
            ? onPrimaryColor.withValues(alpha: 0.1)
            : theme.inputDecorationTheme.fillColor);

    final finalDecoration = InputDecoration(
      hintText: widget.hintText,
      hintStyle: effectiveHintStyle,
      prefixIcon: widget.prefixIcon,
      filled: true,
      fillColor: effectiveFillColor,
      // Use design system constants for border radius
      border: OutlineInputBorder(
        borderRadius:
            widget.borderRadius ?? BorderRadius.circular(AppColors.radiusM),
        borderSide: BorderSide(
          color:
              widget.onPrimary
                  ? onPrimaryColor.withValues(alpha: 0.3)
                  : (widget.customBorderColor ??
                      theme.inputDecorationTheme.border?.borderSide.color ??
                      AppColors.charcoal54),
          width: 1,
        ),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius:
            widget.borderRadius ?? BorderRadius.circular(AppColors.radiusM),
        borderSide: BorderSide(
          color:
              widget.onPrimary
                  ? onPrimaryColor.withValues(alpha: 0.4)
                  : (widget.customBorderColor ??
                      theme
                          .inputDecorationTheme
                          .enabledBorder
                          ?.borderSide
                          .color ??
                      AppColors.rawEarth26),
          width: 1,
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius:
            widget.borderRadius ?? BorderRadius.circular(AppColors.radiusM),
        borderSide: BorderSide(
          color: widget.onPrimary ? onPrimaryColor : primaryColor,
          width: 2,
        ),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius:
            widget.borderRadius ?? BorderRadius.circular(AppColors.radiusM),
        borderSide: BorderSide(color: colorScheme.error, width: 1.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius:
            widget.borderRadius ?? BorderRadius.circular(AppColors.radiusM),
        borderSide: BorderSide(color: colorScheme.error, width: 2.0),
      ),
      suffixIcon:
          widget.obscureText
              ? IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_off : Icons.visibility,
                  color:
                      widget.onPrimary
                          ? onPrimaryColor.withValues(alpha: 0.7)
                          : theme.iconTheme.color,
                ),
                onPressed: () {
                  setState(() {
                    _obscure = !_obscure;
                  });
                },
              )
              : widget.suffixIcon,
    );

    return SizedBox(
      width: widget.width ?? double.infinity,
      height:
          widget
              .height, // Let textformfield determine its own height unless specified
      child: TextFormField(
        controller: widget.controller,
        obscureText: _obscure,
        keyboardType: widget.keyboardType,
        validator: widget.validator,
        focusNode: widget.focusNode,
        onChanged:
            widget.onValidationChanged != null
                ? (value) {
                  final isValid = widget.validator?.call(value) == null;
                  widget.onValidationChanged!(isValid);
                }
                : null,
        style: effectiveTextStyle,
        cursorColor: widget.onPrimary ? onPrimaryColor : primaryColor,
        decoration: finalDecoration.copyWith(
          contentPadding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 14,
          ), // Compact padding
          isDense: true, // Reduces height further
        ),
      ),
    );
  }
}
