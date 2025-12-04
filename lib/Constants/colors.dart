import 'package:flutter/material.dart';

const Color brandGreen = Color(
  0xFF00D09E,
); // App brand color, Buttons, Active Nav
const Color primaryBg = Color(0xFFF1FFF3); // Primary background

const Color primaryText = Color(0xFF052224); // Primary text
const Color accentColor = Color(0xFF2196F3); // Accent color, Highlights
const Color errorColor = Color(0xFFFF4C4C);
 // Error messages,
 // Within a StatelessWidget or StatefulWidget's build method:



ThemeData lightMode = ThemeData(
  scaffoldBackgroundColor: primaryBg,
  colorScheme: ColorScheme.light(
    brightness: Brightness.light,
    surface: primaryBg,
    primary: primaryText
  )
);


ThemeData darkMode = ThemeData(
  scaffoldBackgroundColor: Color(0xFF121212),
  colorScheme: ColorScheme.dark(
    brightness: Brightness.dark,
    surface: primaryText,
    primary: primaryBg
    
  ),
);

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