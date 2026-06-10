import 'package:flutter/material.dart';
import 'package:grocery_app/core/theme/theme.dart';

/// A reusable error state widget for showing when something goes wrong.
///
/// Consolidates the various error state implementations across the app.
///
/// Usage:
/// ```dart
/// ErrorStateWidget(
///   title: 'Something went wrong',
///   subtitle: 'Please try again later.',
///   onRetry: () => reload(),
/// )
/// ```
class ErrorStateWidget extends StatelessWidget {
  /// The title text (default: 'Oops! Something went wrong')
  final String title;

  /// The subtitle/description text
  final String? subtitle;

  /// Retry button text (default: 'Try Again')
  final String retryText;

  /// Callback when retry is pressed
  final VoidCallback? onRetry;

  /// The icon to display (default: error_outline)
  final IconData icon;

  /// Icon color (defaults to error color)
  final Color? iconColor;

  /// Icon background color
  final Color? iconBackgroundColor;

  /// Whether to animate the entrance
  final bool animated;

  /// Icon size (default: 64)
  final double iconSize;

  /// Error type for preset styling
  final ErrorType errorType;

  const ErrorStateWidget({
    super.key,
    this.title = 'Oops! Something went wrong',
    this.subtitle,
    this.retryText = 'Try Again',
    this.onRetry,
    this.icon = Icons.error_outline_rounded,
    this.iconColor,
    this.iconBackgroundColor,
    this.animated = true,
    this.iconSize = 64,
    this.errorType = ErrorType.general,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final errorColor = _getErrorColor(colorScheme);

    final content = Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon Container with gradient
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    (iconBackgroundColor ?? errorColor).withValues(alpha: 0.15),
                    (iconBackgroundColor ?? errorColor).withValues(alpha: 0.05),
                  ],
                ),
              ),
              child: Icon(
                _getIcon(),
                size: iconSize,
                color: iconColor ?? errorColor,
              ),
            ),
            AppSpacing.verticalXl,

            // Title
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            // Subtitle
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            // Retry Button
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: Text(retryText),
                style: ElevatedButton.styleFrom(
                  backgroundColor: errorColor,
                  foregroundColor: AppColors.parchment,
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.md,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (animated) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: Transform.scale(scale: 0.8 + (0.2 * value), child: child),
          );
        },
        child: content,
      );
    }

    return content;
  }

  Color _getErrorColor(ColorScheme colorScheme) {
    switch (errorType) {
      case ErrorType.general:
        return AppColors.rawEarth;
      case ErrorType.network:
        return AppColors.charcoal54;
      case ErrorType.server:
        return AppColors.rawEarth;
      case ErrorType.notFound:
        return AppColors.deepSoilGreen;
      case ErrorType.permission:
        return AppColors.harvestAmber;
    }
  }

  IconData _getIcon() {
    if (icon != Icons.error_outline_rounded) return icon;

    switch (errorType) {
      case ErrorType.general:
        return Icons.error_outline_rounded;
      case ErrorType.network:
        return Icons.wifi_off_rounded;
      case ErrorType.server:
        return Icons.cloud_off_rounded;
      case ErrorType.notFound:
        return Icons.search_off_rounded;
      case ErrorType.permission:
        return Icons.lock_outline_rounded;
    }
  }
}

/// Types of errors for preset styling
enum ErrorType { general, network, server, notFound, permission }

/// Preset error states for common use cases - Friendly messages!
class ErrorStatePresets {
  /// Network error - cool slate grey
  static ErrorStateWidget network({VoidCallback? onRetry}) {
    return ErrorStateWidget(
      title: 'Oops! You\'re Offline 📶',
      subtitle:
          'Your internet took a coffee break.\nCheck your connection and try again.',
      errorType: ErrorType.network,
      onRetry: onRetry,
    );
  }

  /// Server error - warm mocha
  static ErrorStateWidget server({VoidCallback? onRetry}) {
    return ErrorStateWidget(
      title: 'Our Servers Need a Moment ☕',
      subtitle: 'We\'re working on it! Please try again shortly.',
      errorType: ErrorType.server,
      onRetry: onRetry,
    );
  }

  /// Not found error - soft teal
  static ErrorStateWidget notFound({String? item}) {
    return ErrorStateWidget(
      title: '${item ?? 'Item'} Not Found 🔍',
      subtitle:
          'Hmm, we couldn\'t find that.\nIt might have moved or been removed.',
      errorType: ErrorType.notFound,
    );
  }

  /// Permission denied - golden amber
  static ErrorStateWidget permission({VoidCallback? onSettings}) {
    return ErrorStateWidget(
      title: 'Permission Needed 🔐',
      subtitle: 'Please grant the required permission to continue.',
      errorType: ErrorType.permission,
      retryText: 'Open Settings',
      onRetry: onSettings,
    );
  }

  /// Generic load failed - warm mocha
  static ErrorStateWidget loadFailed({VoidCallback? onRetry}) {
    return ErrorStateWidget(
      title: 'Hmm, That Didn\'t Load 🔄',
      subtitle: 'Something went sideways. Let\'s try again!',
      onRetry: onRetry,
    );
  }
}
