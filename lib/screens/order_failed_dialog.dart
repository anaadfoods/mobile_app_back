import 'package:grocery_app/common_widgets/global_import.dart';

class OrderFailedDialog extends StatelessWidget {
  final String? error;

  const OrderFailedDialog({super.key, this.error});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusXL),
      ),
      title: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppColors.spacingL),
            decoration: BoxDecoration(
              color: theme.colorScheme.error.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline,
              color: theme.colorScheme.error,
              size: 48,
            ),
          ),
          const SizedBox(height: AppColors.spacingL),
          Text(
            'Order Failed',
            style: textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            error ?? 'Something went wrong while placing your order.',
            style: textTheme.bodyLarge,
          ),
          const SizedBox(height: AppColors.spacingL),
          Text(
            'Please try again later or contact support if the issue persists.',
            style: textTheme.bodyMedium?.copyWith(color: theme.hintColor),
          ),
        ],
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            child: const Text('OK'),
          ),
        ),
      ],
      actionsPadding: const EdgeInsets.fromLTRB(
        AppColors.spacingL,
        0,
        AppColors.spacingL,
        AppColors.spacingL,
      ),
    );
  }
}
