import 'package:final_project/auth_page.dart';
import 'package:final_project/balance.dart';
import 'package:final_project/bottomnav.dart';
import 'package:final_project/forgot_pwd_page.dart';
import 'package:final_project/hme.dart';
import 'package:final_project/home.dart';
import 'package:final_project/income.dart';
import 'package:final_project/login.dart';
import 'package:final_project/main_page.dart';
import 'package:final_project/single_budget.dart';
import 'package:final_project/single_saving.dart';
import 'package:final_project/splash.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  // Initialize Firebase
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // Run your app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  bool name() {
    return true;
  }

  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(), //MainPage(), //main page
      routes: {
        '/homepage': (context) => HomePage(),
        '/forgotpassword': (context) => ForgotPasswordPage(),
        '/auth': (context) => AuthPage(), //yhy
        '/home': (context) => Home(),
        '/singlebudget': (context) => SingleBudget(),
        '/singlesaving': (context) => SingleSaving(),
        '/balance': (context) => BalancePage(),
        '/login': (context) => Login(showSignupPage: () => true),
        '/navigation': (context) => BottomNavigation(),
        '/mainpage': (context) => MainPage(),
        '/income': (context) => Income(),
      },
    );
  }
}
