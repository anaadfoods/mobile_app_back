import 'package:flutter/material.dart';
import 'package:grocery_app/styles/colors.dart';

class AppButton extends StatelessWidget {
  final String label;
  final double roundness;
  final FontWeight fontWeight;
  final Color? color;
  final Color? textColor;
  final double? width;

  final EdgeInsets? padding;
  final Widget? trailingWidget;
  final Function? onPressed;

  const AppButton({
    super.key,
    required this.label,
    this.roundness = 18,
    this.fontWeight = FontWeight.bold,
    this.padding ,
    this.trailingWidget,
    this.color,
    this.textColor,
    this.width,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.maxFinite,
      child: ElevatedButton(
        onPressed: () {
          onPressed?.call();
        },
        style: ElevatedButton.styleFrom(
          visualDensity: VisualDensity.compact,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(roundness),
          ),
          elevation: 0,
          backgroundColor: color,
          textStyle: TextStyle(
            color: textColor,
            fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
            fontWeight: fontWeight,
          ),
          padding: padding ?? EdgeInsets.symmetric(vertical: 24),
          minimumSize: const Size.fromHeight(50),
        ),
        child: Stack(
          fit: StackFit.passthrough,
          children: <Widget>[
            Center(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: fontWeight,
                ),
              ),
            ),
            if (trailingWidget != null)
              Positioned(
                top: 0,
                right: 25,
                child: trailingWidget!,
              ),
          ],
        ),
      ),
    );
  }
}
