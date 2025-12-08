import 'package:final_project/Constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ThemeToggleIcon extends StatelessWidget {
  const ThemeToggleIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.currentTheme == darkMode;

    return IconButton(
      icon: Icon(
        isDarkMode ?  Icons.light_mode_rounded: Icons.dark_mode_rounded,
        size: 30,
        color: Theme.of(context).iconTheme.color,
      ),
      onPressed: () {
        themeProvider.toggleTheme();
      },
      tooltip: isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
    );
  }
}
