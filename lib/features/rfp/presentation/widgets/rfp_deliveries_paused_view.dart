import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/rfp_booking.dart';
import '../../domain/entities/rfp_delivery.dart';
import 'rfp_paused_truck_illustration.dart';
import 'rfp_box_allotment_overview.dart';
import 'rfp_paused_harvest_schedule.dart';

/// Deliveries Paused (Enforcement) View matching Screen B (Right mockup).
///
/// Displayed when remaining payment is overdue or subscription is paused.
/// Features:
/// 1. Top salmon/peach header card with red alert badge, DELIVERIES PAUSED title,
///    due date, and dashed truck illustration.
/// 2. Lockdown warning card explaining the harvest pause.
/// 3. Box Allotment Overview with circular thumbnails (Delivered vs Locked).
/// 4. Harvest Schedule timeline with [DONE], [PAUSED], and [Pending] locked items.
/// 5. Sticky bottom red "PAY REMAINING ₹X,000" bar.
class RfpDeliveriesPausedView extends StatelessWidget {
  final RfpBooking booking;
  final List<RfpDelivery> deliveries;
  final VoidCallback? onPayRemaining;

  const RfpDeliveriesPausedView({
    super.key,
    required this.booking,
    required this.deliveries,
    this.onPayRemaining,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      symbol: '₹',
      decimalDigits: 0,
      locale: 'en_IN',
    );
    final remainingFormatted = currencyFormatter.format(
      booking.remainingAmount,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopNoticeCard(),
                const SizedBox(height: 14),
                _buildLockdownCard(remainingFormatted),
                const SizedBox(height: 18),
                const RfpBoxAllotmentOverview(),
                const SizedBox(height: 18),
                RfpPausedHarvestSchedule(deliveries: deliveries),
              ],
            ),
          ),
          if (!booking.remainingPaid && booking.remainingAmount > 0)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildStickyPayBar(remainingFormatted),
            ),
        ],
      ),
    );
  }

  // ─── 1. Top Salmon Notice Card ────────────────────────────────────────────

  Widget _buildTopNoticeCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFFECEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD5D2), width: 1),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        children: [
          // Corner marks x x x
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                '× × ×',
                style: TextStyle(
                  color: Color(0xFFE57373),
                  fontSize: 10,
                  letterSpacing: 3.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '× × ×',
                style: TextStyle(
                  color: Color(0xFFE57373),
                  fontSize: 10,
                  letterSpacing: 3.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Red badge: ! HARVEST NOTICE
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFC62828),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 12,
                  color: Colors.white,
                ),
                SizedBox(width: 4),
                Text(
                  'HARVEST NOTICE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Title: DELIVERIES PAUSED
          const Text(
            'DELIVERIES PAUSED',
            style: TextStyle(
              color: Color(0xFFB71C1C),
              fontSize: 21,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),

          // Subtitle: Payment Due by Week 3: Oct 15th
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 13,
                color: Color(0xFFC62828),
              ),
              const SizedBox(width: 5),
              Text(
                'Payment Due by Week 3: Oct 15th',
                style: TextStyle(
                  color: const Color(0xFFC62828).withValues(alpha: 0.9),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Dotted truck illustration
          const RfpPausedTruckIllustration(),
        ],
      ),
    );
  }

  // ─── 2. Lockdown Card ─────────────────────────────────────────────────────

  Widget _buildLockdownCard(String remainingFormatted) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F6FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFFFECE8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.lock_outline,
              size: 16,
              color: Color(0xFFE53935),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.planName.isNotEmpty
                      ? booking.planName
                      : 'Winter Harvest Cycle',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Please clear your remaining balance of $remainingFormatted for the harvest to resume your scheduled farm-fresh drops.',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF475569),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── 3. Sticky Bottom Pay Bar ─────────────────────────────────────────────

  Widget _buildStickyPayBar(String remainingFormatted) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: onPayRemaining,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB71C1C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.credit_card, size: 18),
                const SizedBox(width: 8),
                Text(
                  'PAY REMAINING $remainingFormatted',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
