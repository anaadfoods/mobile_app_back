import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../cubit/rfp_checkout_cubit.dart';
import '../cubit/rfp_batch_cubit.dart';
import '../rfp_theme.dart';
import '../../domain/entities/rfp_booking.dart';

/// Payment success screen showing confirmed RFP subscription after verify-payment SUCCESS.
class RfpPaymentSuccessScreen extends StatefulWidget {
  final RfpBooking? booking;

  const RfpPaymentSuccessScreen({super.key, this.booking});

  @override
  State<RfpPaymentSuccessScreen> createState() =>
      _RfpPaymentSuccessScreenState();
}

class _RfpPaymentSuccessScreenState extends State<RfpPaymentSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    RfpCheckoutState? checkoutState;
    try {
      checkoutState = context.watch<RfpCheckoutCubit>().state;
    } catch (_) {}

    final batchState = context.watch<RfpBatchCubit?>()?.state;
    final booking = widget.booking ?? checkoutState?.booking;

    // Show success only when verify-payment returns SUCCESS or booking is marked paid
    final isVerifiedSuccess =
        checkoutState?.status == CheckoutStatus.success ||
        (checkoutState?.isBookingPaid ?? false) ||
        checkoutState?.verificationResponse?['status'] == 'SUCCESS' ||
        (booking?.bookingPaid ?? false);

    if (!isVerifiedSuccess) {
      return _buildPendingOrUnverifiedView(context, checkoutState);
    }

    final df = DateFormat('dd MMM');
    final batchDisplay =
        booking?.batchName ??
        (booking != null
            ? 'Batch #${booking.batchNumber}'
            : 'Batch #${batchState?.selectedBatch?.batchNumber ?? 1}');
    final bookingId =
        booking != null && booking.id.isNotEmpty
            ? '#${booking.id}'
            : (checkoutState?.merchantTransactionId != null
                ? checkoutState!.merchantTransactionId!
                : 'CONFIRMED');

    final dateRange =
        booking != null
            ? '${df.format(booking.startDate)} - ${df.format(booking.endDate)}'
            : (batchState?.selectedBatch != null
                ? '${df.format(batchState!.selectedBatch!.startDate)} - ${df.format(batchState.selectedBatch!.endDate)}'
                : '12-Week Harvest');

    final patchCount =
        booking != null
            ? (booking.patchConfigs.isNotEmpty
                ? booking.patchConfigs.length
                : 1)
            : (batchState != null && batchState.selectedPatchIds.isNotEmpty
                ? batchState.selectedPatchIds.length
                : 1);
    final patchLabel = '$patchCount Thali${patchCount == 1 ? '' : 's'}';

    final dropsLabel =
        booking != null && booking.deliveryDays.isNotEmpty
            ? (booking.deliveryDays.length >= 2
                ? 'Bi-weekly drops'
                : 'Weekly drops')
            : 'Scheduled drops';

    final paidAmount =
        booking != null
            ? booking.bookingAmountPaid.toInt()
            : (checkoutState?.pricing?.bookingAmount.toInt() ?? 0);

    return Scaffold(
      backgroundColor: RfpTheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(RfpTheme.gutter),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: RfpTheme.spaceLg),
              // Animated checkmark
              ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: RfpTheme.secondaryContainer,
                    boxShadow: [
                      BoxShadow(
                        color: RfpTheme.secondary.withValues(alpha: 0.3),
                        blurRadius: 32,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 60,
                    color: RfpTheme.onSecondaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: RfpTheme.spaceLg),
              FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    Text(
                      'Payment Verified & Confirmed!',
                      textAlign: TextAlign.center,
                      style: RfpTheme.headlineLg.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: RfpTheme.spaceSm),
                    Text(
                      'Your harvest share is officially reserved.\nWelcome to $batchDisplay.',
                      textAlign: TextAlign.center,
                      style: RfpTheme.bodyMd.copyWith(
                        color: RfpTheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: RfpTheme.spaceLg),
                    // Booking ID Container
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: RfpTheme.spaceLg,
                        vertical: RfpTheme.spaceMd,
                      ),
                      decoration: BoxDecoration(
                        color: RfpTheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(RfpTheme.radiusLg),
                        border: Border.all(
                          color: RfpTheme.outlineVariant.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Subscription Reference',
                            style: RfpTheme.labelSm.copyWith(
                              color: RfpTheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            bookingId,
                            style: RfpTheme.headlineSm.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: RfpTheme.spaceMd),
                    // Summary chips
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _chip(Icons.calendar_month, dateRange),
                        const SizedBox(width: RfpTheme.spaceSm),
                        _chip(Icons.spa, patchLabel),
                      ],
                    ),
                    const SizedBox(height: RfpTheme.spaceSm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _chip(Icons.local_shipping, dropsLabel),
                        const SizedBox(width: RfpTheme.spaceSm),
                        _chip(Icons.check_circle, '₹$paidAmount paid'),
                      ],
                    ),
                    const SizedBox(height: RfpTheme.spaceLg),
                    // Policy note
                    Container(
                      padding: const EdgeInsets.all(RfpTheme.spaceMd),
                      decoration: BoxDecoration(
                        color: RfpTheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(RfpTheme.radiusMd),
                        border: Border.all(
                          color: RfpTheme.outlineVariant.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.eco_rounded,
                            size: 18,
                            color: RfpTheme.primary,
                          ),
                          const SizedBox(width: RfpTheme.spaceSm),
                          Expanded(
                            child: Text(
                              'Produce selections are locked for the harvest cycle to ensure dedicated farm plots.',
                              style: RfpTheme.bodySm.copyWith(
                                color: RfpTheme.onSurfaceVariant,
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: RfpTheme.spaceLg),
              // CTAs
              FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed:
                            () => context.go('/rfp/dashboard', extra: booking),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: RfpTheme.primary,
                          foregroundColor: RfpTheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              RfpTheme.radiusLg,
                            ),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'View Farm Dashboard',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(height: RfpTheme.spaceSm),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => context.go('/home'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: RfpTheme.onSurface,
                          side: BorderSide(
                            color: RfpTheme.outlineVariant.withValues(
                              alpha: 0.6,
                            ),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              RfpTheme.radiusLg,
                            ),
                          ),
                        ),
                        child: const Text('Return to Home'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: RfpTheme.spaceMd),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingOrUnverifiedView(
    BuildContext context,
    RfpCheckoutState? checkoutState,
  ) {
    return Scaffold(
      backgroundColor: RfpTheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(RfpTheme.gutter),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.amber.withValues(alpha: 0.15),
                ),
                child: const Icon(
                  Icons.hourglass_top_rounded,
                  size: 44,
                  color: Colors.amber,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Payment Verification Pending',
                textAlign: TextAlign.center,
                style: RfpTheme.headlineLg.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'We are verifying confirmation with the payment gateway. Subscription will activate once verification completes.',
                textAlign: TextAlign.center,
                style: RfpTheme.bodyMd.copyWith(
                  color: RfpTheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    } else {
                      context.go('/rfp/checkout');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RfpTheme.primary,
                    foregroundColor: RfpTheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(RfpTheme.radiusLg),
                    ),
                  ),
                  child: const Text('Return to Checkout'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () => context.go('/home'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: RfpTheme.onSurface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(RfpTheme.radiusLg),
                    ),
                  ),
                  child: const Text('Return to Home'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: RfpTheme.spaceMd,
        vertical: RfpTheme.spaceXs,
      ),
      decoration: BoxDecoration(
        color: RfpTheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(RfpTheme.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: RfpTheme.primary),
          const SizedBox(width: 4),
          Text(label, style: RfpTheme.labelSm),
        ],
      ),
    );
  }
}
