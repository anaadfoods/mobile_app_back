import 'package:grocery_app/common_widgets/global_import.dart';

class SubscriptionRepaymentButton extends StatelessWidget {
  final Subscription subscription;
  final bool isExpanded;
  final bool showLabel;

  const SubscriptionRepaymentButton({
    super.key,
    required this.subscription,
    this.isExpanded = true,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    // COD restriction: Installments and online repayments are disabled. Return empty box.
    return const SizedBox.shrink();

    /*
    // Logic to verify if payment is pending
    // Using the getter from Subscription model if available or direct check
    final bool isPaymentPending =
        (subscription.installmentInfo?.installmentPaymentStatus ?? '')
            .toUpperCase() ==
        'PENDING';

    if (!isPaymentPending) return const SizedBox.shrink();

    final theme = Theme.of(context);

    Widget buttonContent = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.rawEarth,
            AppColors.rawEarth.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.rawEarth.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: () {
            final handler = SubscriptionHandler(context);
            handler.processUPIRepayment(subscription.id);
          },
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.payment_rounded,
                    color: AppColors.parchment,
                    size: 20,
                  ),
                  if (showLabel) ...[
                    const SizedBox(width: 8),
                    Text(
                      'Pay Now',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppColors.parchment,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (isExpanded) {
      return Expanded(child: buttonContent);
    }

    return buttonContent;
    */
  }
}
