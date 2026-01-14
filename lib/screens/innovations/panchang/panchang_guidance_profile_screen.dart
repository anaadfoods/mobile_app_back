import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _updateFromProfile(GuidanceProfileResponse profile) {
    setState(() {
      _dietStyle = _validateOption(profile.dietStyle, dietOptions, 'normal');
      _fastingPreference = _validateOption(profile.fastingPreference, fastingOptions, 'none');
      _devata = _validateOption(profile.devata, devataOptions, 'other');
      _profile = _validateOption(profile.profile, profileOptions, 'default');
      _locale = _validateOption(profile.locale, localeOptions, 'en');
      _isLoading = false;
    });
  }

  String _validateOption(String value, List<_SelectOption> options, String defaultValue) {
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
      backgroundColor: isDark ? const Color(0xFF0F0F23) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        elevation: 0,
        title: Text(
          'Guidance Preferences',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? Colors.white : Colors.black87,
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
                  icon: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_rounded),
                  label: const Text('Save'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue,
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
                content: Text('Preferences saved successfully!'),
                backgroundColor: Colors.green,
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
                content: Text('Error: ${state.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: _isLoading
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
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
          const SizedBox(height: 16),
          Text(
            'Error loading preferences',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadProfile,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
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
            color: Colors.green,
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
            color: Colors.orange,
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
            color: Colors.purple,
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
            color: Colors.blue,
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
            color: Colors.teal,
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
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
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
                  color.withOpacity(isDark ? 0.2 : 0.1),
                  color.withOpacity(isDark ? 0.1 : 0.05),
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: (isDark ? Colors.white : Colors.black).withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
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
      children: options.map((option) {
        final isSelected = option.value == selectedValue;
        return GestureDetector(
          onTap: () => onChanged(option.value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.blue.withOpacity(isDark ? 0.3 : 0.15)
                  : (isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? Colors.blue
                    : (isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade300),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(option.emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? Colors.blue
                            : (isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                  ],
                ),
                if (isSelected) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.check_circle, color: Colors.blue, size: 18),
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

