import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/typograpy.dart';
import 'package:final_project/Firebase/auth_page.dart';
import 'package:final_project/balance.dart';
import 'package:final_project/Screens/forgot_pwd_page.dart';
import 'package:final_project/Screens/home.dart';
import 'package:final_project/income.dart';
import 'package:final_project/Screens/login.dart';
import 'package:final_project/main_page.dart';
import 'package:final_project/single_budget.dart';
import 'package:final_project/single_saving.dart';
import 'package:final_project/Screens/splash.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  // Initialize Firebase
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // Run your app
  runApp(const MyApp());
}

//
class MyApp extends StatelessWidget {
  bool name() {
    return true;
  }

  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: primaryBg,
        textTheme: kTextTheme,
      ),
      home: SplashScreen(), //MainPage(), //main page
      routes: {
        '/homepage': (context) => HomePage(), //init
        '/forgotpassword': (context) => ForgotPasswordPage(),
        '/auth': (context) => AuthPage(), //yhy
        '/singlebudget': (context) => SingleBudget(),
        '/singlesaving': (context) => SingleSaving(),
        '/balance': (context) => BalancePage(),
        '/login': (context) => Login(showSignupPage: () => true),
        '/mainpage': (context) => MainPage(),
        '/income': (context) => Income(),
      },
    );
  }
}
