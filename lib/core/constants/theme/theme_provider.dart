import 'package:flutter/material.dart';

/// ThemeProvider is a ChangeNotifier that manages the app's theme mode (light or dark).
///
/// This allows you to easily switch between light and dark themes in your app.
/// You can use ThemeProvider with a Provider or similar state management solution.
///
/// Example usage:
///   final themeProvider = Provider.of<ThemeProvider>(context);
///   themeProvider.toggleTheme(); // Switches between light and dark mode
class ThemeProvider extends ChangeNotifier {
  /// The current theme mode of the app.
  ThemeMode _themeMode = ThemeMode.light;

  /// Returns the current theme mode.
  ThemeMode get themeMode => _themeMode;

  /// Returns true if the current theme is dark.
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  /// Sets the theme mode and notifies listeners.
  void setTheme(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  /// Toggles between light and dark theme modes.
  void toggleTheme() {
    if (_themeMode == ThemeMode.light) {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.light;
    }
    notifyListeners();
  }
}
