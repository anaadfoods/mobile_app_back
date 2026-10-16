import 'package:flutter/material.dart';
import '../../domain/entities/rfp_booking.dart';
import '../../domain/entities/rfp_delivery.dart';
import '../../domain/entities/rfp_delivery_otp_status.dart';
import 'rfp_harvest_ledger_notice.dart';
import 'rfp_active_harvest_card.dart';
import 'rfp_delivery_otp_card.dart';
import 'rfp_seasonal_harvest_log.dart';

/// Active Subscriber Dashboard matching Screen A (Left mockup).
///
/// Features:
/// 1. Dark green Harvest Ledger Notice with remaining amount & Pay Now button.
/// 2. Active Delivery OTP Card when an active OTP has been sent by the delivery agent.
/// 3. Active Harvest Order card with upcoming dispatch, plan pill, compact
///    vegetable chips, farm photo banner with morning delivery badge, and location footer.
/// 4. Seasonal Journey 12-Week Harvest Log with delivered, cancelled, active, and upcoming items.
class RfpActiveSubscriberView extends StatelessWidget {
  final RfpBooking booking;
  final List<RfpDelivery> deliveries;
  final VoidCallback? onPayNow;
  final VoidCallback? onViewDetails;
  final RfpDeliveryOtpStatus? otpStatus;
  final VoidCallback? onRefreshOtp;

  const RfpActiveSubscriberView({
    super.key,
    required this.booking,
    required this.deliveries,
    this.onPayNow,
    this.onViewDetails,
    this.otpStatus,
    this.onRefreshOtp,
  });

  @override
  Widget build(BuildContext context) {
    final isOut = deliveries.any((d) => d.isOutForDelivery);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!booking.remainingPaid && booking.remainingAmount > 0) ...[
            RfpHarvestLedgerNotice(booking: booking, onPayNow: onPayNow),
            const SizedBox(height: 14),
          ],
          if (isOut || otpStatus?.isActive == true) ...[
            RfpDeliveryOtpCard(
              otpStatus: otpStatus,
              isOutForDelivery: isOut,
              onRefresh: onRefreshOtp,
            ),
            const SizedBox(height: 14),
          ],
          RfpActiveHarvestCard(
            booking: booking,
            deliveries: deliveries,
            onViewDetails: onViewDetails,
            otpStatus: otpStatus,
          ),
          const SizedBox(height: 20),
          RfpSeasonalHarvestLog(booking: booking, deliveries: deliveries),
        ],
      ),
    );
  }
}
