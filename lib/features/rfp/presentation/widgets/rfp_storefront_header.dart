import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:grocery_app/common_widgets/modern_back_button.dart';
import 'package:grocery_app/core/theme/app_colors.dart';
import 'package:grocery_app/core/theme/app_text_styles.dart';
import '../../domain/entities/rfp_batch.dart';
import '../cubit/rfp_dashboard_cubit.dart';
import '../rfp_theme.dart';

/// Top header banner and field note card for the Batch Builder storefront.
class RfpStorefrontHeader extends StatelessWidget {
  final RfpBatch batch;
  final VoidCallback onBackTap;

  const RfpStorefrontHeader({
    super.key,
    required this.batch,
    required this.onBackTap,
  });

  String _daySuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d');
    final startStr = dateFormat.format(batch.startDate);
    final endStr =
        '${dateFormat.format(batch.endDate)}${_daySuffix(batch.endDate.day)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ModernBackButton(
              onPressed: onBackTap,
              iconColor: Colors.white,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
            ),
            BlocBuilder<RfpDashboardCubit, RfpDashboardState>(
              builder: (context, dashboardState) {
                final hasBooking = dashboardState.hasBooking;
                const label = 'My Active Plan';

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      context.push('/rfp/dashboard');
                    },
                    borderRadius: BorderRadius.circular(AppColors.radiusRound),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color:
                            hasBooking
                                ? AppColors.harvestAmber.withValues(alpha: 0.22)
                                : Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(
                          AppColors.radiusRound,
                        ),
                        border: Border.all(
                          color:
                              hasBooking
                                  ? AppColors.harvestAmber.withValues(
                                    alpha: 0.7,
                                  )
                                  : Colors.white.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            hasBooking
                                ? Icons.eco_rounded
                                : Icons.dashboard_outlined,
                            size: 15,
                            color:
                                hasBooking
                                    ? AppColors.harvestAmber
                                    : Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            label,
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color:
                                  hasBooking
                                      ? AppColors.harvestAmber
                                      : Colors.white,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 10,
                            color:
                                hasBooking
                                    ? AppColors.harvestAmber
                                    : Colors.white70,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 20),
        Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.eco, size: 14, color: Color(0xFF8ABDA9)),
                  const SizedBox(width: 6),
                  Text(
                    'HANDCRAFTED HEARTH',
                    style: RfpTheme.labelSm.copyWith(
                      color: const Color(0xFF8ABDA9),
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.eco, size: 14, color: Color(0xFF8ABDA9)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                (batch.seasonLabel ?? 'HARVEST BATCH').toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: Colors.white70,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Deliveries run from $startStr to $endStr',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (batch.generalNote != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 0.5,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8ABDA9).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Color(0xFF8ABDA9),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FIELD NOTE • Microclimate Update',
                        style: RfpTheme.labelSm.copyWith(
                          color: const Color(0xFF8ABDA9),
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        batch.generalNote!,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
