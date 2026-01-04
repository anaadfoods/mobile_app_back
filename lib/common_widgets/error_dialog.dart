import 'package:flutter/material.dart';
import 'package:grocery_app/styles/colors.dart';
import 'package:grocery_app/common_widgets/app_constants.dart';

/// A beautifully themed error dialog that displays user-friendly error messages.
///
/// Matches the application's design system with proper styling for both
/// light and dark themes.
///
/// Usage:
/// ```dart
/// showDialog(
///   context: context,
///   builder: (context) => ErrorDialog(
///     title: 'Something Went Wrong',
///     message: 'Please try again later.',
///     onRetry: () => retry(),
///   ),
/// );
/// ```
class ErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;
  final String? primaryButtonText;
  final String? secondaryButtonText;
  final bool showCloseButton;
  final Color? iconColor;

  const ErrorDialog({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.error_outline_rounded,
    this.onRetry,
    this.onDismiss,
    this.primaryButtonText,
    this.secondaryButtonText,
    this.showCloseButton = true,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final effectiveIconColor = iconColor ?? colorScheme.error;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: AppAnimations.medium,
        curve: AppAnimations.overshootCurve,
        builder: (context, value, child) {
          return Transform.scale(
            scale: 0.8 + (0.2 * value),
            child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
          );
        },
        child: Container(
          constraints: const BoxConstraints(maxWidth: 340),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(AppDecorations.radiusXL),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.4 : 0.15),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with gradient and icon
              _buildHeader(context, effectiveIconColor, isDark),

              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),

                    // Message
                    Text(
                      message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color:
                            isDark ? Colors.grey[400] : AppColors.textSecondary,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Action buttons
                    _buildActions(context, isDark),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color iconColor, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            iconColor.withOpacity(isDark ? 0.25 : 0.12),
            iconColor.withOpacity(isDark ? 0.1 : 0.05),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Close button (if enabled)
          if (showCloseButton)
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 8, bottom: 8),
                child: IconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onDismiss?.call();
                  },
                  icon: Icon(
                    Icons.close_rounded,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    size: 22,
                  ),
                  splashRadius: 24,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),

          // Icon container with glow effect
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconColor.withOpacity(isDark ? 0.2 : 0.15),
              boxShadow: [
                BoxShadow(
                  color: iconColor.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(icon, size: 40, color: iconColor),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, bool isDark) {
    final hasRetry = onRetry != null;

    if (!hasRetry && !showCloseButton) {
      // No actions needed
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Retry/Primary button
        if (hasRetry)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry?.call();
              },
              icon: Icon(
                primaryButtonText == 'Log In'
                    ? Icons.login_rounded
                    : Icons.refresh_rounded,
                size: 20,
              ),
              label: Text(primaryButtonText ?? 'Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),

        // Secondary/Dismiss button
        if (hasRetry && showCloseButton) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onDismiss?.call();
              },
              child: Text(
                secondaryButtonText ?? 'Dismiss',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],

        // Single close button when no retry
        if (!hasRetry && showCloseButton)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onDismiss?.call();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text('OK'),
            ),
          ),
      ],
    );
  }
}

/// Preset error dialogs for common scenarios
class ErrorDialogPresets {
  ErrorDialogPresets._();

  /// Network connection error dialog
  static ErrorDialog networkError({VoidCallback? onRetry}) {
    return ErrorDialog(
      title: 'No Internet Connection',
      message: 'Please check your connection and try again.',
      icon: Icons.wifi_off_rounded,
      iconColor: Colors.orange,
      onRetry: onRetry,
    );
  }

  /// Server error dialog
  static ErrorDialog serverError({VoidCallback? onRetry}) {
    return ErrorDialog(
      title: 'Server Error',
      message:
          'We\'re experiencing technical difficulties. Please try again later.',
      icon: Icons.cloud_off_rounded,
      iconColor: Colors.red.shade600,
      onRetry: onRetry,
    );
  }

  /// Session expired dialog
  static ErrorDialog sessionExpired({VoidCallback? onLogin}) {
    return ErrorDialog(
      title: 'Session Expired',
      message: 'Your session has expired. Please log in again.',
      icon: Icons.lock_outline_rounded,
      iconColor: Colors.amber.shade700,
      primaryButtonText: 'Log In',
      onRetry: onLogin,
      showCloseButton: false,
    );
  }

  /// Generic error dialog
  static ErrorDialog generic({String? message, VoidCallback? onRetry}) {
    return ErrorDialog(
      title: 'Something Went Wrong',
      message: message ?? 'An unexpected error occurred. Please try again.',
      onRetry: onRetry,
    );
  }
}
