import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/rfp_delivery.dart';

/// Delivery history section for customer dashboard displaying delivered produce drops.
class RfpDashboardHistory extends StatelessWidget {
  final List<RfpDelivery> history;
  final DateFormat df;

  const RfpDashboardHistory({
    super.key,
    required this.history,
    required this.df,
  });

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Delivery History',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 8),
        ...history.take(3).map((delivery) {
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE9ECEF), width: 0.8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  size: 18,
                  color: Color(0xFF1E7E34),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${delivery.dayOfWeek}, ${df.format(delivery.date)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F4EA),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'DELIVERED',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E7E34),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
