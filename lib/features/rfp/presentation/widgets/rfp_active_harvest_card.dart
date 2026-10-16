import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/rfp_booking.dart';
import '../../domain/entities/rfp_delivery.dart';
import '../../domain/entities/rfp_delivery_otp_status.dart';

/// Active Harvest Order card with upcoming dispatch, plan pill, compact
/// vegetable chips, farm photo banner with morning delivery badge, and location footer.
class RfpActiveHarvestCard extends StatelessWidget {
  final RfpBooking booking;
  final List<RfpDelivery> deliveries;
  final VoidCallback? onViewDetails;
  final RfpDeliveryOtpStatus? otpStatus;

  const RfpActiveHarvestCard({
    super.key,
    required this.booking,
    required this.deliveries,
    this.onViewDetails,
    this.otpStatus,
  });

  @override
  Widget build(BuildContext context) {
    // Find next upcoming delivery or first scheduled
    final upcomingList =
        deliveries.where((d) => d.status != 'delivered').toList()
          ..sort((a, b) => a.date.compareTo(b.date));
    final nextDelivery =
        upcomingList.isNotEmpty
            ? upcomingList.first
            : (deliveries.isNotEmpty ? deliveries.first : null);

    final nextDate =
        nextDelivery?.date ?? DateTime.now().add(const Duration(days: 3));
    final dateStr = DateFormat('MMM d (EEEE)').format(nextDate);

    // Vegetables for chips
    final vegChips = <String>[];
    if (nextDelivery != null && nextDelivery.patches.isNotEmpty) {
      for (final p in nextDelivery.patches) {
        if (p.includedVegetables != null) {
          vegChips.addAll(p.includedVegetables!);
        }
      }
    }
    if (vegChips.isEmpty) {
      vegChips.addAll([
        'Carrots',
        'Spinach',
        'Tomatoes',
        'Broccoli',
        'Potatoes',
      ]);
    }

    // Weight and frequency
    final weight =
        booking.patchConfigs.isNotEmpty
            ? booking.patchConfigs.first.selectedWeight
            : 5.0;
    final freq = booking.deliveryDays.length >= 2 ? '2x/week' : '1x/week';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9ECEF), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order tag & Batch number
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F1FC),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '● ACTIVE HARVEST ORDER',
                      style: TextStyle(
                        color: Color(0xFF1E56A0),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Batch No. #${booking.batchNumber != 0 ? booking.batchNumber : "SF-8842"}',
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Upcoming dispatch row
          Builder(
            builder: (context) {
              final isOut = nextDelivery?.isOutForDelivery == true;
              return Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color:
                          isOut
                              ? const Color(0xFFDCFCE7)
                              : const Color(0xFFE6F4EA),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isOut
                          ? Icons.delivery_dining
                          : Icons.local_shipping_outlined,
                      color:
                          isOut
                              ? const Color(0xFF16A34A)
                              : const Color(0xFF1E7E34),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isOut ? 'OUT FOR DELIVERY' : 'UPCOMING DISPATCH',
                          style: TextStyle(
                            color:
                                isOut
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFF718096),
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          dateStr,
                          style: const TextStyle(
                            color: Color(0xFF1A202C),
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        if (nextDelivery?.assignDeliveryTo != null &&
                            nextDelivery!.assignDeliveryTo!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              'Agent: ${nextDelivery.assignDeliveryTo}',
                              style: const TextStyle(
                                color: Color(0xFF1E56A0),
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (otpStatus?.isActive == true)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF86EFAC),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.key,
                            size: 12,
                            color: Color(0xFF166534),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'OTP: ${otpStatus!.otp}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF166534),
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 10),

          // Plan pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8F9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFEAEAEA), width: 0.8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.eco_outlined,
                      size: 13,
                      color: Color(0xFF003629),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      booking.planName,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A202C),
                      ),
                    ),
                  ],
                ),
                Text(
                  '${weight.toStringAsFixed(weight.truncateToDouble() == weight ? 0 : 1)}KG • $freq',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF718096),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Freshly Picked Chips
          const Text(
            'Freshly Picked This Run',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 5,
            children:
                vegChips.take(5).map((veg) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3.5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDF4F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '✕ ',
                          style: TextStyle(
                            fontSize: 9,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          veg,
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: Color(0xFF1E293B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
          const SizedBox(height: 12),

          // Farm banner with badge overlay
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                SizedBox(
                  height: 115,
                  width: double.infinity,
                  child: Image.asset(
                    'assets/images/natural_veggies.png',
                    fit: BoxFit.cover,
                    errorBuilder:
                        (ctx, err, stack) => Container(
                          color: const Color(0xFF28543B),
                          child: const Center(
                            child: Icon(
                              Icons.eco,
                              color: Colors.white70,
                              size: 36,
                            ),
                          ),
                        ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.eco, size: 10, color: Color(0xFF8ABDA9)),
                        SizedBox(width: 4),
                        Text(
                          'Harvested Morning of Delivery',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Footer row: location and View Details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 15,
                    color: Color(0xFF64748B),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    booking.address.city.isNotEmpty
                        ? 'Plot 4B, ${booking.address.city}'
                        : 'Plot 4B, South Ridge Orchard',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: onViewDetails,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF003629),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View Details',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 3),
                      Icon(Icons.chevron_right, size: 13, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
