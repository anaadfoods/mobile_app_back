import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:grocery_app/common_widgets/modern_back_button.dart';
import 'package:grocery_app/services/notification_service.dart';
import '../cubit/rfp_dashboard_cubit.dart';
import '../rfp_theme.dart';
import '../widgets/rfp_active_subscriber_view.dart';
import '../widgets/rfp_deliveries_paused_view.dart';

/// Deliveries Schedule Screen coordinating:
/// - Screen A: Active Subscriber Dashboard
/// - Screen B: Deliveries Paused (Enforcement)
/// Matches design mockup media_1790156501915.png
class RfpDeliveriesScreen extends StatefulWidget {
  const RfpDeliveriesScreen({super.key});

  @override
  State<RfpDeliveriesScreen> createState() => _RfpDeliveriesScreenState();
}

class _RfpDeliveriesScreenState extends State<RfpDeliveriesScreen>
    with WidgetsBindingObserver {
  int _viewMode = 0; // 0 = Active Dashboard, 1 = Deliveries Paused
  bool _initializedMode = false;
  bool _isPayingRemaining = false;
  StreamSubscription? _notifSub;
  Timer? _otpPollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    context.read<RfpDashboardCubit>().loadDashboard();
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

  Future<void> _handlePayRemaining() async {
    if (_isPayingRemaining) return;

    final cubit = context.read<RfpDashboardCubit>();
    final booking = cubit.state.activeBooking;
    if (booking == null) return;

    if (booking.remainingPaid || booking.remainingAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Remaining amount is already paid.'),
          backgroundColor: Color(0xFF1E7E34),
        ),
      );
      return;
    }

    setState(() => _isPayingRemaining = true);

    try {
      final res = await cubit.payRemaining();
      if (!mounted) return;

      if (res == null) {
        final err =
            cubit.state.error ?? 'Unable to initiate remaining payment.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: RfpTheme.error),
        );
        return;
      }

      final checkoutUrl =
          res['checkout_url'] as String? ?? res['payment_url'] as String?;
      final txId =
          res['merchant_transaction_id'] as String? ??
          res['transaction_id'] as String?;

      if (checkoutUrl != null && checkoutUrl.isNotEmpty) {
        final uri = Uri.tryParse(checkoutUrl);
        if (uri != null) {
          try {
            if (!await launchUrl(uri, mode: LaunchMode.inAppBrowserView)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          } catch (_) {
            try {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            } catch (_) {}
          }
        }
      }

      if (txId != null && txId.isNotEmpty && mounted) {
        final verified = await cubit.verifyRemainingPayment(txId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              verified
                  ? 'Payment verified! Harvest deliveries resumed.'
                  : 'Payment verification pending. Please refresh.',
            ),
            backgroundColor:
                verified ? const Color(0xFF1E7E34) : RfpTheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Payment error: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: RfpTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPayingRemaining = false);
    }
  }

  void _showBookingDetailsSheet(BuildContext context, dynamic booking) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (ctx) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Subscription Details',
                        style: RfpTheme.headlineSm.copyWith(fontSize: 16),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Plan: ${booking.planName}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Address: ${booking.address.addressLine}, ${booking.address.city}',
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RfpDashboardCubit, RfpDashboardState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Scaffold(
            backgroundColor: Color(0xFFF9F9FB),
            body: Center(
              child: CircularProgressIndicator(color: RfpTheme.primary),
            ),
          );
        }

        if (state.error != null) {
          return Scaffold(
            backgroundColor: const Color(0xFFF9F9FB),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: RfpTheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load deliveries',
                      style: RfpTheme.headlineSm,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.error!,
                      style: RfpTheme.bodySm.copyWith(
                        color: RfpTheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed:
                          () =>
                              context.read<RfpDashboardCubit>().loadDashboard(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final booking = state.activeBooking;
        if (booking == null) {
          return Scaffold(
            backgroundColor: const Color(0xFFF9F9FB),
            appBar: AppBar(
              title: const Text('Deliveries'),
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0,
              leading: ModernBackButton(
                onPressed:
                    () =>
                        Navigator.of(context).canPop()
                            ? Navigator.of(context).pop()
                            : context.go('/home'),
              ),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.eco_outlined,
                      size: 56,
                      color: RfpTheme.secondary,
                    ),
                    const SizedBox(height: 16),
                    Text('No Active Subscription', style: RfpTheme.headlineSm),
                    const SizedBox(height: 8),
                    const Text(
                      'You do not have an active harvest subscription yet. Explore our open batches to subscribe.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => context.push('/rfp/batches'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: RfpTheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Browse Batches'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Auto-initialize mode once based on booking payment status
        if (!_initializedMode) {
          _initializedMode = true;
          if (!booking.remainingPaid &&
              (booking.status.toLowerCase() == 'paused' ||
                  booking.remainingAmount > 0)) {
            // Can default to active or paused; keep active as default or paused if explicitly paused
            if (booking.status.toLowerCase() == 'paused') {
              _viewMode = 1;
            }
          }
        }

        final allDeliveries = [
          ...state.deliveryHistory,
          ...state.upcomingDeliveries,
          ...booking.deliveries,
        ];
        // Deduplicate by ID or week
        final seenIds = <String>{};
        final uniqueDeliveries =
            allDeliveries.where((d) {
              final key = '${d.id}_${d.weekNumber}';
              if (seenIds.contains(key)) return false;
              seenIds.add(key);
              return true;
            }).toList();

        return Scaffold(
          backgroundColor: const Color(0xFFF9F9FB),
          appBar: AppBar(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF1E293B),
            elevation: 0.5,
            leading: ModernBackButton(
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  context.go('/rfp/dashboard');
                }
              },
            ),
            title: const Text(
              'Harvest Deliveries',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
            centerTitle: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(42),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _viewMode = 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          decoration: BoxDecoration(
                            color:
                                _viewMode == 0
                                    ? const Color(0xFF003629)
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              'Active Dashboard',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color:
                                    _viewMode == 0
                                        ? Colors.white
                                        : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _viewMode = 1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          decoration: BoxDecoration(
                            color:
                                _viewMode == 1
                                    ? const Color(0xFFB71C1C)
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (!booking.remainingPaid &&
                                    booking.remainingAmount > 0)
                                  Container(
                                    width: 6,
                                    height: 6,
                                    margin: const EdgeInsets.only(right: 4),
                                    decoration: const BoxDecoration(
                                      color: Colors.amber,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                Text(
                                  'Deliveries Paused',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color:
                                        _viewMode == 1
                                            ? Colors.white
                                            : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          body:
              _viewMode == 0
                  ? RfpActiveSubscriberView(
                    booking: booking,
                    deliveries: uniqueDeliveries,
                    onPayNow: _handlePayRemaining,
                    onViewDetails:
                        () => _showBookingDetailsSheet(context, booking),
                    otpStatus: state.activeOtpStatus,
                    onRefreshOtp:
                        () =>
                            context
                                .read<RfpDashboardCubit>()
                                .checkDeliveryOtpStatus(),
                  )
                  : RfpDeliveriesPausedView(
                    booking: booking,
                    deliveries: uniqueDeliveries,
                    onPayRemaining: _handlePayRemaining,
                  ),
        );
      },
    );
  }
}
