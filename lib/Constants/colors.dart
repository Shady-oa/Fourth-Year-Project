import 'package:final_project/Constants/typograpy.dart';
import 'package:flutter/material.dart';
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

// --- Light Mode Theme Data ---
ThemeData lightMode = ThemeData(
  scaffoldBackgroundColor: lightBg,
  colorScheme: ColorScheme.light(
    brightness: Brightness.light,
    surface: lightBg,
    primary: brandGreen,
    onSurface: textLightMode,
  ),
  textTheme: createTextTheme(textLightMode),
);

// --- Dark Mode Theme Data ---
ThemeData darkMode = ThemeData(
  scaffoldBackgroundColor: darkBg,
  colorScheme: ColorScheme.dark(
    brightness: Brightness.dark,
    surface: darkBg,
    primary: brandGreen,
    onSurface: textDarkMode,
  ),
  textTheme: createTextTheme(textDarkMode),
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
