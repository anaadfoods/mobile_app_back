import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

// The state for this cubit is Flutter's built-in `ThemeMode` enum.
// No separate state class is needed.

class ThemeCubit extends Cubit<ThemeMode> {
  // Initialize the cubit with the system's theme as the default.
  ThemeCubit() : super(ThemeMode.system) {
    _loadTheme();
  }

  static const String _themeKey = 'theme_mode';

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final String? themeStr = prefs.getString(_themeKey);
    if (themeStr != null) {
      if (themeStr == 'dark') {
        emit(ThemeMode.dark);
      } else if (themeStr == 'light') {
        emit(ThemeMode.light);
      } else {
        emit(ThemeMode.system);
      }
    }
  }

  /// Toggles the theme between light and dark mode.
  void toggleTheme(bool isDarkMode) async {
    final mode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    emit(mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, isDarkMode ? 'dark' : 'light');
  }
}
