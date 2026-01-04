import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:grocery_app/services/api_exception.dart';
import 'package:grocery_app/common_widgets/error_dialog.dart';
import 'package:grocery_app/helpers/snackbar_helper.dart';

/// Centralized error handling helper that converts technical errors
/// into user-friendly messages with proper themed UI presentation.
///
/// Usage:
/// ```dart
/// try {
///   await apiCall();
/// } catch (e) {
///   AppErrorHelper.showErrorDialog(context, error: e, onRetry: retry);
/// }
/// ```
class AppErrorHelper {
  AppErrorHelper._();

  /// Maps HTTP status codes and exceptions to user-friendly messages
  static String getErrorMessage(dynamic error) {
    // Handle ApiException with status codes
    if (error is ApiException) {
      return _getMessageForStatusCode(error.statusCode, error.message);
    }

    // Handle SocketException (network errors)
    if (error is SocketException) {
      return 'Unable to connect to the server. Please check your internet connection and try again.';
    }

    // Handle TimeoutException
    if (error is TimeoutException) {
      return 'The request took too long. Please check your connection and try again.';
    }

    // Handle FormatException (parsing errors)
    if (error is FormatException) {
      return 'We received an unexpected response. Please try again later.';
    }

    // Handle generic exceptions
    if (error is Exception) {
      final message = error.toString().toLowerCase();

      // Check for common error patterns
      if (message.contains('socket') ||
          message.contains('network') ||
          message.contains('connection')) {
        return 'Unable to connect. Please check your internet connection.';
      }

      if (message.contains('timeout')) {
        return 'Connection timed out. Please try again.';
      }

      if (message.contains('handshake') || message.contains('certificate')) {
        return 'Secure connection failed. Please try again later.';
      }
    }

    // Default message
    return 'Something went wrong. Please try again.';
  }

  /// Maps HTTP status codes to user-friendly messages
  static String _getMessageForStatusCode(
    int? statusCode,
    String? originalMessage,
  ) {
    if (statusCode == null) {
      return originalMessage ?? 'Something went wrong. Please try again.';
    }

    switch (statusCode) {
      case 400:
        return originalMessage ??
            'Invalid request. Please check your information and try again.';
      case 401:
        return 'Your session has expired. Please log in again.';
      case 403:
        return 'You don\'t have permission to perform this action.';
      case 404:
        return 'The requested item could not be found.';
      case 408:
        return 'Request timed out. Please try again.';
      case 422:
        return originalMessage ??
            'The provided data is invalid. Please check and try again.';
      case 429:
        return 'Too many requests. Please wait a moment and try again.';
      case 500:
        return 'We\'re experiencing technical difficulties. Please try again later.';
      case 502:
        return 'Our servers are temporarily unavailable. Please try again in a moment.';
      case 503:
        return 'Service temporarily unavailable. We\'re working on it!';
      case 504:
        return 'Server took too long to respond. Please try again.';
      default:
        if (statusCode >= 500) {
          return 'Server error occurred. Please try again later.';
        }
        if (statusCode >= 400) {
          return originalMessage ?? 'Request failed. Please try again.';
        }
        return 'Something went wrong. Please try again.';
    }
  }

  /// Gets error title based on the error type
  static String getErrorTitle(dynamic error) {
    if (error is ApiException) {
      final code = error.statusCode;
      if (code != null) {
        if (code == 401 || code == 403) return 'Session Expired';
        if (code == 404) return 'Not Found';
        if (code >= 500) return 'Server Error';
        if (code >= 400) return 'Request Failed';
      }
    }

    if (error is SocketException) return 'Connection Error';
    if (error is TimeoutException) return 'Request Timeout';

    return 'Oops! Something Went Wrong';
  }

  /// Gets the appropriate icon for the error type
  static IconData getErrorIcon(dynamic error) {
    if (error is ApiException) {
      final code = error.statusCode;
      if (code != null) {
        if (code == 401 || code == 403) return Icons.lock_outline_rounded;
        if (code == 404) return Icons.search_off_rounded;
        if (code >= 500) return Icons.cloud_off_rounded;
      }
    }

    if (error is SocketException) return Icons.wifi_off_rounded;
    if (error is TimeoutException) return Icons.timer_off_rounded;

    return Icons.error_outline_rounded;
  }

  /// Shows a themed error dialog with optional retry action
  static Future<void> showErrorDialog(
    BuildContext context, {
    required dynamic error,
    String? customTitle,
    String? customMessage,
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
    bool barrierDismissible = true,
  }) async {
    final title = customTitle ?? getErrorTitle(error);
    final message = customMessage ?? getErrorMessage(error);
    final icon = getErrorIcon(error);

    return showDialog<void>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder:
          (context) => ErrorDialog(
            title: title,
            message: message,
            icon: icon,
            onRetry: onRetry,
            onDismiss: onDismiss,
          ),
    );
  }

  /// Shows a quick error snackbar (for non-critical errors)
  static void showErrorSnackbar(
    BuildContext context, {
    required dynamic error,
    String? customMessage,
    SnackBarAction? action,
  }) {
    final message = customMessage ?? getErrorMessage(error);
    SnackBarHelper.showError(context, message, action: action);
  }

  /// Shows a themed network error dialog
  static Future<void> showNetworkError(
    BuildContext context, {
    VoidCallback? onRetry,
  }) async {
    return showErrorDialog(
      context,
      error: SocketException('Network error'),
      customTitle: 'No Internet Connection',
      customMessage: 'Please check your connection and try again.',
      onRetry: onRetry,
    );
  }

  /// Shows a themed server error dialog
  static Future<void> showServerError(
    BuildContext context, {
    VoidCallback? onRetry,
  }) async {
    return showErrorDialog(
      context,
      error: ApiException('Server error', 500),
      customTitle: 'Server Error',
      customMessage:
          'We\'re experiencing technical difficulties. Please try again later.',
      onRetry: onRetry,
    );
  }

  /// Shows a themed session expired dialog
  static Future<void> showSessionExpired(
    BuildContext context, {
    VoidCallback? onLogin,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => ErrorDialog(
            title: 'Session Expired',
            message:
                'Your session has expired. Please log in again to continue.',
            icon: Icons.lock_outline_rounded,
            primaryButtonText: 'Log In',
            onRetry: onLogin,
            showCloseButton: false,
          ),
    );
  }
}
