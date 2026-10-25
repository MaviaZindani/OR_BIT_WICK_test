import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:product_explorer/constant/app_colors.dart';
import 'package:product_explorer/constant/data_const.dart';

/// Text styles for the app, composed from the sizes and weights in
/// [DataConst] so the two constant files never drift apart.
class AppTextStyles {
  static TextStyle get screenTitle => GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.darkText,
  );

  static TextStyle get sectionHeading => GoogleFonts.poppins(
    fontSize: DataConst.medimTextSize,
    fontWeight: DataConst.highFontWeight,
    color: AppColors.darkText,
  );

  /// Product name on a grid card.
  static TextStyle get cardTitle => GoogleFonts.poppins(
    fontSize: DataConst.normalTextSize,
    fontWeight: DataConst.medimFontWeight,
    color: AppColors.darkText,
    height: 1.3,
  );

  static TextStyle get cardSubtitle => GoogleFonts.poppins(
    fontSize: DataConst.lowTextSize,
    fontWeight: DataConst.lowFontWeight,
    color: AppColors.greyText,
  );

  static TextStyle get price => GoogleFonts.poppins(
    fontSize: DataConst.medimTextSize,
    fontWeight: FontWeight.w700,
    color: AppColors.darkText,
  );

  /// Original price shown struck through next to a discounted one.
  static TextStyle get strikePrice => GoogleFonts.poppins(
    fontSize: DataConst.lowTextSize,
    fontWeight: DataConst.lowFontWeight,
    color: AppColors.greyText,
    decoration: TextDecoration.lineThrough,
  );

  static TextStyle get detailTitle => GoogleFonts.poppins(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.darkText,
    height: 1.3,
  );

  static TextStyle get detailPrice => GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
  );

  static TextStyle get body => GoogleFonts.poppins(
    fontSize: DataConst.normalTextSize,
    fontWeight: DataConst.lowFontWeight,
    color: AppColors.greyText,
    height: 1.6,
  );

  static TextStyle get label => GoogleFonts.poppins(
    fontSize: DataConst.lowTextSize,
    fontWeight: DataConst.medimFontWeight,
    color: AppColors.greyText,
  );

  static TextStyle get chipLabel => GoogleFonts.poppins(
    fontSize: DataConst.lowTextSize + 1,
    fontWeight: DataConst.medimFontWeight,
    color: AppColors.darkText,
  );

  static TextStyle get chipLabelSelected =>
      chipLabel.copyWith(color: AppColors.lightText);

  static TextStyle get badge => GoogleFonts.poppins(
    fontSize: 11,
    fontWeight: DataConst.highFontWeight,
    color: AppColors.lightText,
  );

  static TextStyle get buttonLabel => GoogleFonts.poppins(
    fontSize: DataConst.normalTextSize,
    fontWeight: DataConst.highFontWeight,
    color: AppColors.lightText,
  );

  static TextStyle get searchHint => GoogleFonts.poppins(
    fontSize: DataConst.normalTextSize,
    fontWeight: DataConst.lowFontWeight,
    color: AppColors.greyText,
  );

  /// Bottom-up scrim so a label stays legible over any product photo.
  static const LinearGradient imageScrim = LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.center,
    colors: [Color(0x99000000), Color(0x00000000)],
  );
}
