import 'package:grocery_app/common_widgets/global_import.dart';

class OrderAcceptedScreen extends StatefulWidget {
  final OrderModel? order;
  final PaymentStatus? paymentStatus;
  final SubscriptionPaymentStatus? subscriptionPaymentStatus;
  final bool? isSubscription;

  const OrderAcceptedScreen({
    super.key,
    this.order,
    this.paymentStatus,
    this.isSubscription,
    this.subscriptionPaymentStatus,
  });

  @override
  State<OrderAcceptedScreen> createState() => _OrderAcceptedScreenState();
}

class _OrderAcceptedScreenState extends State<OrderAcceptedScreen> {
  Timer? _redirectTimer;
  int _countdown = 3;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    // Start countdown display
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _countdown > 0) {
        setState(() => _countdown--);
      }
    });
    // Auto-redirect after 3 seconds
    _redirectTimer = Timer(const Duration(seconds: 3), _autoRedirect);
  }

  @override
  void dispose() {
    _redirectTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _autoRedirect() {
    if (!mounted) return;
    final orderId = widget.paymentStatus?.orderId;
    final subscriptionId = widget.subscriptionPaymentStatus?.subscriptionId;

    if (widget.isSubscription == true && subscriptionId != null) {
      // Navigate to subscription details
      Navigator.of(context).popUntil((route) => route.isFirst);
      NavigationService.navigateToSubscriptionDetails(subscriptionId as String);
    } else if (orderId != null) {
      // Navigate to order details
      Navigator.of(context).popUntil((route) => route.isFirst);
      NavigationService.navigateToOrderDetails(orderId as String);
    } else {
      // Fallback: go home
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;

    // Determine which data source to use
    final orderNumber =
        widget.order?.orderNumber ?? widget.paymentStatus?.orderNumber ?? 'N/A';
    final totalAmount =
        widget.order?.total ?? widget.paymentStatus?.amount.toString() ?? 'N/A';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.harvestAmber.withValues(alpha: 0.1),
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
                      color: AppColors.harvestAmber.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.harvestAmber.withValues(alpha: 0.2),
                          blurRadius: 24,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.check_circle,
                      size: 80,
                      color: AppColors.harvestAmber,
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
                            isDark ? AppColors.charcoal87 : AppColors.parchment,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.shadowColor.withValues(
                            alpha: AppColors.shadowOpacityLight,
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
                        if (widget.paymentStatus?.transactionId != null &&
                            widget.paymentStatus!.transactionId.isNotEmpty) ...[
                          Divider(
                            height: AppColors.spacingXL * 2,
                            color:
                                isDark
                                    ? AppColors.charcoal87
                                    : AppColors.parchment,
                          ),
                          _buildDetailRow(
                            context,
                            icon: Icons.payment_outlined,
                            label: 'Transaction ID',
                            value: widget.paymentStatus!.transactionId,
                          ),
                        ],
                        Divider(
                          height: AppColors.spacingXL * 2,
                          color:
                              isDark
                                  ? AppColors.charcoal87
                                  : AppColors.parchment,
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
                  const SizedBox(height: AppColors.spacingL),

                  // Auto-redirect indicator
                  Text(
                    _countdown > 0
                        ? 'Redirecting in $_countdown seconds...'
                        : 'Redirecting...',
                    style: textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                  const SizedBox(height: AppColors.spacingL),

                  // Continue Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _redirectTimer?.cancel();
                        _countdownTimer?.cancel();
                        Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.harvestAmber,
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
            color: (isPrimary
                    ? AppColors.harvestAmber
                    : AppColors.harvestAmber)
                .withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppColors.radiusS),
          ),
          child: Icon(
            icon,
            color:
                isPrimary ? AppColors.harvestAmber : AppColors.harvestAmber,
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
                  color: isPrimary ? AppColors.harvestAmber : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
