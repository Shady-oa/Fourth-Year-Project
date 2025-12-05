import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

TextTheme createTextTheme(Color textColor) {
  return TextTheme(
    displaySmall: GoogleFonts.urbanist(
      fontSize: 28.0,
      color: textColor,
      fontWeight: FontWeight.bold,
    ),
    headlineSmall: GoogleFonts.urbanist(
      fontSize: 20.0,
      color: textColor,
      fontWeight: FontWeight.bold,
    ),
    titleLarge: GoogleFonts.urbanist(
      fontSize: 18.0,
      color: textColor,
      fontWeight: FontWeight.bold,
    ),
    bodyLarge: GoogleFonts.urbanist(
      fontSize: 16.0,
      color: textColor,
      fontWeight: FontWeight.w600,
    ),
    bodyMedium: GoogleFonts.urbanist(
      fontSize: 14.0,
      color: textColor,
      fontWeight: FontWeight.w600,
    ),
    bodySmall: GoogleFonts.urbanist(
      fontSize: 12.0,
      color: textColor,
      fontWeight: FontWeight.w600,
    ),
  );
}
