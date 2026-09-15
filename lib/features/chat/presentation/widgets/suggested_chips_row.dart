import 'package:flutter/material.dart';
import 'package:grocery_app/core/theme/app_colors.dart';

/// Gemini-style Boxed Recommendation Chips Row.
class SuggestedChipsRow extends StatelessWidget {
  final List<String> chips;
  final Function(String) onChipTap;
  final bool isEnabled;

  const SuggestedChipsRow({
    Key? key,
    required this.chips,
    required this.onChipTap,
    this.isEnabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (chips.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedOpacity(
      opacity: isEnabled ? 1.0 : 0.4,
      duration: const Duration(milliseconds: 300),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
        child: Row(
          children:
              chips.map((chip) {
                return Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: isEnabled ? () => onChipTap(chip) : null,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11.0,
                          vertical: 5.5,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isDark
                                  ? AppColors.darkSurfaceElevated
                                  : AppColors.pureWhite,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.harvestAmber.withValues(
                              alpha: 0.35,
                            ),
                            width: 0.8,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isDark ? 0.15 : 0.03,
                              ),
                              blurRadius: 4,
                              offset: const Offset(0, 1.5),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.lightbulb_outline_rounded,
                              size: 13,
                              color: AppColors.harvestAmber,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              chip,
                              style: TextStyle(
                                color:
                                    isDark ? Colors.white : AppColors.charcoal,
                                fontSize: 11.8,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }
}
