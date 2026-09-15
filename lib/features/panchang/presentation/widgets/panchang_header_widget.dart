import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:grocery_app/core/theme/app_colors.dart';

class PanchangHeaderWidget extends StatelessWidget {
  final DateTime selectedDate;
  final bool isDark;
  final VoidCallback onDateTap;
  final VoidCallback? onPreviousDay;
  final VoidCallback? onNextDay;
  final VoidCallback? onTodayTap;
  final String locationLabel;
  final VoidCallback? onLocationTap;
  final VoidCallback? onBack;

  const PanchangHeaderWidget({
    super.key,
    required this.selectedDate,
    required this.isDark,
    required this.onDateTap,
    this.onPreviousDay,
    this.onNextDay,
    this.onTodayTap,
    this.locationLabel = 'New Delhi, India (28.61° N, 77.21° E)',
    this.onLocationTap,
    this.onBack,
  });

  Widget _buildModernIconButton({
    required IconData icon,
    required VoidCallback onTap,
    required ThemeData theme,
    String? tooltip,
  }) {
    final button = TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.onPrimary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.2 * value),
                blurRadius: 10,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Transform.rotate(
            angle: math.sin(value * math.pi * 2) * 0.08,
            child: Icon(icon, color: theme.colorScheme.onPrimary, size: 20),
          ),
        );
      },
    );

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: tooltip != null
          ? Tooltip(message: tooltip, child: button)
          : button,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final isToday = selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.deepSoilGreen, Color(0xFF3D6B28)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Row: Back Button, Logo, Title, Verification Badge, Month Calendar, Chakra
            Padding(
              padding: EdgeInsets.only(
                left: screenWidth * 0.04,
                right: screenWidth * 0.04,
                top: 10,
                bottom: 6,
              ),
              child: Row(
                children: [
                  _buildModernIconButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: onBack ?? () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        context.go('/home');
                      }
                    },
                    theme: theme,
                    tooltip: 'Back',
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                'Vedic Panchang',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.2,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.onPrimary.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppColors.harvestAmber.withValues(
                                    alpha: 0.4,
                                  ),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(
                                    Icons.verified_rounded,
                                    size: 10,
                                    color: AppColors.harvestAmber,
                                  ),
                                  SizedBox(width: 3),
                                  Text(
                                    'NASA DE421',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.harvestAmber,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        GestureDetector(
                          onTap: onLocationTap,
                          behavior: HitTestBehavior.opaque,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 13,
                                color: theme.colorScheme.onPrimary.withValues(
                                  alpha: 0.9,
                                ),
                              ),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  locationLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: theme.colorScheme.onPrimary.withValues(
                                      alpha: 0.95,
                                    ),
                                    fontWeight: FontWeight.w500,
                                    decoration: TextDecoration.underline,
                                    decorationColor: theme.colorScheme.onPrimary.withValues(alpha: 0.4),
                                    decorationStyle: TextDecorationStyle.dotted,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                Icons.arrow_drop_down_rounded,
                                size: 16,
                                color: theme.colorScheme.onPrimary.withValues(alpha: 0.85),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildModernIconButton(
                    icon: Icons.calendar_month_rounded,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.push('/panchang-month');
                    },
                    theme: theme,
                    tooltip: 'Monthly Calendar',
                  ),
                ],
              ),
            ),

            // Date Navigation Row
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: 8,
              ),
              child: Row(
                children: [
                  if (onPreviousDay != null)
                    _buildModernIconButton(
                      icon: Icons.chevron_left_rounded,
                      onTap: onPreviousDay!,
                      theme: theme,
                      tooltip: 'Previous Day',
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        onDateTap();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onPrimary.withValues(
                            alpha: 0.15,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: theme.colorScheme.onPrimary.withValues(
                              alpha: 0.2,
                            ),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 15,
                              color: AppColors.harvestAmber,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                DateFormat('EEE, d MMM yyyy').format(selectedDate),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 18,
                              color: theme.colorScheme.onPrimary.withValues(
                                alpha: 0.7,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (onNextDay != null)
                    _buildModernIconButton(
                      icon: Icons.chevron_right_rounded,
                      onTap: onNextDay!,
                      theme: theme,
                      tooltip: 'Next Day',
                    ),
                  if (!isToday && onTodayTap != null) ...[
                    const SizedBox(width: 8),
                    _buildModernIconButton(
                      icon: Icons.today_rounded,
                      onTap: onTodayTap!,
                      theme: theme,
                      tooltip: 'Today',
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}
