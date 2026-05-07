import 'package:grocery_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:grocery_app/core/theme/theme.dart';

class CustomSwitch extends StatelessWidget {
  final bool value;

  final ValueChanged<bool> onChanged;

  final Color activeColor;

  final Color inactiveColor;

  final Color thumbColor;

  final double width;

  final double height;

  const CustomSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor = AppColors.deepSoilGreen,
    this.inactiveColor = AppColors.charcoal54,
    this.thumbColor = AppColors.parchment,
    this.width = 50.0,
    this.height = 30.0,
  });

  @override
  Widget build(BuildContext context) {
    final double thumbSize = height - 4.0;

    return GestureDetector(
      onTap: () {
        onChanged(!value);
      },
      child: AnimatedContainer(
        width: width,
        height: height,
        duration: const Duration(milliseconds: AppColors.animMedium),
        curve: Curves.easeIn,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(height / 2),
          color: value ? activeColor : inactiveColor,
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: AppColors.animMedium),
          curve: Curves.easeIn,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: thumbSize,
            height: thumbSize,
            margin: const EdgeInsets.all(2.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: thumbColor,
              boxShadow: [
                BoxShadow(
                  color: AppColors.charcoal.withValues(alpha: 0.1),
                  blurRadius: 2,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
