// ignore_for_file: prefer_const_constructors

import 'dart:convert';

import 'package:final_project/Components/bottom_nav.dart';
import 'package:final_project/Components/form_logo.dart';
import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/spacing.dart';
import 'package:final_project/Constants/typograpy.dart';
import 'package:final_project/Firebase/auth_services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:toasty_box/toast_enums.dart';
import 'package:toasty_box/toast_service.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final _emailController = TextEditingController();
  final String baseUrl = 'http://10.0.2.2:8080';

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<String> passwordReset({required String email}) async {
    final url = Uri.parse('$baseUrl/reset-password');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['status'] ?? 'email sent';
      } else {
        final body = jsonDecode(response.body);
        return body['status'] ?? 'error';
      }
    } catch (e) {
      return e.toString();
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
              sizedBoxHeightLarge,
              Container(
                alignment: Alignment.center,
                height: 100,
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
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    formLogo,

                    sizedBoxHeightLarge,
                    Text(
                      'Reset Your Password?',
                      style: kTextTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    sizedBoxHeightSmall,
                    Text(
                      'Enter your email to receive a password reset link.',
                      style: kTextTheme.bodyLarge,
                      textAlign: TextAlign.left,
                    ),
                    sizedBoxHeightSmall,
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        hintText: 'Email',
                        border: OutlineInputBorder(borderRadius: radiusMedium),
                        fillColor: primaryBg.withOpacity(0.8),
                        filled: true,
                      ),
                    ),

                    sizedBoxHeightLarge,
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
                        onPressed: () async {
                          if (_emailController.text.isNotEmpty) {
                            String result = await passwordReset(
                              email: _emailController.text.trim(),
                            );
                            if (result == 'success') {
                              ToastService.showToast(
                                context,
                                backgroundColor: accentColor,
                                dismissDirection: DismissDirection.endToStart,
                                expandedHeight: 80,
                                isClosable: true,
                                leading: const Icon(Icons.error_outline),
                                message:
                                    'Please enter both email and password!',
                                length: ToastLength.medium,
                                positionCurve: Curves.bounceInOut,
                                messageStyle: kTextTheme.bodyLarge?.copyWith(
                                  color: primaryBg,
                                ),
                                slideCurve: Curves.easeInOut,
                                shadowColor: primaryText.withOpacity(0.5),
                              );
                            }
                            if (result == 'error') {
                              ToastService.showToast(
                                context,
                                backgroundColor: errorColor,
                                dismissDirection: DismissDirection.endToStart,
                                expandedHeight: 80,
                                isClosable: true,
                                leading: const Icon(Icons.error_outline),
                                message: 'An error occured please try again',
                                length: ToastLength.medium,
                                positionCurve: Curves.bounceInOut,
                                messageStyle: kTextTheme.bodyLarge?.copyWith(
                                  color: primaryBg,
                                ),
                                slideCurve: Curves.easeInOut,
                                shadowColor: primaryText.withOpacity(0.5),
                              );
                            } else {
                              ToastService.showToast(
                                context,
                                backgroundColor: errorColor,
                                dismissDirection: DismissDirection.endToStart,
                                expandedHeight: 80,
                                isClosable: true,
                                leading: const Icon(Icons.error_outline),
                                message: result,
                                length: ToastLength.medium,
                                positionCurve: Curves.bounceInOut,
                                messageStyle: kTextTheme.bodyLarge?.copyWith(
                                  color: primaryBg,
                                ),
                                slideCurve: Curves.easeInOut,
                                shadowColor: primaryText.withOpacity(0.5),
                              );
                              print('this is the reset password error');
                              print(result);
                            }
                          } else {
                            ToastService.showToast(
                              context,
                              backgroundColor: errorColor,
                              dismissDirection: DismissDirection.endToStart,
                              expandedHeight: 80,
                              isClosable: true,
                              leading: const Icon(Icons.error_outline),
                              message: 'Please enter both email and password!',
                              length: ToastLength.medium,
                              positionCurve: Curves.bounceInOut,
                              messageStyle: kTextTheme.bodyLarge?.copyWith(
                                color: primaryBg,
                              ),
                              slideCurve: Curves.easeInOut,
                              shadowColor: primaryText.withOpacity(0.5),
                            );
                          }
                        },
                        child: Text(
                          'Send Reset Link',
                          style: kTextTheme.titleLarge?.copyWith(
                            color: primaryText,
                          ),
                        ),
                      ),
                    ),
                    sizedBoxHeightLarge,
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
                            builder: (context) => const BottomNav(),
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
                            sizedBoxWidthSmall,
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
          ),
        ],
      ),
    );
  }
}
