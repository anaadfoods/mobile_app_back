import 'package:flutter/material.dart';

/// Friendly snackbar helper with app-themed colors
/// Uses warm, friendly tones - no scary red colors!
class SnackBarHelper {
  // Friendly color palette matching app theme
  static const _successColor = Color(0xFF3f5e46);    // App primary green
  static const _errorColor = Color(0xFF8B7355);      // Warm mocha - friendly, not scary
  static const _infoColor = Color(0xFF5B8A9A);       // Soft teal blue
  static const _warningColor = Color(0xFFB8860B);    // Dark golden
  static const _networkColor = Color(0xFF6B7B8A);    // Cool slate grey

  static void showTopSnackBar(
    BuildContext context, {
    required String message,
    Color backgroundColor = const Color(0xFF3f5e46),
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
    bool showProgressIndicator = false,
    IconData? icon,
  }) {
    final overlay = Overlay.of(context);
    late final OverlayEntry overlayEntry;
    bool isDismissible = true;

    final shadowColor = backgroundColor.withValues(alpha: 0.4);

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
                child: GestureDetector(
                  // Make it dismissible by tapping anywhere on the snackbar
                  onTap: () {
                    if (isDismissible && overlayEntry.mounted) {
                      overlayEntry.remove();
                    }
                  },
                  // Make it dismissible by swiping down
                  onPanEnd: (details) {
                    if (isDismissible && details.velocity.pixelsPerSecond.dy > 300) {
                      if (overlayEntry.mounted) overlayEntry.remove();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: shadowColor,
                          blurRadius: 16,
                          spreadRadius: 1,
                          offset: const Offset(0, 6),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        if (icon != null) ...[
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(icon, color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 12),
                        ],
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
                              height: 1.3,
                            ),
                          ),
                        ),
                        if (action != null) ...[
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () {
                              if (overlayEntry.mounted) overlayEntry.remove();
                              action.onPressed();
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.white.withValues(alpha: 0.2),
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
                        // Add close button for manual dismissal
                        if (isDismissible && action == null) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              if (overlayEntry.mounted) overlayEntry.remove();
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
    );

    overlay.insert(overlayEntry);
    
    // Auto-dismiss with proper cleanup
    Future.delayed(duration, () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  /// Success - App primary green with checkmark
  static void showSuccess(
    BuildContext context,
    String message, {
    SnackBarAction? action,
  }) {
    showTopSnackBar(
      context,
      message: message,
      backgroundColor: _successColor,
      icon: Icons.check_circle_outline_rounded,
      action: action,
    );
  }

  /// Error - Warm mocha (NOT red!) with info icon
  static void showError(
    BuildContext context,
    String message, {
    SnackBarAction? action,
  }) {
    showTopSnackBar(
      context,
      message: message,
      backgroundColor: _errorColor,
      icon: Icons.sentiment_neutral_rounded,
      action: action,
    );
  }

  /// Info - Soft teal with lightbulb
  static void showInfo(
    BuildContext context,
    String message, {
    SnackBarAction? action,
  }) {
    showTopSnackBar(
      context,
      message: message,
      backgroundColor: _infoColor,
      icon: Icons.lightbulb_outline_rounded,
      action: action,
    );
  }

  /// Warning - Golden amber
  static void showWarning(
    BuildContext context,
    String message, {
    SnackBarAction? action,
  }) {
    showTopSnackBar(
      context,
      message: message,
      backgroundColor: _warningColor,
      icon: Icons.tips_and_updates_outlined,
      action: action,
    );
  }

  /// Loading indicator
  static void showLoading(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    showTopSnackBar(
      context,
      message: message,
      backgroundColor: _infoColor,
      duration: duration,
      showProgressIndicator: true,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FRIENDLY ERROR MESSAGES - Cool texts for common scenarios
  // ═══════════════════════════════════════════════════════════════════════════

  /// Network/WiFi connection issue
  static void showNetworkError(BuildContext context, {SnackBarAction? action}) {
    showTopSnackBar(
      context,
      message: "Oops! Looks like you're offline. Check your connection 📶",
      backgroundColor: _networkColor,
      icon: Icons.wifi_off_rounded,
      action: action,
      duration: const Duration(seconds: 4),
    );
  }

  /// Server is having issues
  static void showServerError(BuildContext context, {SnackBarAction? action}) {
    showTopSnackBar(
      context,
      message: "Our servers need a quick break. Try again shortly! ☕",
      backgroundColor: _errorColor,
      icon: Icons.cloud_outlined,
      action: action,
      duration: const Duration(seconds: 4),
    );
  }

  /// Generic "something went wrong"
  static void showSomethingWrong(BuildContext context, {SnackBarAction? action}) {
    showTopSnackBar(
      context,
      message: "Hmm, that didn't work. Let's try again! 🔄",
      backgroundColor: _errorColor,
      icon: Icons.refresh_rounded,
      action: action,
    );
  }

  /// Session expired
  static void showSessionExpired(BuildContext context, {VoidCallback? onLogin}) {
    showTopSnackBar(
      context,
      message: "Your session took a nap. Please log in again 💤",
      backgroundColor: _warningColor,
      icon: Icons.access_time_rounded,
      action: onLogin != null
          ? SnackBarAction(label: 'Log In', onPressed: onLogin)
          : null,
      duration: const Duration(seconds: 5),
    );
  }

  /// Payment issue
  static void showPaymentIssue(BuildContext context, {String? message}) {
    showTopSnackBar(
      context,
      message: message ?? "Payment got stuck. No worries, try once more! 💳",
      backgroundColor: _errorColor,
      icon: Icons.payment_rounded,
      duration: const Duration(seconds: 4),
    );
  }

  /// Request timeout
  static void showTimeout(BuildContext context, {SnackBarAction? action}) {
    showTopSnackBar(
      context,
      message: "Taking too long... Let's give it another shot! ⏱️",
      backgroundColor: _networkColor,
      icon: Icons.timer_off_outlined,
      action: action,
    );
  }

  /// Item not found
  static void showNotFound(BuildContext context, {String? item}) {
    showTopSnackBar(
      context,
      message: "Couldn't find ${item ?? 'that'}. It might have moved! 🔍",
      backgroundColor: _infoColor,
      icon: Icons.search_off_rounded,
    );
  }

  /// Copied to clipboard
  static void showCopied(BuildContext context, {String? what}) {
    showSuccess(context, "${what ?? 'Copied'} to clipboard! 📋");
  }

  /// Connection restored
  static void showBackOnline(BuildContext context) {
    showSuccess(context, "You're back online! Welcome back 🎉");
  }

  /// Action not allowed
  static void showNotAllowed(BuildContext context, {String? reason}) {
    showTopSnackBar(
      context,
      message: reason ?? "This action isn't available right now 🚫",
      backgroundColor: _warningColor,
      icon: Icons.block_rounded,
    );
  }

  /// Saved successfully
  static void showSaved(BuildContext context, {String? what}) {
    showSuccess(context, "${what ?? 'Changes'} saved successfully! ✨");
  }

  /// Feature coming soon
  static void showComingSoon(BuildContext context) {
    showInfo(context, "This feature is coming soon! Stay tuned 🚀");
  }
}
