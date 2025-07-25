import 'package:flutter/widgets.dart';

/// A utility class for responsive app sizing using MediaQuery.
/// Use these methods to get consistent, responsive paddings, margins, radii, and icon sizes.
class AppSizes {
  // Padding & Margin
  static double paddingXS(BuildContext context) => _responsive(context, 4.0);
  static double paddingS(BuildContext context) => _responsive(context, 8.0);
  static double paddingM(BuildContext context) => _responsive(context, 16.0);
  static double paddingL(BuildContext context) => _responsive(context, 24.0);
  static double paddingXL(BuildContext context) => _responsive(context, 32.0);

  static double marginXS(BuildContext context) => _responsive(context, 4.0);
  static double marginS(BuildContext context) => _responsive(context, 8.0);
  static double marginM(BuildContext context) => _responsive(context, 16.0);
  static double marginL(BuildContext context) => _responsive(context, 24.0);
  static double marginXL(BuildContext context) => _responsive(context, 32.0);

  // Border Radius
  static double radiusXS(BuildContext context) => _responsive(context, 4.0);
  static double radiusS(BuildContext context) => _responsive(context, 8.0);
  static double radiusM(BuildContext context) => _responsive(context, 12.0);
  static double radiusL(BuildContext context) => _responsive(context, 20.0);
  static double radiusXL(BuildContext context) => _responsive(context, 32.0);

  // Icon Sizes
  static double iconXS(BuildContext context) => _responsive(context, 16.0);
  static double iconS(BuildContext context) => _responsive(context, 20.0);
  static double iconM(BuildContext context) => _responsive(context, 24.0);
  static double iconL(BuildContext context) => _responsive(context, 32.0);
  static double iconXL(BuildContext context) => _responsive(context, 40.0);

  // Button Heights
  static double buttonHeightS(BuildContext context) => _responsive(context, 36.0);
  static double buttonHeightM(BuildContext context) => _responsive(context, 48.0);
  static double buttonHeightL(BuildContext context) => _responsive(context, 56.0);

  // AppBar Height
  static double appBarHeight(BuildContext context) => _responsive(context, 56.0);

  // General Spacing
  static double spaceXS(BuildContext context) => _responsive(context, 4.0);
  static double spaceS(BuildContext context) => _responsive(context, 8.0);
  static double spaceM(BuildContext context) => _responsive(context, 16.0);
  static double spaceL(BuildContext context) => _responsive(context, 24.0);
  static double spaceXL(BuildContext context) => _responsive(context, 32.0);

  // Font Sizes
static double fontSizeXS(BuildContext context) => _responsive(context, 10.0);
static double fontSizeS(BuildContext context) => _responsive(context, 12.0);
static double fontSizeM(BuildContext context) => _responsive(context, 14.0);
static double fontSizeL(BuildContext context) => _responsive(context, 16.0);
static double fontSizeXL(BuildContext context) => _responsive(context, 18.0);
static double fontSizeXXL(BuildContext context) => _responsive(context, 20.0);
static double fontSizeXXXL(BuildContext context) => _responsive(context, 24.0);




  /// Private helper for responsive sizing.
  /// Scales the base size according to the device's screen width.
  static double _responsive(BuildContext context, double baseSize) {
    final width = MediaQuery.of(context).size.width;
    // 375 is a common base width (iPhone 11/12/13/14)
    return baseSize * (width / 375.0);
  }
}

