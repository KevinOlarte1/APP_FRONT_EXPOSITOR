import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  static final TextStyle TITLE_APPBAR = GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.WHITE_COLOR,
  );

  static final TextStyle SUBTITLE_APPBAR = GoogleFonts.poppins(
    fontSize: 14,
    color: AppColors.GRAY_FONT,
  );

  static final TextStyle TITLE_CARD = GoogleFonts.poppins(
    fontWeight: FontWeight.w600,
    fontSize: 16,
    color: AppColors.BLACK_FONT,
  );

}
