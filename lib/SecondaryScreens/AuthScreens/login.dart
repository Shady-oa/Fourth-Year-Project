import 'package:final_project/Components/bottom_nav.dart';
import 'package:final_project/Components/form_logo.dart';
import 'package:final_project/Components/toast.dart';
import 'package:final_project/Constants/spacing.dart';
import 'package:final_project/Firebase/auth_services.dart';
import 'package:final_project/SecondaryScreens/AuthScreens/social_login_button.dart';
import 'package:flutter/material.dart';

class Login extends StatefulWidget {
  final VoidCallback showSignupPage;

  const Login({super.key, required this.showSignupPage});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  

  // ── Google sign-in handler ─────────────────────────────────────────────────
  Future<void> _handleGoogleSignIn() async {
    try {
      await AuthService().signInWithGoogle();
      if (!context.mounted) return;

      AppToast.success(context, 'Google Sign in successfully!');

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const BottomNav()),
      );
    } on NoGoogleAccountChoosenException {
      return;
    } catch (e) {
      if (!context.mounted) return;
      AppToast.error(context, 'Unexpected error occurred,try again!');
    }
  }

  // ── Facebook sign-in handler ───────────────────────────────────────────────
  Future<void> _handleFacebookSignIn() async {
    try {
      // Call the Facebook function
      final userCredential = await AuthService().signInWithFacebook();

      // If userCredential is null, it means the user cancelled the login
      if (userCredential == null) return;

      if (!context.mounted) return;

      // Success! Navigate to Home
      AppToast.success(context, 'Facebook Sign in successfully!');

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const BottomNav()),
      );
    } catch (e) {
      if (!context.mounted) return;

      // Show error toast
      AppToast.error(context, 'Facebook Sign in failed. Please try again!');
      print("Facebook Error✅✅✅: $e"); // Helpful for debugging the Key Hash!
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              formLogo,

              sizedBoxHeightXLarge,
              Text(
                "Access Your Account. ",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              sizedBoxHeightLarge,

              // ── Google sign-in button ──────────────────────────────────────
              SocialLoginButton(
                assetPath: 'assets/image/google.png',
                label: 'Continue with Google',
                onTap: _handleGoogleSignIn,
                imageSpacer: sizedBoxWidthSmall,
              ),

              sizedBoxHeightLarge,

              // ── Facebook sign-in button ────────────────────────────────────
              SocialLoginButton(
                assetPath: 'assets/image/facebook.png',
                label: 'Continue with Facebook',
                onTap: _handleFacebookSignIn,
                imageWidth: 32,
                imageHeight: 32,
                imageSpacer: sizedBoxWidthMedium,
              ),

              const SizedBox(height: 140),
            ],
          ),
        ),
      ),
    );
  }
}
