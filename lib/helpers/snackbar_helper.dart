import 'package:flutter/material.dart';
import 'package:grocery_app/core/theme/app_colors.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// SnackBarHelper — Premium ANAAD-themed notification system.
///
/// Light Mode: Clean whites & semantic tints with green/gold/teal accents.
/// Dark Mode: Deep Soil Green base with parchment text.
/// ═══════════════════════════════════════════════════════════════════════════
class SnackBarHelper {
  // ─── Semantic Background Colors ──────────────────────────────────────────
  static const _successBg = AppColors.deepSoilGreen;
  static const _successIcon = AppColors.parchment;
  static const _successText = AppColors.parchment;

  static const _errorBg = AppColors.softRed;
  static const _errorIcon = AppColors.parchment;
  static const _errorText = AppColors.parchment;

  static const _infoBg = AppColors.infoTeal;
  static const _infoIcon = AppColors.parchment;
  static const _infoText = AppColors.parchment;

  static const _warningBg = AppColors.amberWarn;
  static const _warningIcon = AppColors.pureWhite;
  static const _warningText = AppColors.pureWhite;

  static const _networkBg = AppColors.charcoal;
  static const _networkIcon = AppColors.parchment;
  static const _networkText = AppColors.parchment;

  static const _loadingBg = AppColors.deepSoilGreen;

