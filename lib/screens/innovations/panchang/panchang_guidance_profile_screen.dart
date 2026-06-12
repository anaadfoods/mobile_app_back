import '../../../core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grocery_app/core/theme/app_colors.dart';

import '../../../cubits/panchang/panchang_guidance_cubit.dart';
import '../../../cubits/panchang/panchang_guidance_state.dart';
import '../../../models/panchang/panchang_guidance_models.dart';

/// Guidance Preferences Screen
/// Allows users to customize their guidance preferences
class PanchangGuidanceProfileScreen extends StatefulWidget {
  const PanchangGuidanceProfileScreen({super.key});

  @override
  State<PanchangGuidanceProfileScreen> createState() =>
      _PanchangGuidanceProfileScreenState();
}

class _PanchangGuidanceProfileScreenState
    extends State<PanchangGuidanceProfileScreen> {
  // Current selections
  String _dietStyle = 'normal';
  String _fastingPreference = 'none';
  String _devata = 'other';
  String _profile = 'default';
  String _locale = 'en';

  bool _isLoading = true;
  String? _errorMessage;

  // Valid options from backend
  static const List<_SelectOption> dietOptions = [
    _SelectOption('satvik', 'Satvik', '🥗', 'Pure vegetarian, no onion/garlic'),
    _SelectOption('normal', 'Normal', '🍽️', 'Regular vegetarian diet'),
  ];

  static const List<_SelectOption> fastingOptions = [
    _SelectOption('none', 'None', '🚫', 'No fasting preference'),
    _SelectOption('light', 'Light', '🌿', 'Light fasting on special days'),
    _SelectOption('strict', 'Strict', '🙏', 'Strict observance of all fasts'),
  ];

  static const List<_SelectOption> devataOptions = [
    _SelectOption('vishnu', 'Vishnu', '🙏', 'Lord Vishnu'),
    _SelectOption('shiva', 'Shiva', '🕉️', 'Lord Shiva'),
    _SelectOption('devi', 'Devi', '🌺', 'Divine Mother'),
    _SelectOption('ganesh', 'Ganesh', '🐘', 'Lord Ganesha'),
    _SelectOption('other', 'Other', '✨', 'Other deities'),
  ];

  static const List<_SelectOption> profileOptions = [
    _SelectOption('default', 'Default', '🇮🇳', 'Standard Indian Panchang'),
    _SelectOption('north', 'North Indian', '🏔️', 'North Indian traditions'),
    _SelectOption('south', 'South Indian', '🌴', 'South Indian traditions'),
  ];

  static const List<_SelectOption> localeOptions = [
    _SelectOption('en', 'English', '🇬🇧', 'English language'),
    _SelectOption('hi', 'Hindi', '🇮🇳', 'हिंदी भाषा'),
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await context.read<PanchangGuidanceCubit>().loadProfile();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _updateFromProfile(GuidanceProfileResponse profile) {
    setState(() {
      _dietStyle = _validateOption(profile.dietStyle, dietOptions, 'normal');
      _fastingPreference = _validateOption(
        profile.fastingPreference,
        fastingOptions,
        'none',
      );
      _devata = _validateOption(profile.devata, devataOptions, 'other');
      _profile = _validateOption(profile.profile, profileOptions, 'default');
      _locale = _validateOption(profile.locale, localeOptions, 'en');
      _isLoading = false;
    });
  }

  String _validateOption(
    String value,
    List<_SelectOption> options,
    String defaultValue,
  ) {
    return options.any((opt) => opt.value == value) ? value : defaultValue;
  }

  Future<void> _saveProfile() async {
    final request = GuidanceProfileRequest(
      dietStyle: _dietStyle,
      fastingPreference: _fastingPreference,
      devata: _devata,
      profile: _profile,
      locale: _locale,
    );

    await context.read<PanchangGuidanceCubit>().saveProfile(request);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.pureBlack : AppColors.parchment,
      appBar: AppBar(
        backgroundColor:
            isDark ? AppColors.deepSoilGreen : AppColors.deepSoilGreen,
        elevation: 0,
        title: AutoSizeText(
          'Guidance Preferences',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color:
                isDark ? AppColors.parchment : AppColors.charcoal,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: AppColors.parchment,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          BlocBuilder<PanchangGuidanceCubit, PanchangGuidanceState>(
            builder: (context, state) {
              final isLoading = state is PanchangProfileLoading;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TextButton.icon(
                  onPressed: isLoading ? null : _saveProfile,
                  icon:
                      isLoading
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : Icon(Icons.save_rounded),
                  label: AutoSizeText('Save'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.parchment,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocListener<PanchangGuidanceCubit, PanchangGuidanceState>(
        listener: (context, state) {
          if (state is PanchangProfileSuccess) {
            _updateFromProfile(state.profile);
          } else if (state is PanchangProfileSaved) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: AutoSizeText('Preferences saved successfully!'),
                backgroundColor: AppColors.deepSoilGreen,
              ),
            );
            Navigator.pop(context);
          } else if (state is PanchangProfileError) {
            setState(() {
              _isLoading = false;
              _errorMessage = state.message;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: AutoSizeText('Error: ${state.message}'),
                backgroundColor: AppColors.rawEarth,
              ),
            );
          }
        },
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? _buildErrorState(isDark)
                : _buildContent(isDark),
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.rawEarth),
          const SizedBox(height: 16),
          AutoSizeText(
            'Error loading preferences',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color:
                  isDark ? AppColors.parchment : AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: AutoSizeText(
              _errorMessage ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.pureWhite.withValues(alpha: 0.54) : AppColors.charcoal54,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadProfile,
            icon: Icon(Icons.refresh),
            label: AutoSizeText('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionCard(
            title: 'Diet Style',
            subtitle: 'Your dietary preferences',
            icon: Icons.restaurant,
            color: AppColors.deepSoilGreen,
            isDark: isDark,
            child: _buildOptionGrid(
              options: dietOptions,
              selectedValue: _dietStyle,
              onChanged: (value) => setState(() => _dietStyle = value),
              isDark: isDark,
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Fasting Preference',
            subtitle: 'Your fasting observance level',
            icon: Icons.self_improvement,
            color: AppColors.harvestAmber,
            isDark: isDark,
            child: _buildOptionGrid(
              options: fastingOptions,
              selectedValue: _fastingPreference,
              onChanged: (value) => setState(() => _fastingPreference = value),
              isDark: isDark,
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Devata (Deity)',
            subtitle: 'Your primary deity for worship',
            icon: Icons.temple_hindu,
            color: isDark ? AppColors.pureWhite : AppColors.parchment,
            isDark: isDark,
            child: _buildOptionGrid(
              options: devataOptions,
              selectedValue: _devata,
              onChanged: (value) => setState(() => _devata = value),
              isDark: isDark,
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Regional Profile',
            subtitle: 'Regional calendar variations',
            icon: Icons.location_on,
            color: isDark ? AppColors.pureWhite : AppColors.parchment,
            isDark: isDark,
            child: _buildOptionGrid(
              options: profileOptions,
              selectedValue: _profile,
              onChanged: (value) => setState(() => _profile = value),
              isDark: isDark,
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Language',
            subtitle: 'Preferred language for guidance',
            icon: Icons.language,
            color: AppColors.deepSoilGreen,
            isDark: isDark,
            child: _buildOptionGrid(
              options: localeOptions,
              selectedValue: _locale,
              onChanged: (value) => setState(() => _locale = value),
              isDark: isDark,
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color:
            (isDark
                ? AppColors.charcoal
                : AppColors.parchment),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: isDark ? 0.2 : 0.1),
                  color.withValues(alpha: isDark ? 0.1 : 0.05),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AutoSizeText(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color:
                            (isDark
                                ? AppColors.parchment
                                : AppTheme
                                    .lightTheme
                                    .textTheme
                                    .bodyLarge
                                    ?.color),
                      ),
                    ),
                    AutoSizeText(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: (isDark ? AppColors.pureWhite : AppColors.charcoal)
                            .withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }

  Widget _buildOptionGrid({
    required List<_SelectOption> options,
    required String selectedValue,
    required ValueChanged<String> onChanged,
    required bool isDark,
  }) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children:
          options.map((option) {
            final isSelected = option.value == selectedValue;
            return GestureDetector(
              onTap: () => onChanged(option.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? const Color(
                            0xFF3F5E46,
                          ).withValues(alpha: isDark ? 0.3 : 0.15)
                          : (isDark
                              ? AppColors.parchment.withValues(alpha: 0.05)
                              : AppColors.parchment),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        isSelected
                            ? AppColors.parchment
                            : (isDark
                                ? AppColors.parchment.withValues(alpha: 0.1)
                                : AppColors.rawEarth12),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AutoSizeText(
                      option.emoji,
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AutoSizeText(
                          option.label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w500,
                            color:
                                isSelected
                                    ? AppColors.parchment
                                    : (isDark ? AppColors.pureWhite : AppColors.charcoal),
                          ),
                        ),
                      ],
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.check_circle,
                        color: isDark ? AppColors.pureWhite : AppColors.parchment,
                        size: 18,
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }
}

class _SelectOption {
  final String value;
  final String label;
  final String emoji;
  final String description;

  const _SelectOption(this.value, this.label, this.emoji, this.description);
}
