// ignore_for_file: prefer_const_constructors

import 'dart:convert';

import 'package:final_project/Components/bottom_nav.dart';
import 'package:final_project/Components/form_logo.dart';
import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/spacing.dart';
import 'package:final_project/Firebase/auth_services.dart';
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
  final String baseUrl = 'https://fourth-year-backend.onrender.com';

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
                icon: Icon(Icons.arrow_back_ios_sharp, color: Theme.of(context).colorScheme.onSurface),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              sizedBoxHeightLarge,
              Container(
                alignment: Alignment.center,
                height: 100,
                child: Text("Forgot Password", style: Theme.of(context).textTheme.displaySmall),
              ),
            ],
          ),
          Expanded(
            child: Container(
              padding: paddingAllMedium,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
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
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    sizedBoxHeightSmall,
                    Text(
                      'Enter your email to receive a password reset link.',
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.left,
                    ),
                    sizedBoxHeightSmall,
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        hintText: 'Email',
                        border: OutlineInputBorder(borderRadius: radiusMedium),
                        fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.8),
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
                                messageStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.surface,
                                ),
                                slideCurve: Curves.easeInOut,
                                shadowColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
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
                                messageStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.surface,
                                ),
                                slideCurve: Curves.easeInOut,
                                shadowColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
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
                                messageStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.surface,
                                ),
                                slideCurve: Curves.easeInOut,
                                shadowColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
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
                              messageStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).colorScheme.surface,
                              ),
                              slideCurve: Curves.easeInOut,
                              shadowColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                            );
                          }
                        },
                        child: Text(
                          'Send Reset Link',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
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
                                  style: Theme.of(context).textTheme.bodyMedium,
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
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: radiusMedium,
                          border: Border.all(color: Theme.of(context).colorScheme.onSurface),
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
                              style: Theme.of(context).textTheme.bodyLarge,
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