  static void showTopSnackBar(
    BuildContext context, {
    required String message,
    Color backgroundColor = AppColors.deepSoilGreen,
    Color textColor = AppColors.parchment,
    Color iconColor = AppColors.parchment,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
    bool showProgressIndicator = false,
    IconData? icon,
  }) {
    final overlay = Overlay.of(context);
    late final OverlayEntry overlayEntry;
    bool isDismissible = true;

    overlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Material(
              color: AppColors.transparent,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutBack,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, -24 * (1 - value)),
                    child: Opacity(
                      opacity: value.clamp(0.0, 1.0),
                      child: child,
                    ),
                  );
                },
                child: GestureDetector(
                  onTap: () {
                    if (isDismissible && overlayEntry.mounted) {
                      overlayEntry.remove();
                    }
                  },
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
                          color: backgroundColor.withValues(alpha: 0.35),
                          blurRadius: 20,
                          spreadRadius: 0,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: AppColors.charcoal.withValues(alpha: 0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        if (icon != null) ...[
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: AppColors.pureWhite.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(icon, color: iconColor, size: 18),
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
                                iconColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: Text(
                            message,
                            style: TextStyle(
                              color: textColor,
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
                              backgroundColor: AppColors.pureWhite.withValues(alpha: 0.2),
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
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                        if (isDismissible && action == null) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              if (overlayEntry.mounted) overlayEntry.remove();
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.pureWhite.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                color: iconColor,
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

  /// ═══════════════════════════════════════════════════════════════════════════
  /// Success — Deep Soil Green with checkmark (brand primary)
  /// ═══════════════════════════════════════════════════════════════════════════
  static void showSuccess(
    BuildContext context,
    String message, {
    SnackBarAction? action,
  }) {
    showTopSnackBar(
      context,
      message: message,
      backgroundColor: _successBg,
      textColor: _successText,
      iconColor: _successIcon,
      icon: Icons.check_circle_outline_rounded,
      action: action,
    );
  }

  /// ═══════════════════════════════════════════════════════════════════════════
  /// Invoice downloaded — premium two-line toast
  /// ═══════════════════════════════════════════════════════════════════════════
  static void showInvoiceDownloaded(BuildContext context) {
    final overlay = Overlay.of(context);
    late final OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        child: Material(
          color: AppColors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, -24 * (1 - value)),
                child: Opacity(
                  opacity: value.clamp(0.0, 1.0),
                  child: child,
                ),
              );
            },
            child: GestureDetector(
              onTap: () {
                if (overlayEntry.mounted) overlayEntry.remove();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: _successBg,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _successBg.withValues(alpha: 0.35),
                      blurRadius: 20,
                      spreadRadius: 0,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: AppColors.charcoal.withValues(alpha: 0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Icon badge
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.pureWhite.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.download_done_rounded,
                        color: _successIcon,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Title + subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Invoice Downloaded Successfully',
                            style: TextStyle(
                              color: _successText,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Your invoice is ready. Please check your Downloads folder.',
                            style: TextStyle(
                              color: _successText.withValues(alpha: 0.82),
                              fontWeight: FontWeight.w400,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Dismiss
                    GestureDetector(
                      onTap: () {
                        if (overlayEntry.mounted) overlayEntry.remove();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.pureWhite.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: _successIcon,
                          size: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 5), () {
      if (overlayEntry.mounted) overlayEntry.remove();
    });
  }

  /// ═══════════════════════════════════════════════════════════════════════════
  /// Error — Terracotta red (warm, not scary)
  /// ═══════════════════════════════════════════════════════════════════════════
  static void showError(
    BuildContext context,
    String message, {
    SnackBarAction? action,
  }) {
    showTopSnackBar(
      context,
      message: message,
      backgroundColor: _errorBg,
      textColor: _errorText,
      iconColor: _errorIcon,
      icon: Icons.sentiment_neutral_rounded,
      action: action,
    );
  }

  /// ═══════════════════════════════════════════════════════════════════════════
  /// Info — Deep Teal with lightbulb
  /// ═══════════════════════════════════════════════════════════════════════════
  static void showInfo(
    BuildContext context,
    String message, {
    SnackBarAction? action,
  }) {
    showTopSnackBar(
      context,
      message: message,
      backgroundColor: _infoBg,
      textColor: _infoText,
      iconColor: _infoIcon,
      icon: Icons.lightbulb_outline_rounded,
      action: action,
    );
  }

  /// ═══════════════════════════════════════════════════════════════════════════
  /// Warning — Rich golden amber
  /// ═══════════════════════════════════════════════════════════════════════════
  static void showWarning(
    BuildContext context,
    String message, {
    SnackBarAction? action,
  }) {
    showTopSnackBar(
      context,
      message: message,
      backgroundColor: _warningBg,
      textColor: _warningText,
      iconColor: _warningIcon,
      icon: Icons.tips_and_updates_outlined,
      action: action,
    );
  }

  /// ═══════════════════════════════════════════════════════════════════════════
  /// Loading — Deep Soil Green with spinner
  /// ═══════════════════════════════════════════════════════════════════════════
  static void showLoading(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    showTopSnackBar(
      context,
      message: message,
      backgroundColor: _loadingBg,
      textColor: AppColors.parchment,
      iconColor: AppColors.parchment,
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
      backgroundColor: _networkBg,
      textColor: _networkText,
      iconColor: _networkIcon,
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
      backgroundColor: _errorBg,
      textColor: _errorText,
      iconColor: _errorIcon,
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
      backgroundColor: _errorBg,
      textColor: _errorText,
      iconColor: _errorIcon,
      icon: Icons.refresh_rounded,
      action: action,
    );
  }

  /// Session expired
  static void showSessionExpired(BuildContext context, {VoidCallback? onLogin}) {
    showTopSnackBar(
      context,
      message: "Your session took a nap. Please log in again 💤",
      backgroundColor: _warningBg,
      textColor: _warningText,
      iconColor: _warningIcon,
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
      backgroundColor: _errorBg,
      textColor: _errorText,
      iconColor: _errorIcon,
      icon: Icons.payment_rounded,
      duration: const Duration(seconds: 4),
    );
  }

  /// Request timeout
  static void showTimeout(BuildContext context, {SnackBarAction? action}) {
    showTopSnackBar(
      context,
      message: "Taking too long... Let's give it another shot! ⏱️",
      backgroundColor: _networkBg,
      textColor: _networkText,
      iconColor: _networkIcon,
      icon: Icons.timer_off_outlined,
      action: action,
    );
  }

  /// Item not found
  static void showNotFound(BuildContext context, {String? item}) {
    showTopSnackBar(
      context,
      message: "Couldn't find ${item ?? 'that'}. It might have moved! 🔍",
      backgroundColor: _infoBg,
      textColor: _infoText,
      iconColor: _infoIcon,
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
      backgroundColor: _warningBg,
      textColor: _warningText,
      iconColor: _warningIcon,
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
