import 'package:final_project/Components/back_button.dart';
import 'package:final_project/Components/bottom_nav.dart';
import 'package:final_project/Components/form_logo.dart';
import 'package:final_project/Components/toast.dart';
import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/spacing.dart';
import 'package:final_project/Firebase/auth_services.dart';
import 'package:firebase_auth/firebase_auth.dart';
//import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> passwordReset({required String email}) async {
    try {
      // 1. Core Firebase Action: Sends the email using your configured Firebase project
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      showCustomToast(
        context: context,
        message: ' Reset link has been sent. Check your inbox.',
        backgroundColor: accentColor,
        icon: Icons.check_circle_outline_rounded,
      );

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      // 3. Handle Firebase Errors

      if (e.code == 'user-not-found') {
        showCustomToast(
          context: context,
          message: 'Account not found. Please create an account',
          backgroundColor: errorColor,
          icon: Icons.error_outline_rounded,
        );

        Navigator.pop(context);
      } else if (e.code == 'invalid-email') {
        showCustomToast(
          context: context,
          message: 'invalid-email',
          backgroundColor: errorColor,
          icon: Icons.error_outline_rounded,
        );
      } else {
        showCustomToast(
          context: context,
          message: 'An error occurred. Please try again.',
          backgroundColor: errorColor,
          icon: Icons.error_outline_rounded,
        );
        //clientMessage = 'An error occurred. Please try again.';
        print(
          "Firebase Error Code: ${e.code}",
        ); // Log the code for developer debugging
      }
    } catch (e) {
      // General network/unknown error
      showCustomToast(
        context: context,
        message:
            'A network error occurred. Check your connection and try again.',
        backgroundColor: errorColor,
        icon: Icons.wifi_off_rounded,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: brandGreen,

        body: Column(
          children: [
            Row(
              children: [
                CustomBackButton(),
                sizedBoxHeightLarge,
                Container(
                  alignment: Alignment.center,
                  height: 100,
                  child: Text(
                    "Forgot Password",
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
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
                          border: OutlineInputBorder(
                            borderRadius: radiusMedium,
                          ),
                          fillColor: Theme.of(
                            context,
                          ).colorScheme.surface.withOpacity(0.8),
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
                              await passwordReset(
                                email: _emailController.text.trim(),
                              );
                            } else {
                              showCustomToast(
                                context: context,
                                message: 'Enter email address',
                                backgroundColor: errorColor,
                                icon: Icons.error_outline_rounded,
                              );
                            }
                          },
                          child: Text(
                            'Send Reset Link',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
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
                            showCustomToast(
                              context: context,
                              message: "Unexpected error occurred,try again!",
                              backgroundColor: errorColor,
                              icon: Icons.error_outline_rounded,
                            );
                          }
                          showCustomToast(
                            context: context,
                            message: "Logged in successfully! ",
                            backgroundColor: accentColor,
                            icon: Icons.check_circle_outline_rounded,
                          );
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
                            border: Border.all(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
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
      ),
    );
  }
}
