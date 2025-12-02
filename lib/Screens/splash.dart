import 'dart:async';

import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/spacing.dart';
import 'package:final_project/Constants/typograpy.dart';
import 'package:final_project/main_page.dart';
// import 'package:firebase/main_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: brandGreen, // Splash screen background color
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/svg/penny.svg',
              height: 120,
              width: 120,
              colorFilter: const ColorFilter.mode(primaryText, BlendMode.srcIn),
            ),
            const SizedBox(height: 2),
            Text(
              'Penny Wise',
              style: kTextTheme.displayMedium?.copyWith(color: primaryText),
            ),
            const SizedBox(height: 2),

            Text(
              "Wise Choices For Financial Freedom",
              style: kTextTheme.titleMedium?.copyWith(color: primaryText),
            ),
          ],
        ),
      ),
    );
  }
}
