import 'package:flutter/material.dart';

/// A collection of colors for the Smart Farm App,
/// designed to provide a cohesive and appealing visual experience.
class AppColors {
  // Core Colors
  static const Color background = Color(0xFFFCFBFC); // White
  static const Color secondaryOrange = Color(0xFFFF8C00); // Dark Orange
  static const Color tertiaryPurple = Color(0xFF8A2BE2); // Blue Violet

  //text color
  static const Color primaryTextColor = Color(0xFF6A8F80);

  // Suggested Additional Colors
  static const Color primaryGreen = Color(0xFFC2E96A); // Farm Green
  static const Color accentYellow = Color(0xFFFFD700); // Golden Yellow

  // Text & Icon Colors
  static const Color primaryText = Color(0xFF333333); // Dark Gray
  static const Color secondaryText = Color(0xFF666666); // Medium Gray
  static const Color disabledText = Color(0xFFBBBBBB); // Light Gray

  // Neutral & Utility Colors
  static const Color borderDivider = Color(0xFFE0E0E0); // Light Blue-Gray
  static const Color success = Color(0xFF28A745); // Teal Green
  static const Color warning = Color(
    0xFFF0AD4E,
  ); // Gold (Adjusted for better contrast in Dart, original was FF C107)
  static const Color error = Color(0xFFDC3545); // Crimson Red

  // You can also define a primary swatch for Material App theming if needed:
  static const MaterialColor primaryGreenSwatch = MaterialColor(
    0xffC2E96A,
    <int, Color>{
      50: Color(0xFFE8F5E9),
      100: Color(0xFFC8E6C9),
      200: Color(0xFFA5D6A7),
      300: Color(0xFF81C784),
      400: Color(0xFF66BB6A),
      500: Color(0xFF4CAF50), // Primary shade
      600: Color(0xFF43A047),
      700: Color(0xFF388E3C),
      800: Color(0xFF2E7D32),
      900: Color(0xFF1B5E20),
    },
  );
}
