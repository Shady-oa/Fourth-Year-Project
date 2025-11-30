import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

//- - - - - - - - - - - - - - - - - - - - COLORS - - - - - - - - - - - - - - - - - - - -

const Color brandGreen = Color(
  0xFF00D09E,
); // App brand color, Buttons, Active Nav
const Color primaryBg = Color(0xFFF1FFF3); // Primary background
const Color primaryText = Color(0xFF052224); // Primary text
const Color accentColor = Color(0xFF0068FF); // Accent color, Highlights
const Color errorColor = Color(0xFFFF4C4C); // Error messages,

//- - - - - - - - - - - - - - - - - - - - TEXT STYLES - - - - - - - - - - - - - - - - - - - -

TextTheme kTextTheme = TextTheme(
  displayLarge: GoogleFonts.urbanist(
    fontSize: 40.0,
    color: primaryText,
    fontWeight: FontWeight.bold,
  ),
  displayMedium: GoogleFonts.urbanist(
    fontSize: 32.0,
    color: primaryText,
    fontWeight: FontWeight.bold,
  ),
  displaySmall: GoogleFonts.urbanist(
    fontSize: 28.0,
    color: primaryText,
    fontWeight: FontWeight.bold,
  ),
  headlineMedium: GoogleFonts.urbanist(
    fontSize: 24.0,
    color: primaryText,
    fontWeight: FontWeight.bold,
  ),
  headlineSmall: GoogleFonts.urbanist(
    fontSize: 20.0,
    color: primaryText,
    fontWeight: FontWeight.bold,
  ),
  titleLarge: GoogleFonts.urbanist(
    fontSize: 18.0,
    color: primaryText,
    fontWeight: FontWeight.bold,
  ),
  bodyLarge: GoogleFonts.urbanist(
    fontSize: 16.0,
    color: primaryText,
    fontWeight: FontWeight.w600,
  ),
  bodyMedium: GoogleFonts.urbanist(
    fontSize: 14.0,
    color: primaryText,
    fontWeight: FontWeight.w600,
  ),
  bodySmall: GoogleFonts.urbanist(
    fontSize: 12.0,
    color: primaryText,
    fontWeight: FontWeight.w600,
  ),
);

//- - - - - - - - - - - - - - - - - - - - SPACING - - - - - - - - - - - - - - - - - - - -

const double spacerTiny = 4.0;
const double spacerSmall = 8.0;
const double spacerMedium = 16.0;
const double spacerLarge = 24.0;
const double spacerXLarge = 32.0;

const EdgeInsets paddingAllTiny = EdgeInsets.all(spacerTiny);
const EdgeInsets paddingAllSmall = EdgeInsets.all(spacerSmall);
const EdgeInsets paddingAllMedium = EdgeInsets.all(spacerMedium);
const EdgeInsets paddingAllLarge = EdgeInsets.all(spacerLarge);

//- - - - - - - - - - - - - - - - - - - - BORDER RADIUS - - - - - - - - - - - - - - - - - - - -

const BorderRadius radiusSmall = BorderRadius.all(Radius.circular(8.0));
const BorderRadius radiusMedium = BorderRadius.all(Radius.circular(12.0));
const BorderRadius radiusLarge = BorderRadius.all(Radius.circular(24.0));
