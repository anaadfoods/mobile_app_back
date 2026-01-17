import 'package:flutter/material.dart';

class SnackBarHelper {
  static void showTopSnackBar(
    BuildContext context, {
    required String message,
    Color backgroundColor = Colors.black87,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
    bool showProgressIndicator = false,
  }) {
    final overlay = Overlay.of(context);
    late final OverlayEntry overlayEntry;

    // Create glowing shadow color based on background
    final shadowColor = backgroundColor.withValues(alpha: 0.5);

    overlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Material(
              color: Colors.transparent,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, -20 * (1 - value)),
                    child: Opacity(
                      opacity: value.clamp(0.0, 1.0),
                      child: child,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      // Glowing shadow effect
                      BoxShadow(
                        color: shadowColor,
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 8),
                      ),
                      // Subtle depth shadow
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (showProgressIndicator) ...[
                        SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Text(
                          message,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      if (action != null)
                        TextButton(
                          onPressed: () {
                            overlayEntry.remove();
                            action.onPressed();
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.2,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            minimumSize: Size.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            action.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(duration, () => overlayEntry.remove());
  }

  static void showSuccess(
    BuildContext context,
    String message, {
    SnackBarAction? action,
  }) {
    showTopSnackBar(
      context,
      message: message,
      backgroundColor: Colors.green,
      action: action,
    );
  }

  static void showError(
    BuildContext context,
    String message, {
    SnackBarAction? action,
  }) {
    showTopSnackBar(
      context,
      message: message,
      backgroundColor: Colors.red,
      action: action,
    );
  }

  static void showInfo(
    BuildContext context,
    String message, {
    SnackBarAction? action,
  }) {
    showTopSnackBar(
      context,
      message: message,
      backgroundColor: Colors.blue,
      action: action,
    );
  }

  static void showWarning(
    BuildContext context,
    String message, {
    SnackBarAction? action,
  }) {
    showTopSnackBar(
      context,
      message: message,
      backgroundColor: Colors.orange,
      action: action,
    );
  }

  static void showLoading(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    showTopSnackBar(
      context,
      message: message,
      backgroundColor: Colors.blue,
      duration: duration,
      showProgressIndicator: true,
    );
  }
}
