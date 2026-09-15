import 'package:grocery_app/common_widgets/global_import.dart';

/// Themed order failed dialog using the app's error dialog system.
///
/// Usage:
/// ```dart
/// showDialog(
///   context: context,
///   builder: (_) => OrderFailedDialog(error: 'Payment failed'),
/// );
/// ```
class OrderFailedDialog extends StatelessWidget {
  final String? error;
  final VoidCallback? onRetry;

  const OrderFailedDialog({super.key, this.error, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ErrorDialog(
      title: 'Order Failed',
      message:
          error ??
          'Something went wrong while placing your order. Please try again or contact support if the issue persists.',
      icon: Icons.shopping_cart_checkout_rounded,
      iconColor: Theme.of(context).colorScheme.error,
      onRetry: onRetry,
      primaryButtonText: onRetry != null ? 'Try Again' : null,
    );
  }
}
