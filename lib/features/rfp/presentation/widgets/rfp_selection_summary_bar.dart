import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../cubit/rfp_batch_cubit.dart';
import '../rfp_theme.dart';

/// Sticky bottom summary bar displaying live pricing calculated from the backend
/// endpoint POST /api/rfp_subscription/subscriptions/calculate/.
///
/// Shows loading state while calculating, clear error if calculation fails,
/// and exact backend quote values: total, pay_now, pay_later, discount_percentage,
/// and deliveries_count.
class RfpSelectionSummaryBar extends StatelessWidget {
  const RfpSelectionSummaryBar({super.key});

  static String _fmt(num n) => n.toInt().toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RfpBatchCubit, RfpBatchState>(
      builder: (context, state) {
        final hasActiveSelection =
            state.selectedPlanIds.isNotEmpty ||
            (state.selectedPlan != null && state.isPlanConfigured);

        if (!hasActiveSelection) {
          return const SizedBox.shrink();
        }

        return Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
            decoration: BoxDecoration(
              color: RfpTheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, -4),
                ),
              ],
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: SafeArea(top: false, child: _buildContent(context, state)),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, RfpBatchState state) {
    if (state.isPricingLoading) {
      return _buildLoadingState();
    }

    if (state.pricingError != null) {
      return _buildErrorState(context, state.pricingError!);
    }

    final pricing = state.pricing;
    if (pricing == null) {
      return _buildCalculatingPrompt(context);
    }

    return _buildPricingQuote(context, state, pricing);
  }

  Widget _buildLoadingState() {
    return const SizedBox(
      height: 52,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: RfpTheme.primary,
            ),
          ),
          SizedBox(width: 14),
          Text(
            'Calculating quote from farm...',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: RfpTheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Row(
      children: [
        const Icon(
          Icons.error_outline_rounded,
          color: RfpTheme.error,
          size: 22,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            error,
            style: const TextStyle(
              color: RfpTheme.error,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 10),
        OutlinedButton(
          onPressed: () => context.read<RfpBatchCubit>().recalculatePricing(),
          style: OutlinedButton.styleFrom(
            foregroundColor: RfpTheme.error,
            side: const BorderSide(color: RfpTheme.error, width: 1),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text('Retry', style: TextStyle(fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildCalculatingPrompt(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Ready to calculate quote',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
        ElevatedButton(
          onPressed: () => context.read<RfpBatchCubit>().recalculatePricing(),
          style: ElevatedButton.styleFrom(
            backgroundColor: RfpTheme.primary,
            foregroundColor: RfpTheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(RfpTheme.radiusLg),
            ),
          ),
          child: const Text('Calculate'),
        ),
      ],
    );
  }

  Widget _buildPricingQuote(
    BuildContext context,
    RfpBatchState state,
    dynamic pricing,
  ) {
    final discountPercent = pricing.discountPercentage as double;
    final total = pricing.finalPrice as double;
    final payNow = pricing.bookingAmount as double;
    final payLater = pricing.remainingAmount as double;
    final deliveries = pricing.deliveriesCount as int;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    '$deliveries Deliveries',
                    style: RfpTheme.labelMd.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: RfpTheme.onSurfaceVariant,
                    ),
                  ),
                  if (discountPercent > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC9EEA9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${discountPercent.toStringAsFixed(discountPercent.truncateToDouble() == discountPercent ? 0 : 1)}% OFF',
                        style: const TextStyle(
                          color: Color(0xFF003629),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    'Total: ₹${_fmt(total)}',
                    style: RfpTheme.headlineSm.copyWith(
                      color: RfpTheme.onSurface,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 1),
              Text(
                'Pay Now: ₹${_fmt(payNow)} • Pay Later: ₹${_fmt(payLater)}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: RfpTheme.primary,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 44,
          child: ElevatedButton(
            onPressed: () => context.push('/rfp/checkout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: RfpTheme.primary,
              foregroundColor: RfpTheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(RfpTheme.radiusLg),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Proceed to Checkout',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                SizedBox(width: 6),
                Icon(Icons.arrow_forward, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
