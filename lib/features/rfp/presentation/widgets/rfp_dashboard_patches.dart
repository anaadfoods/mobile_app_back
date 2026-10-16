import 'package:flutter/material.dart';
import '../../domain/entities/rfp_booking.dart';

/// Active Plans section on the customer dashboard.
class RfpDashboardPatches extends StatelessWidget {
  final RfpBooking booking;

  const RfpDashboardPatches({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final configs = booking.patchConfigs;
    if (configs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Active Plans',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 8),
        ...configs.map((config) {
          final freq =
              config.deliveryFrequency == 'twice_a_week'
                  ? '2x/week'
                  : '1x/week';
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 5),
                  child: Icon(Icons.circle, size: 6, color: Color(0xFF2D6A4F)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: config.patchLabel,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        TextSpan(
                          text: '  •  ${config.selectedWeight} KG  •  $freq',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
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
