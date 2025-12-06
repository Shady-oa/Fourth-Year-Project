import 'dart:async';

import 'package:final_project/Components/bottom_nav.dart';
import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Firebase/main_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase/main_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  void checkAuthAndNavigate() {
    // FirebaseAuth.instance.currentUser returns the currently signed-in User
    // or null if none is signed in. This is synchronous after initialization.
    final user = FirebaseAuth.instance.currentUser;

    // Use a small delay for the splash screen duration
    Timer(const Duration(seconds: 3), () {
      // Determine the destination based on the user's state
      Widget destination;
      if (user != null) {
        // User is logged in (persistent session found)
        destination =
            const BottomNav(); 
      } else {
        // User is NOT logged in (no persistent session or logged out)
        destination =
            const MainPage(); 
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => destination),
      );
    });
  }

  @override
  void initState() {
    super.initState();

    checkAuthAndNavigate();
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
              colorFilter: ColorFilter.mode(
                Theme.of(context).colorScheme.onSurface,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Penny Wise',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),

            Text(
              "Wise Choices For Financial Freedom",
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
