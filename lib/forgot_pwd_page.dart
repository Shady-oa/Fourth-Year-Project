// ignore_for_file: prefer_const_constructors

import 'package:final_project/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future passwordReset() async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: primaryBg,
            content: Text('Password reset email sent. Check your email.',
                style: kTextTheme.bodyMedium),
          );
        },
      );
    } on FirebaseAuthException catch (e) {
      print(e);
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: primaryBg,
            content: Text(e.message.toString(), style: kTextTheme.bodyMedium),
          );
        },
      );
    } catch (e) {
      print(e);
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: primaryBg,
            content: Text('An error occurred. Please try again later.',
                style: kTextTheme.bodyMedium),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBg,
      appBar: AppBar(
        backgroundColor: primaryText,
        title: Text('Forgot Password', style: kTextTheme.headlineSmall?.copyWith(color: primaryBg)),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Enter your email to receive a password reset link.',
            style: kTextTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          SizedBox(
            height: 20,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: TextField(
              controller: _emailController,
              decoration: InputDecoration(
                hintText: 'Email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                fillColor: primaryBg.withOpacity(0.8),
                filled: true,
              ),
            ),
          ),
          SizedBox(
            height: 20,
          ),
          TextButton(
            onPressed: passwordReset,
            style: TextButton.styleFrom(
              backgroundColor: brandGreen, // Background color
              padding:
                  EdgeInsets.symmetric(horizontal: 30, vertical: 15), // Padding
            ),
            child: Text(
              'Reset',
              style: kTextTheme.bodyLarge?.copyWith(color: primaryText),
            ),
          )
        ],
      ),
    );
  }
}
