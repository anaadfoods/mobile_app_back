import 'package:grocery_app/common_widgets/global_import.dart';

/// Inline quick-action toggles for haptic feedback and dark mode.
/// Displayed as a horizontal row of pill-shaped toggle chips.
class AccountPreferencesSection extends StatelessWidget {
  final bool vibrationEnabled;
  final ValueChanged<bool> onVibrationChanged;

  const AccountPreferencesSection({
    super.key,
    required this.vibrationEnabled,
    required this.onVibrationChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            'QUICK SETTINGS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: theme.textTheme.bodyMedium?.color?.withAlpha(130),
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Haptic toggle
              _buildQuickToggle(
                theme,
                context,
                icon: Icons.vibration_rounded,
                label: 'Haptic',
                isActive: vibrationEnabled,
                activeColor: Colors.deepPurple,
                onTap: () {
                  if (!vibrationEnabled) {
                    HapticFeedback.mediumImpact();
                  }
                  onVibrationChanged(!vibrationEnabled);
                },
              ),
              const SizedBox(width: 12),
              // Dark mode toggle
              BlocBuilder<ThemeCubit, ThemeMode>(
                builder: (context, themeMode) {
                  final isDarkMode = themeMode == ThemeMode.dark ||
                      (themeMode == ThemeMode.system &&
                          MediaQuery.of(context).platformBrightness ==
                              Brightness.dark);

                  return _buildQuickToggle(
                    theme,
                    context,
                    icon: isDarkMode
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                    label: isDarkMode ? 'Dark' : 'Light',
                    isActive: isDarkMode,
                    activeColor: Colors.blueGrey,
                    onTap: () {
                      if (vibrationEnabled) {
                        HapticFeedback.lightImpact();
                      }
                      context.read<ThemeCubit>().toggleTheme(!isDarkMode);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickToggle(
    ThemeData theme,
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withAlpha(25)
              : theme.dividerColor.withAlpha(40),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isActive ? activeColor.withAlpha(80) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: Icon(
                icon,
                key: ValueKey('$icon-$isActive'),
                size: 20,
                color: isActive
                    ? activeColor
                    : theme.textTheme.bodyMedium?.color?.withAlpha(140),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive
                    ? activeColor
                    : theme.textTheme.bodyMedium?.color?.withAlpha(140),
              ),
            ),
          ],
        ),
      ),
    );
  }
}