// ignore_for_file: prefer_const_constructors

import 'package:final_project/auth_services.dart';
import 'package:final_project/constants.dart';
import 'package:final_project/start.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

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
            backgroundColor: accentColor,
            content: Text(
              'Password reset email sent. Check your email.',
              style: kTextTheme.bodyMedium,
            ),
          );
        },
      );
    } on FirebaseAuthException catch (e) {
      print(e);
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: errorColor,
            content: Text(
              'Enter a valid email address.',
              style: kTextTheme.bodyMedium,
            ),
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
            content: Text(
              'An error occurred. Please try again later.',
              style: kTextTheme.bodyMedium,
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: brandGreen,

      body: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back_ios_sharp, color: primaryText),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              SizedBox(width: 20),
              Container(
                alignment: Alignment.center,
                height: 150,
                child: Text("Forgot Password", style: kTextTheme.displaySmall),
              ),
            ],
          ),
          Expanded(
            child: Container(
              padding: paddingAllMedium,
              decoration: const BoxDecoration(
                color: primaryBg,
                borderRadius: topOnly,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        SvgPicture.asset(
                          'assets/svg/penny.svg',
                          height: 120,
                          width: 120,
                          colorFilter: ColorFilter.mode(
                            brandGreen,
                            BlendMode.srcIn,
                          ),
                        ),
                        Text('Penny Wise', style: kTextTheme.displayMedium),
                        SizedBox(height: 2),
                        Text(
                          "Wise Choices For Financial Freedom",
                          style: kTextTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 35),
                  Text(
                    'Reset Your Password?',
                    style: kTextTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Enter your email to receive a password reset link.',
                    style: kTextTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      hintText: 'Email',
                      border: OutlineInputBorder(borderRadius: radiusMedium),
                      fillColor: primaryBg.withOpacity(0.8),
                      filled: true,
                    ),
                  ),

                  SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: radiusMedium,
                        ),
                      ),
                      onPressed: passwordReset,
                      child: Text(
                        'Send Reset Link',
                        style: kTextTheme.titleLarge?.copyWith(
                          color: primaryText,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  GestureDetector(
                    onTap: () async {
                      try {
                        await AuthService().signInWithGoogle();
                      } on NoGoogleAccountChoosenException {
                        return;
                      } catch (e) {
                        if (!context.mounted) return;
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              backgroundColor: errorColor,
                              content: Text(
                                'Unknown error occurred',
                                style: kTextTheme.bodyMedium,
                              ),
                            );
                          },
                        );
                      }

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MainLoader(),
                        ),
                      );
                    },
                    child: Container(
                      height: 50,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: primaryBg,
                        borderRadius: radiusMedium,
                        border: Border.all(color: primaryText),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Image(
                            image: AssetImage('assets/image/google.png'),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Or Sign in with Google',
                            style: kTextTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
