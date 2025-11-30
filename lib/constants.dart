import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

//- - - - - - - - - - - - - - - - - - - - COLORS - - - - - - - - - - - - - - - - - - - -

const Color brandGreen = Color(0xFF00D09E); // App brand color, Buttons, Active Nav
const Color primaryBg = Color(0xFFF1FFF3); // Primary background
const Color primaryText = Color(0xFF052224); // Primary text

//- - - - - - - - - - - - - - - - - - - - TEXT STYLES - - - - - - - - - - - - - - - - - - - -

TextTheme kTextTheme = TextTheme(
  displayLarge: GoogleFonts.urbanist(
      fontSize: 40.0, color: primaryText, fontWeight: FontWeight.bold),
  displayMedium: GoogleFonts.urbanist(
      fontSize: 32.0, color: primaryText, fontWeight: FontWeight.bold),
  displaySmall: GoogleFonts.urbanist(
      fontSize: 28.0, color: primaryText, fontWeight: FontWeight.bold),
  headlineMedium: GoogleFonts.urbanist(
      fontSize: 24.0, color: primaryText, fontWeight: FontWeight.bold),
  headlineSmall: GoogleFonts.urbanist(
      fontSize: 20.0, color: primaryText, fontWeight: FontWeight.bold),
  titleLarge: GoogleFonts.urbanist(
      fontSize: 18.0, color: primaryText, fontWeight: FontWeight.bold),
  bodyLarge: GoogleFonts.inter(fontSize: 16.0, color: primaryText),
  bodyMedium: GoogleFonts.inter(fontSize: 14.0, color: primaryText),
  bodySmall: GoogleFonts.inter(fontSize: 12.0, color: primaryText),
);

//- - - - - - - - - - - - - - - - - - - - FONT SIZES - - - - - - - - - - - - - - - - - - - -

const double hugeText = 40.0;
const double headerText = 32.0;
const double largeText = 24.0;
const double mediumText = 20.0;
const double normalText = 18.0;
const double bodyText = 16.0;
const double smallText = 14.0;
const double tinyText = 12.0;
