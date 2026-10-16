import 'package:flutter/material.dart';
import '../rfp_theme.dart';

/// Attractive, customer-friendly modal popup for vegetable selection and swap limits.
class RfpVegetableDialog extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String actionLabel;

  const RfpVegetableDialog({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    this.actionLabel = 'Understood',
  });

  /// Shows popup when maximum swaps / deselections reached or curation is fixed.
  static Future<void> showSwapLimitReached(
    BuildContext context, {
    required String planName,
    required int maxSwaps,
    required bool isCuratedFixed,
  }) {
    return showDialog(
      context: context,
      builder:
          (ctx) => RfpVegetableDialog(
            title:
                isCuratedFixed
                    ? 'Fixed Harvest Curation'
                    : 'Swap Limit Reached',
            message:
                isCuratedFixed
                    ? '$planName is an expertly curated seasonal harvest directly from our morning dawn harvest cycle. Its vegetables are fixed to ensure optimal nutritional balance.'
                    : 'You have used all $maxSwaps allowed swaps for $planName. To customize with a different vegetable, please re-add one of the previously swapped items first.',
            icon:
                isCuratedFixed
                    ? Icons.lock_clock_rounded
                    : Icons.swap_horizontal_circle_outlined,
            iconColor: const Color(0xFFC2410C),
            iconBgColor: const Color(0xFFFFEDD5),
            actionLabel: 'Got It',
          ),
    );
  }

  /// Shows popup when selection limit is reached and user tries to add another item.
  static Future<void> showSelectionLimitReached(
    BuildContext context, {
    required String planName,
    required int limit,
    required String vegetableName,
  }) {
    return showDialog(
      context: context,
      builder:
          (ctx) => RfpVegetableDialog(
            title: 'Box is Full ($limit / $limit)',
            message:
                'Your $planName has reached the maximum box capacity of $limit vegetables. Tap any selected item to remove or swap it before adding "$vegetableName".',
            icon: Icons.inventory_2_outlined,
            iconColor: const Color(0xFF003629),
            iconBgColor: const Color(0xFFC9EEA9),
            actionLabel: 'Understood',
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      elevation: 12,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: iconColor),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
                letterSpacing: -0.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.45,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: RfpTheme.primary,
                  foregroundColor: RfpTheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  actionLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
