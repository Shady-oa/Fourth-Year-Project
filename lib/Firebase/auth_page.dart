import 'package:final_project/Screens/login.dart';
import 'package:final_project/Screens/signup_page.dart';
import 'package:flutter/material.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  //show ligin page
  bool showLoginPage = true;

  void toggleScreens() {
    setState(() {
      showLoginPage = !showLoginPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (showLoginPage) {
      return Login(showSignupPage: toggleScreens);
    } else {
      return SignUp(showLoginpage: toggleScreens);
    }
  }
}
