import 'package:grocery_app/common_widgets/global_import.dart';

class OrderAcceptedScreen extends StatelessWidget {
  final OrderModel? order;
  final PaymentStatus? paymentStatus;
  final bool? isSubscription;

  const OrderAcceptedScreen({
    super.key,
    this.order,
    this.paymentStatus,
    this.isSubscription,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;

    // Determine which data source to use
    final orderNumber =
        order?.orderNumber ?? paymentStatus?.orderNumber ?? 'N/A';
    final totalAmount =
        order?.total ?? paymentStatus?.amount.toString() ?? 'N/A';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.success.withOpacity(0.1),
              theme.scaffoldBackgroundColor,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppColors.spacingXL),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Success Icon with glow
                  Container(
                    padding: const EdgeInsets.all(AppColors.spacingXL),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.success.withOpacity(0.2),
                          blurRadius: 24,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.check_circle,
                      size: 80,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(height: AppColors.spacingXL),

                  // Success Message
                  Text(
                    'Order Placed Successfully!',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppColors.spacingXL),

                  // Order Details Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppColors.spacingXL),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(AppColors.radiusL),
                      border: Border.all(
                        color:
                            isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade200,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.shadowColor.withOpacity(
                            AppColors.shadowOpacityLight,
                          ),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow(
                          context,
                          icon: Icons.receipt_long_outlined,
                          label: 'Order Number',
                          value: orderNumber,
                        ),
                        if (paymentStatus?.transactionId != null &&
                            paymentStatus!.transactionId.isNotEmpty) ...[
                          Divider(
                            height: AppColors.spacingXL * 2,
                            color:
                                isDark
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade200,
                          ),
                          _buildDetailRow(
                            context,
                            icon: Icons.payment_outlined,
                            label: 'Transaction ID',
                            value: paymentStatus!.transactionId,
                          ),
                        ],
                        Divider(
                          height: AppColors.spacingXL * 2,
                          color:
                              isDark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade200,
                        ),
                        _buildDetailRow(
                          context,
                          icon: Icons.currency_rupee,
                          label: 'Total Amount',
                          value: '₹$totalAmount',
                          isPrimary: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppColors.spacingXXL),

                  // Continue Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppColors.spacingL,
                        ),
                      ),
                      child: const Text('Continue Shopping'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool isPrimary = false,
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppColors.spacingS),
          decoration: BoxDecoration(
            color: (isPrimary ? theme.colorScheme.primary : AppColors.success)
                .withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppColors.radiusS),
          ),
          child: Icon(
            icon,
            color: isPrimary ? theme.colorScheme.primary : AppColors.success,
            size: 20,
          ),
        ),
        const SizedBox(width: AppColors.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                ),
              ),
              const SizedBox(height: AppColors.spacingXS),
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isPrimary ? theme.colorScheme.primary : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
