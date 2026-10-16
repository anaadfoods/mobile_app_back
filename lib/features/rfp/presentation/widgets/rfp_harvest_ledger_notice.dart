import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/rfp_booking.dart';

/// Harvest ledger notice banner shown when remaining payment is due.
class RfpHarvestLedgerNotice extends StatelessWidget {
  final RfpBooking booking;
  final VoidCallback? onPayNow;

  const RfpHarvestLedgerNotice({
    super.key,
    required this.booking,
    this.onPayNow,
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF11382A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E5642), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFF1D5A43),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_active_outlined,
              size: 16,
              color: Color(0xFF8ABDA9),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'HARVEST LEDGER NOTICE',
                  style: TextStyle(
                    color: Color(0xFF8ABDA9),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text.rich(
                  TextSpan(
                    text: 'Your remaining balance of ',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      height: 1.3,
                    ),
                    children: [
                      TextSpan(
                        text: remainingFormatted,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFC9EEA9),
                        ),
                      ),
                      const TextSpan(
                        text: ' is due to keep deliveries active.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onPayNow,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1D5C45),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF488B70), width: 0.8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Pay Now',
                    style: TextStyle(
                      color: Color(0xFFE2F4DF),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 3),
                  Icon(Icons.arrow_forward, size: 11, color: Color(0xFFE2F4DF)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
