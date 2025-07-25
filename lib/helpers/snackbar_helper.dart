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
    overlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(8),
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showProgressIndicator)
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
                    if (showProgressIndicator) SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        message,
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    if (action != null)
                      TextButton(
                        onPressed: () {
                          overlayEntry.remove();
                          action.onPressed();
                        },
                        child: Text(
                          action.label,
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                  ],
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
