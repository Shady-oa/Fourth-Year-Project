// ignore_for_file: prefer_const_constructors

import 'package:final_project/auth_page.dart';
// import 'package:firebase/auth_page.dart';
//import 'package:firebase/login.dart';
import 'package:firebase_auth/firebase_auth.dart';
//import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return AuthPage();
          } else {
            return AuthPage();
          }
        },
      ),
    );
  }
}
