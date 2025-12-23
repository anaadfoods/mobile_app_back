import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// The state for this cubit is Flutter's built-in `ThemeMode` enum.
// No separate state class is needed.

class ThemeCubit extends Cubit<ThemeMode> {
  // Initialize the cubit with the system's theme as the default.
  ThemeCubit() : super(ThemeMode.system);

  /// Toggles the theme between light and dark mode.
  void toggleTheme(bool isDarkMode) {
    emit(isDarkMode ? ThemeMode.dark : ThemeMode.light);
  }
}