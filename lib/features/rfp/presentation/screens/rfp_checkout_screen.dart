import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:grocery_app/common_widgets/app_button.dart';
import 'package:grocery_app/common_widgets/modern_back_button.dart';
import 'package:grocery_app/core/theme/app_colors.dart';
import 'package:grocery_app/core/theme/app_spacing.dart';
import 'package:grocery_app/core/theme/app_text_styles.dart';
import 'package:url_launcher/url_launcher.dart';
import '../cubit/rfp_checkout_cubit.dart';
import '../cubit/rfp_batch_cubit.dart';
import '../rfp_theme.dart';
import '../widgets/rfp_fresh_harvest_ledger.dart';
import '../widgets/rfp_split_payment_section.dart';
import '../widgets/rfp_checkout_address_section.dart';

/// Harvest Subscription ORDER SUMMARY screen.
///
/// Allows the user to review selected RFP plans, configurations, delivery days,
/// delivery address, and live split pricing returned by the backend /calculate/ endpoint
/// before proceeding to payment.
class RfpCheckoutScreen extends StatefulWidget {
  const RfpCheckoutScreen({super.key});

  @override
  State<RfpCheckoutScreen> createState() => _RfpCheckoutScreenState();
}

class _RfpCheckoutScreenState extends State<RfpCheckoutScreen> {
  String _fmt(num n) => n.toInt().toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<RfpCheckoutCubit>().loadSavedAddresses();

        final bs = context.read<RfpBatchCubit>().state;
        if (bs.pricing == null && !bs.isPricingLoading) {
          context.read<RfpBatchCubit>().recalculatePricing();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<RfpCheckoutCubit, RfpCheckoutState>(
      listener: (context, state) {
        if (state.status == CheckoutStatus.success) {
          context.go('/rfp/payment-success');
        } else if (state.status == CheckoutStatus.error &&
            state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!),
              backgroundColor: RfpTheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        final bs = context.watch<RfpBatchCubit>().state;
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: AppSpacing.sm),
                              _buildHeader(context),
                              const SizedBox(height: AppSpacing.xl),
                              RfpFreshHarvestLedger(
                                plans:
                                    bs.selectedPlans.isNotEmpty
                                        ? bs.selectedPlans
                                        : (bs.selectedPlan != null
                                            ? [bs.selectedPlan!]
                                            : const []),
                                planConfigurations: bs.planConfigurations,
                                batch: bs.selectedBatch,
                                pricing: bs.pricing,
                                plan: bs.selectedPlan,
                                variant: bs.selectedPricingVariant,
                                frequency: bs.selectedFrequency,
                                deliveryDays: bs.selectedDeliveryDays,
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              RfpSplitPaymentSection(
                                plan: bs.selectedPlan,
                                batch: bs.selectedBatch,
                                pricing: bs.pricing,
                                selectedPaymentType: state.paymentType,
                                onPaymentTypeChanged:
                                    (type) => context
                                        .read<RfpCheckoutCubit>()
                                        .selectPaymentType(type),
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              RfpCheckoutAddressSection(state: state),
                              const SizedBox(height: AppSpacing.xl),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildPayButton(context, state, bs),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        ModernBackButton(
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/rfp/batches');
            }
          },
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'HARVEST SUBSCRIPTION',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: isDark ? AppColors.parchment70 : AppColors.charcoal60,
                ),
              ),
              Text(
                'Order Summary',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.pureWhite : AppColors.charcoal,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.deepSoilGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppColors.radiusRound),
            border: Border.all(
              color: AppColors.deepSoilGreen.withValues(alpha: 0.2),
              width: 0.8,
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 13,
                color: AppColors.deepSoilGreen,
              ),
              SizedBox(width: 4),
              Text(
                'Secure SSL',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.deepSoilGreen,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPayButton(
    BuildContext context,
    RfpCheckoutState state,
    RfpBatchState bs,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSubmitting = state.status == CheckoutStatus.submitting;
    final isVerifying = state.isVerifyingPayment;
    final inProgress = isSubmitting || isVerifying;

    final hasPlans = bs.selectedPlanIds.isNotEmpty || bs.selectedPlan != null;
    final hasPricing = bs.pricing != null;
    final canBook =
        state.canSubmit &&
        hasPlans &&
        hasPricing &&
        !bs.isPricingLoading &&
        !inProgress;

    final payNowAmount =
        (bs.pricing?.bookingAmount ?? bs.selectedPlan?.bookingAmount ?? 0)
            .toInt();
    final totalAmount =
        (bs.pricing?.finalPrice ?? bs.selectedPlan?.totalPrice ?? 0).toInt();

    String buttonLabel;
    if (isVerifying) {
      buttonLabel = 'Verifying Payment with Farm...';
    } else if (isSubmitting) {
      buttonLabel = 'Processing Booking...';
    } else if (bs.isPricingLoading) {
      buttonLabel = 'Calculating Pricing...';
    } else if (!hasPlans) {
      buttonLabel = 'Select a Plan to Continue';
    } else if (!state.canSubmit) {
      buttonLabel = 'Enter Delivery Address to Book';
    } else if (state.paymentType == 'full') {
      buttonLabel = 'PAY IN FULL: ₹${_fmt(totalAmount)}';
    } else if (payNowAmount > 0) {
      buttonLabel = 'PAY BOOKING AMOUNT: ₹${_fmt(payNowAmount)}';
    } else {
      buttonLabel = 'PAY TOTAL AMOUNT: ₹${_fmt(totalAmount)}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.charcoal12,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.charcoal.withValues(
              alpha: isDark ? 0.2 : AppColors.shadowOpacityLight,
            ),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (state.verificationFailed) ...[
              Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: RfpTheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: RfpTheme.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 18,
                      color: RfpTheme.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.error ?? 'Payment verification failed',
                        style: const TextStyle(
                          fontSize: 11,
                          color: RfpTheme.error,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      onPressed:
                          () =>
                              context.read<RfpCheckoutCubit>().verifyPayment(),
                      child: const Text(
                        'Retry Verify',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          color: RfpTheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            AppButton(
              label: buttonLabel,
              color: AppColors.deepSoilGreen,
              textColor: AppColors.parchment,
              roundness: AppColors.radiusM,
              onPressed:
                  canBook ? () => _handlePaymentFlow(context, state, bs) : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Instant UPI & Cards • 100% Soil-to-Door Farm Escrow',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 11,
                color: isDark ? AppColors.parchment70 : AppColors.charcoal60,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePaymentFlow(
    BuildContext context,
    RfpCheckoutState checkoutState,
    RfpBatchState bs,
  ) async {
    final checkoutCubit = context.read<RfpCheckoutCubit>();
    final activePlanId =
        bs.selectedPlan?.id ??
        (bs.selectedPlanIds.isNotEmpty ? bs.selectedPlanIds.first : '');

    // 1. Submit booking to POST /api/rfp_subscription/subscriptions/book/
    final booking = await checkoutCubit.submitBooking(
      batchId: bs.selectedBatch?.id ?? '',
      planId: activePlanId,
      locationId: bs.selectedLocationId,
      patchConfigs: bs.activePatchConfigs,
    );

    if (!mounted || booking == null) return;

    // 2. Open checkout_url if returned
    final url = booking.checkoutUrl;
    final txId = booking.merchantTransactionId;

    if (url != null && url.isNotEmpty) {
      await _openGatewayUrl(url);
    }

    // 3. Return from payment -> verify payment
    if (txId != null && txId.isNotEmpty && mounted) {
      await checkoutCubit.verifyPayment(txId);
    }
  }

  Future<void> _openGatewayUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {}
    }
  }
}
