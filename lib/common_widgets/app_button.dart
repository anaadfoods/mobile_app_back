import "global_import.dart";

class AppButton extends StatefulWidget {
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
    this.padding,
    this.trailingWidget,
    this.color,
    this.textColor,
    this.width,
    this.onPressed,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonTheme = theme.elevatedButtonTheme.style;

    final isEnabled = widget.onPressed != null;

    return Semantics(
      button: true,
      enabled: isEnabled,
      label: widget.label,
      child: GestureDetector(
        onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: isEnabled ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel: isEnabled ? () => setState(() => _isPressed = false) : null,
        child: AnimatedScale(
          scale: _isPressed ? 0.98 : 1.0,
          duration: const Duration(milliseconds: AppColors.animFast),
          curve: Curves.easeInOut,
          child: SizedBox(
            width: widget.width ?? double.maxFinite,
            child: ElevatedButton(
              onPressed: isEnabled ? () => widget.onPressed?.call() : null,
              style: (buttonTheme ?? ElevatedButton.styleFrom()).copyWith(
                backgroundColor:
                    widget.color != null
                        ? WidgetStateProperty.all(widget.color)
                        : null,
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(widget.roundness),
                  ),
                ),
                padding: WidgetStateProperty.all(
                  widget.padding ??
                      const EdgeInsets.symmetric(
                        vertical: AppSpacing.md + 2,
                        horizontal: AppSpacing.xl,
                      ),
                    ),
                elevation: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.pressed)) return 0;
                  return 2;
                }),
              ),
              child: Stack(
                fit: StackFit.passthrough,
                children: <Widget>[
                  Center(
                    child: Text(
                      widget.label,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color:
                            widget.textColor ?? theme.colorScheme.onPrimary,
                        fontWeight: widget.fontWeight,
                      ),
                    ),
                  ),
                  if (widget.trailingWidget != null)
                    Positioned(
                      top: 0,
                      right: 25,
                      child: widget.trailingWidget!,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
