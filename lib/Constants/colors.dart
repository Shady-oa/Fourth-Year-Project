import 'package:final_project/Constants/typograpy.dart';
import 'package:flutter/material.dart';

// --- Color Definitions ---
const Color brandGreen = Color(0xFF00D09E);
const Color lightBg = Color(0xFFFFFFFF);
const Color darkBg = Color(0xFF000000);
const Color textLightMode = Color(0xFF000000);
const Color textDarkMode = Color(0xFFFFFFFF);
const Color accentColor = Color(0xFF2196F3);
const Color errorColor = Color(0xFFFF4C4C);
const Color warning = Color(0xFFFFA500);

// --- Text Style Generator Function ---
// This function creates a base text style for a given color.
// We'll use this inside the ThemeData to set the color correctly.

// --- Light Mode Theme Data ---
ThemeData lightMode = ThemeData(
  scaffoldBackgroundColor: lightBg,
  colorScheme: ColorScheme.light(
    brightness: Brightness.light,
    surface: lightBg,
    primary: brandGreen, // Primary button color, etc.
    onSurface:
        textLightMode, // This is the color for text/icons on the surface (background)
  ),
  // Assign the TextTheme with the light mode text color
  textTheme: createTextTheme(textLightMode),
);

// --- Dark Mode Theme Data ---
ThemeData darkMode = ThemeData(
  // I replaced your fixed dark color with your defined darkBg
  scaffoldBackgroundColor: darkBg,
  colorScheme: ColorScheme.dark(
    brightness: Brightness.dark,
    surface: darkBg,
    primary: brandGreen, // Primary button color, etc.
    onSurface:
        textDarkMode, // This is the color for text/icons on the surface (background)
  ),
  // Assign the TextTheme with the dark mode text color
  textTheme: createTextTheme(textDarkMode),
);

// --- Theme Provider Class ---
class ThemeProvider with ChangeNotifier {
  ThemeData _currentTheme = lightMode;

  ThemeData get currentTheme => _currentTheme;

  void toggleTheme() {
    if (_currentTheme == lightMode) {
      _currentTheme = darkMode;
    } else {
      _currentTheme = lightMode;
    }
    notifyListeners();
  }
}
