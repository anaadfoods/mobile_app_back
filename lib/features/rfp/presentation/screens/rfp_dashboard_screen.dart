import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubit/rfp_dashboard_cubit.dart';
import '../widgets/rfp_dashboard_header.dart';
import '../widgets/rfp_dashboard_history.dart';
import '../widgets/rfp_progress_card.dart';
import '../widgets/rfp_dashboard_patches.dart';
import '../widgets/rfp_dashboard_timeline.dart';
import '../widgets/rfp_dashboard_billing_card.dart';
import '../widgets/rfp_delivery_otp_card.dart';
import 'package:grocery_app/services/notification_service.dart';
import '../../domain/entities/rfp_booking.dart';

/// Customer Dashboard screen showing active RFP subscription status, deliveries, and billing.
class RfpDashboardScreen extends StatefulWidget {
  final RfpBooking? initialBooking;
  final String? bookingId;

  const RfpDashboardScreen({super.key, this.initialBooking, this.bookingId});

  @override
  State<RfpDashboardScreen> createState() => _RfpDashboardScreenState();
}

class _RfpDashboardScreenState extends State<RfpDashboardScreen>
    with WidgetsBindingObserver {
  Timer? _otpPollTimer;
  StreamSubscription? _notifSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _otpPollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        final cubit = context.read<RfpDashboardCubit>();
        if (cubit.state.hasOutForDelivery ||
            cubit.state.activeOtpStatus?.isActive == true ||
            cubit.state.upcomingDeliveries.isNotEmpty) {
          cubit.checkDeliveryOtpStatus();
        }
      }
    });
    try {
      _notifSub = NotificationService().onMessageReceived.listen((msg) {
        final type = msg.data['type']?.toString();
        if (type == 'rfp_delivery_otp' || type == 'rfp_delivery') {
          if (mounted) {
            final incomingOtp = msg.data['otp']?.toString();
            final deliveryId = msg.data['delivery_id']?.toString();
            final cubit = context.read<RfpDashboardCubit>();
            if (incomingOtp != null && incomingOtp.isNotEmpty) {
              cubit.ingestLiveOtp(otp: incomingOtp, deliveryId: deliveryId);
            }
            cubit.checkDeliveryOtpStatus(deliveryId);
            cubit.refreshDeliveries();
          }
        }
      });
    } catch (_) {}
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cubit = context.read<RfpDashboardCubit>();
      if (widget.initialBooking != null) {
        cubit.setInitialBooking(widget.initialBooking!);
      } else if (!cubit.state.hasBooking &&
          cubit.state.error == null &&
          !cubit.state.isLoading) {
        cubit.loadDashboard(bookingId: widget.bookingId);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      final cubit = context.read<RfpDashboardCubit>();
      cubit.checkDeliveryOtpStatus();
      cubit.refreshDeliveries();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notifSub?.cancel();
    _otpPollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<RfpDashboardCubit, RfpDashboardState>(
      builder: (context, state) {
        if (state.isLoading && !state.hasBooking) {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: const Center(
              child: CircularProgressIndicator(color: AppColors.deepSoilGreen),
            ),
          );
        }

        if (state.error != null && !state.hasBooking) {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.cloud_off_rounded,
                        size: 48,
                        color: AppColors.amberWarn,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Unable to load subscription',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.textTheme.bodyMedium?.color?.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed:
                            () => context
                                .read<RfpDashboardCubit>()
                                .loadDashboard(bookingId: widget.bookingId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.deepSoilGreen,
                          foregroundColor: AppColors.parchment,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        if (!state.hasBooking) {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.deepSoilGreen.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.eco_outlined,
                          color: AppColors.deepSoilGreen,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'No Active Subscription Found',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Join an upcoming seasonal farming batch to receive farm-fresh produce and follow your patch progress.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.textTheme.bodyMedium?.color?.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => context.go('/rfp/batches'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.deepSoilGreen,
                          foregroundColor: AppColors.parchment,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Explore Batches'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return _buildContent(context, state);
      },
    );
  }

  Widget _buildContent(BuildContext context, RfpDashboardState state) {
    final booking = state.activeBooking!;
    final df = DateFormat('dd MMM');
    final theme = Theme.of(context);

    final rawStatus = booking.status.trim().toUpperCase();
    final statusColor =
        rawStatus == 'ACTIVE'
            ? AppColors.deepSoilGreen
            : (rawStatus.contains('PENDING')
                ? AppColors.harvestAmber
                : AppColors.charcoal);

    final batchTitle =
        booking.batchName?.isNotEmpty == true
            ? booking.batchName!
            : 'Batch #${booking.batchNumber}';

    final deliveryDaysStr =
        booking.deliveryDays.isNotEmpty
            ? booking.deliveryDays.join(' & ')
            : 'Weekly';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.parchment,
          backgroundColor: AppColors.deepSoilGreen,
          onRefresh:
              () => context.read<RfpDashboardCubit>().loadDashboard(
                bookingId: widget.bookingId ?? booking.id,
              ),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      RfpDashboardHeader(booking: booking),
                      const SizedBox(height: 12),
                      // Welcome & Batch Banner
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  batchTitle,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: theme.textTheme.bodyLarge?.color,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Delivery: Every $deliveryDaysStr',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              rawStatus,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (state.hasOutForDelivery ||
                          state.activeOtpStatus?.isActive == true) ...[
                        RfpDeliveryOtpCard(
                          otpStatus: state.activeOtpStatus,
                          isOutForDelivery: state.hasOutForDelivery,
                          onRefresh:
                              () =>
                                  context
                                      .read<RfpDashboardCubit>()
                                      .checkDeliveryOtpStatus(),
                        ),
                        const SizedBox(height: 14),
                      ],
                      // Progress card (computed dynamically)
                      RfpProgressCard(booking: booking, df: df),
                      const SizedBox(height: 14),
                      // Active plans & vegetables
                      RfpDashboardPatches(booking: booking),
                      const SizedBox(height: 14),
                      // Upcoming deliveries timeline
                      RfpDashboardTimeline(state: state, df: df),
                      if (state.deliveryHistory.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        RfpDashboardHistory(
                          history: state.deliveryHistory,
                          df: df,
                        ),
                      ],
                      const SizedBox(height: 14),
                      // Billing
                      RfpDashboardBillingCard(booking: booking),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
