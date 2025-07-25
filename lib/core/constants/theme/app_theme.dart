import 'package:flutter/material.dart';
import 'app_color.dart';

/// Defines the light and dark themes for the Smart Farm App.
class AppThemes {
  /// Light Theme for the Smart Farm App.
  /// It uses a white background, primary green swatch, and dark text.
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch:
        AppColors.primaryGreenSwatch, // Uses the defined MaterialColor swatch
    primaryColor: AppColors.primaryGreen,
    scaffoldBackgroundColor: AppColors.background, // White background
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primaryGreen,
      foregroundColor: AppColors.background, // White text/icons on app bar
      titleTextStyle: TextStyle(
        color: AppColors.background, // White title text
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    // Text theme for various text styles
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: AppColors.primaryText),
      displayMedium: TextStyle(color: AppColors.primaryText),
      displaySmall: TextStyle(color: AppColors.primaryText),
      headlineLarge: TextStyle(color: AppColors.primaryText),
      headlineMedium: TextStyle(color: AppColors.primaryText),
      headlineSmall: TextStyle(color: AppColors.primaryText),
      titleLarge: TextStyle(color: AppColors.primaryText),
      titleMedium: TextStyle(color: AppColors.primaryText),
      titleSmall: TextStyle(color: AppColors.primaryText),
      bodyLarge: TextStyle(color: AppColors.primaryText),
      bodyMedium: TextStyle(color: AppColors.primaryText),
      bodySmall: TextStyle(
        color: AppColors.secondaryText,
      ), // Secondary text for smaller elements
      labelLarge: TextStyle(color: AppColors.primaryText),
      labelMedium: TextStyle(color: AppColors.secondaryText),
      labelSmall: TextStyle(color: AppColors.disabledText), // Disabled text
    ),
    // Button themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor:
            AppColors.primaryGreen, // Primary green for elevated buttons
        foregroundColor: AppColors.background, // White text on buttons
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.secondaryOrange, // Orange for text buttons
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryGreen,
        side: const BorderSide(color: AppColors.primaryGreen),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    ),
    // Input field decoration
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.borderDivider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.borderDivider),
      ),
      labelStyle: const TextStyle(color: AppColors.secondaryText),
      hintStyle: const TextStyle(color: AppColors.disabledText),
      floatingLabelStyle: const TextStyle(color: AppColors.primaryGreen),
    ),
    // Card theme
    cardTheme: CardTheme(
      color: AppColors.background, // White cards
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(8),
    ),
    // Icon theme
    iconTheme: const IconThemeData(
      color: AppColors.primaryText, // Default icon color
    ),
    // Divider color
    dividerColor: AppColors.borderDivider,
    // Accent color for progress indicators, etc.
    colorScheme: ColorScheme.fromSwatch(
      primarySwatch: AppColors.primaryGreenSwatch,
      accentColor: AppColors.accentYellow, // Golden Yellow as accent
      backgroundColor: AppColors.background,
      errorColor: AppColors.error,
      brightness: Brightness.light,
    ).copyWith(
      secondary: AppColors.secondaryOrange,
    ), // Secondary orange for secondary elements
  );

  /// Dark Theme for the Smart Farm App.
  /// It uses a dark background, primary green swatch, and light text.
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: AppColors.primaryGreenSwatch,
    primaryColor: AppColors.primaryGreen,
    scaffoldBackgroundColor: const Color(
      0xFF121212,
    ), // Very dark gray/black for background
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(
        0xFF1F1F1F,
      ), // Slightly lighter dark gray for app bar
      foregroundColor: AppColors.background, // White text/icons on app bar
      titleTextStyle: TextStyle(
        color: AppColors.background, // White title text
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    // Text theme for various text styles, adjusted for dark background
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: AppColors.background),
      displayMedium: TextStyle(color: AppColors.background),
      displaySmall: TextStyle(color: AppColors.background),
      headlineLarge: TextStyle(color: AppColors.background),
      headlineMedium: TextStyle(color: AppColors.background),
      headlineSmall: TextStyle(color: AppColors.background),
      titleLarge: TextStyle(color: AppColors.background),
      titleMedium: TextStyle(color: AppColors.background),
      titleSmall: TextStyle(color: AppColors.background),
      bodyLarge: TextStyle(color: AppColors.background),
      bodyMedium: TextStyle(color: AppColors.background),
      bodySmall: TextStyle(
        color: AppColors.borderDivider,
      ), // Lighter gray for secondary text
      labelLarge: TextStyle(color: AppColors.background),
      labelMedium: TextStyle(color: AppColors.borderDivider),
      labelSmall: TextStyle(
        color: AppColors.secondaryText,
      ), // Slightly darker for disabled
    ),
    // Button themes, adjusted for dark background
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.secondaryOrange),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryGreen,
        side: const BorderSide(color: AppColors.primaryGreen),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    ),
    // Input field decoration
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: AppColors.secondaryText,
        ), // Darker border
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.secondaryText),
      ),
      labelStyle: const TextStyle(color: AppColors.borderDivider),
      hintStyle: const TextStyle(color: AppColors.secondaryText),
      floatingLabelStyle: const TextStyle(color: AppColors.primaryGreen),
    ),
    // Card theme
    cardTheme: CardTheme(
      color: const Color(0xFF1F1F1F), // Darker cards
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(8),
    ),
    // Icon theme
    iconTheme: const IconThemeData(
      color: AppColors.background, // White icons
    ),
    // Divider color
    dividerColor: AppColors.secondaryText,
    // Accent color for dark theme
    colorScheme: ColorScheme.fromSwatch(
      primarySwatch: AppColors.primaryGreenSwatch,
      accentColor: AppColors.accentYellow,
      backgroundColor: const Color(0xFF121212),
      errorColor: AppColors.error,
      brightness: Brightness.dark,
    ).copyWith(secondary: AppColors.secondaryOrange),
  );
}
