import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_farm/core/constants/app_size.dart';

class AppFonts {
  static TextStyle text24normal(BuildContext context, {
    Color color = Colors.grey,
    FontWeight fontWeight = FontWeight.normal,
  }) => GoogleFonts.inter(
    fontSize: AppSizes.fontSizeXXXL(context),
    fontWeight: fontWeight,
    color: color,
  );

  static TextStyle text20normal(BuildContext context,{
    Color color = Colors.grey,
    FontWeight fontWeight = FontWeight.normal,
  }) => GoogleFonts.inter(
    fontSize: AppSizes.fontSizeXXL(context),
    fontWeight: fontWeight,
    color: color,
  );

  static TextStyle text18normal(BuildContext context, {
    Color color = Colors.grey,
    FontWeight fontWeight = FontWeight.normal,
  }) => GoogleFonts.inter(
    fontSize: AppSizes.fontSizeXL(context),
    fontWeight: fontWeight,
    color: color,
  );

  static TextStyle text16normal(BuildContext context,{
    Color color = Colors.grey,
    FontWeight fontWeight = FontWeight.normal,
  }) => GoogleFonts.poppins(
    fontSize: AppSizes.fontSizeL(context),
    fontWeight: fontWeight,
    color: color,
  );

  static TextStyle text14normal(BuildContext context,{
    Color color = Colors.grey,
    FontWeight fontWeight = FontWeight.normal,
  }) => GoogleFonts.poppins(
    fontSize: AppSizes.fontSizeM(context),
    fontWeight: fontWeight,
    color: color,
  );

  static TextStyle text12normal(BuildContext context,{
    Color color = Colors.grey,
    FontWeight fontWeight = FontWeight.normal,
  }) => GoogleFonts.poppins(
    fontSize: AppSizes.fontSizeS(context),
    fontWeight: fontWeight,
    color: color,
  );

  static TextStyle text10normal(BuildContext context,{
    Color color = Colors.grey,
    FontWeight fontWeight = FontWeight.normal,
  }) => GoogleFonts.poppins(
    fontSize: AppSizes.fontSizeXS(context),
    fontWeight: fontWeight,
    color: color,
  );
}
