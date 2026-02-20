import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grocery_app/common_widgets/global_import.dart';

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
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Your Experience',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: theme.textTheme.bodyLarge?.color?.withAlpha(204),
              letterSpacing: 0.3,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Haptic Feedback Toggle
              _buildAnimatedSwitchItem(
                theme,
                context,
                icon: Icons.vibration_rounded,
                title: 'Haptic Feedback',
                subtitle:
                    vibrationEnabled
                        ? 'Feel subtle vibrations'
                        : 'Vibrations disabled',
                value: vibrationEnabled,
                iconColor: Colors.deepPurple,
                onChanged: (value) {
                  if (value) {
                    HapticFeedback.mediumImpact();
                  }
                  onVibrationChanged(value);
                },
              ),
              Padding(
                padding: const EdgeInsets.only(left: 60),
                child: Divider(
                  height: 1,
                  color: theme.dividerColor.withAlpha(38),
                ),
              ),
              // Dark Mode Toggle
              BlocBuilder<ThemeCubit, ThemeMode>(
                builder: (context, themeMode) {
                  final isDarkMode =
                      themeMode == ThemeMode.dark ||
                      (themeMode == ThemeMode.system &&
                          MediaQuery.of(context).platformBrightness ==
                              Brightness.dark);

                  return _buildAnimatedSwitchItem(
                    theme,
                    context,
                    icon:
                        isDarkMode
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                    title: 'Dark Mode',
                    subtitle:
                        isDarkMode
                            ? 'Dark theme enabled'
                            : 'Light theme enabled',
                    value: isDarkMode,
                    iconColor: Colors.blueGrey,
                    onChanged: (value) {
                      _triggerHaptic();
                      context.read<ThemeCubit>().toggleTheme(value);
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

  void _triggerHaptic() {
    if (vibrationEnabled) {
      HapticFeedback.lightImpact();
    }
  }

  Widget _buildAnimatedSwitchItem(
    ThemeData theme,
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Color iconColor,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: value ? 1.0 : 0.0),
            duration: const Duration(milliseconds: 300),
            builder: (context, animValue, child) {
              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Color.lerp(
                    iconColor.withAlpha(25),
                    iconColor.withAlpha(64),
                    animValue,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              );
            },
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 2),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    subtitle,
                    key: ValueKey(subtitle),
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.textTheme.bodyMedium?.color?.withAlpha(127),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildCustomSwitch(theme, value, onChanged),
        ],
      ),
    );
  }

  Widget _buildCustomSwitch(
    ThemeData theme,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        width: 52,
        height: 30,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient:
              value
                  ? LinearGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.primary.withAlpha(204),
                    ],
                  )
                  : null,
          color: value ? null : theme.dividerColor.withAlpha(76),
          boxShadow:
              value
                  ? [
                    BoxShadow(
                      color: colorScheme.primary.withAlpha(76),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : null,
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.all(3),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(25),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child:
                  value
                      ? Icon(
                        Icons.check_rounded,
                        key: const ValueKey('check'),
                        size: 14,
                        color: colorScheme.primary,
                      )
                      : const SizedBox(key: ValueKey('empty')),
            ),
          ),
        ),
      ),
    );
  }
}
