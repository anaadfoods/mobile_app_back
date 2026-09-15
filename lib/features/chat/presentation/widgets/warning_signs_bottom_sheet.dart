import 'package:flutter/material.dart';
import 'package:grocery_app/core/theme/app_colors.dart';

/// A calm, non-alarming safety bottom sheet.
class WarningSignsBottomSheet extends StatelessWidget {
  const WarningSignsBottomSheet({Key? key}) : super(key: key);

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const WarningSignsBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.parchment,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppColors.harvestAmber,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "When to seek medical help",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.charcoal,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              "Anaad AI cannot determine the cause of your symptoms. This information is for awareness only.",
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : AppColors.charcoal54,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            _buildSignItem("Fever that persists beyond 48 hours", isDark),
            _buildSignItem("Symptoms that worsen despite rest", isDark),
            _buildSignItem(
              "Severe pain, difficulty breathing, or confusion",
              isDark,
            ),
            _buildSignItem("Symptoms that concern you for any reason", isDark),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.harvestAmber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.medical_services_outlined,
                    color: AppColors.harvestAmber,
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "If you experience any of these, please consult a healthcare professional.",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.harvestAmber,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignItem(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.circle,
            size: 8,
            color: isDark ? Colors.white54 : AppColors.charcoal40,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white : AppColors.charcoal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
