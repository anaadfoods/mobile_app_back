import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../common_widgets/modern_back_button.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/rfp_booking.dart';
import '../rfp_theme.dart';

/// Top bar header widget for customer dashboard displaying location and quick delivery link.
class RfpDashboardHeader extends StatelessWidget {
  final RfpBooking booking;

  const RfpDashboardHeader({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final city = booking.address.city.trim();
    final locality = booking.address.locality?.trim();
    final String locationText;
    if (city.isNotEmpty && locality != null && locality.isNotEmpty) {
      locationText = '$locality, $city';
    } else if (city.isNotEmpty) {
      locationText = city;
    } else if (locality != null && locality.isNotEmpty) {
      locationText = locality;
    } else {
      locationText = 'Farm Network';
    }

    return Row(
      children: [
        ModernBackButton(
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/home');
            }
          },
        ),
        const SizedBox(width: 8),
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: RfpTheme.primaryContainer,
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(
            Icons.eco,
            color: RfpTheme.onPrimaryContainer,
            size: 16,
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'LOCATION',
              style: TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
            ),
            Text(
              locationText,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        const Spacer(),
        InkWell(
          onTap: () => context.push('/rfp/deliveries'),
          borderRadius: BorderRadius.circular(AppColors.radiusRound),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.deepSoilGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppColors.radiusRound),
              border: Border.all(
                color: AppColors.deepSoilGreen.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.local_shipping_outlined,
                  size: 15,
                  color: AppColors.deepSoilGreen,
                ),
                SizedBox(width: 5),
                Text(
                  'Deliveries',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepSoilGreen,
                  ),
                ),
                SizedBox(width: 3),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 10,
                  color: AppColors.deepSoilGreen,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
