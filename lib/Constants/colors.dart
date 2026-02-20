import 'package:final_project/Constants/typograpy.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- Color Definitions ---
const Color brandGreen = Color(0xFF00D09E);
const Color lightBg = Color(0xFFFFFFFF);
const Color darkBg = Color(0xFF000000);
const Color textLightMode = Color(0xFF000000);
const Color textDarkMode = Color(0xFFFFFFFF);
const Color accentColor = Color(0xFF2196F3);
const Color errorColor = Color(0xFFFF4C4C);
const Color warning = Color(0xFFFFA500);

// --- Input Decoration Theme Helper ---
InputDecorationTheme _inputTheme(Color surface, Color onSurface) {
  return InputDecorationTheme(
    filled: true,
    fillColor: onSurface.withOpacity(0.05),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: onSurface.withOpacity(0.15)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: onSurface.withOpacity(0.15)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: brandGreen, width: 1.8),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: errorColor),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: errorColor, width: 1.8),
    ),
    labelStyle: GoogleFonts.urbanist(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: onSurface.withOpacity(0.6),
    ),
    hintStyle: GoogleFonts.urbanist(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: onSurface.withOpacity(0.4),
    ),
    floatingLabelStyle: GoogleFonts.urbanist(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: brandGreen,
    ),
  );
}

// --- Light Mode Theme Data ---
ThemeData lightMode = ThemeData(
  scaffoldBackgroundColor: lightBg,
  colorScheme: ColorScheme.light(
    brightness: Brightness.light,
    surface: lightBg,
    primary: brandGreen,
    onSurface: textLightMode,
    surfaceContainerHighest: const Color(0xFFF3F4F6),
  ),
  textTheme: createTextTheme(textLightMode),
  inputDecorationTheme: _inputTheme(lightBg, textLightMode),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: brandGreen,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: GoogleFonts.urbanist(
        fontSize: 15,
        fontWeight: FontWeight.bold,
      ),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: textLightMode,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: BorderSide(color: textLightMode.withOpacity(0.2)),
      textStyle: GoogleFonts.urbanist(
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    color: lightBg,
    shadowColor: Colors.black.withOpacity(0.06),
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: lightBg,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    dragHandleColor: Color(0xFFCCCCCC),
    dragHandleSize: Size(40, 4),
  ),
);

// --- Dark Mode Theme Data ---
ThemeData darkMode = ThemeData(
  scaffoldBackgroundColor: darkBg,
  colorScheme: ColorScheme.dark(
    brightness: Brightness.dark,
    surface: darkBg,
    primary: brandGreen,
    onSurface: textDarkMode,
    surfaceContainerHighest: const Color(0xFF1C1C1E),
  ),
  textTheme: createTextTheme(textDarkMode),
  inputDecorationTheme: _inputTheme(darkBg, textDarkMode),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: brandGreen,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: GoogleFonts.urbanist(
        fontSize: 15,
        fontWeight: FontWeight.bold,
      ),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: textDarkMode,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: BorderSide(color: textDarkMode.withOpacity(0.2)),
      textStyle: GoogleFonts.urbanist(
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    color: const Color(0xFF111111),
    shadowColor: Colors.black.withOpacity(0.2),
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: Color(0xFF111111),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    dragHandleColor: Color(0xFF444444),
    dragHandleSize: Size(40, 4),
  ),
);

// --- Theme Provider Class ---
class ThemeProvider with ChangeNotifier {
  ThemeData _currentTheme = lightMode;
  static const String _themeKey = "is_dark_mode";

  ThemeData get currentTheme => _currentTheme;

  // Constructor: Automatically loads the preference on startup
  ThemeProvider() {
    _loadTheme();
  }

  // Toggle theme and persist the choice
  Future<void> toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();

    if (_currentTheme == lightMode) {
      _currentTheme = darkMode;
      await prefs.setBool(_themeKey, true);
    } else {
      _currentTheme = lightMode;
      await prefs.setBool(_themeKey, false);
    }
    notifyListeners();
  }

  // Fetch the saved preference from local storage
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = prefs.getBool(_themeKey) ?? false; // Defaults to light

    _currentTheme = isDarkMode ? darkMode : lightMode;
    notifyListeners();
  }
}
