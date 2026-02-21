import 'package:final_project/Components/bottom_nav.dart';
import 'package:final_project/Components/form_logo.dart';
import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/spacing.dart';
import 'package:final_project/Firebase/auth_services.dart';
import 'package:final_project/SecondaryScreens/AuthScreens/social_login_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:toasty_box/toast_enums.dart';
import 'package:toasty_box/toast_service.dart';

class Login extends StatefulWidget {
  final VoidCallback showSignupPage;

  const Login({super.key, required this.showSignupPage});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _emailcontroller = TextEditingController();
  final _passwordcontroller = TextEditingController();

  @override
  void dispose() {
    _emailcontroller.dispose();
    _passwordcontroller.dispose();
    super.dispose();
  }

  Future signin() async {
    if (_emailcontroller.text.isEmpty || _passwordcontroller.text.isEmpty) {
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
        shadowColor: Theme.of(
          context,
        ).colorScheme.onSurface.withAlpha((255 * 0.5).round()),
      );
      return;
    }
    //confirm
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailcontroller.text.trim(),
        password: _passwordcontroller.text.trim(),
      );
      if (!context.mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const BottomNav()),
      );
    } catch (e) {
      if (!context.mounted) return;
      ToastService.showToast(
        context,
        backgroundColor: errorColor,
        dismissDirection: DismissDirection.endToStart,
        expandedHeight: 80,
        isClosable: true,
        leading: const Icon(Icons.error_outline),
        message: 'Wrong email or password!',
        length: ToastLength.medium,
        positionCurve: Curves.bounceInOut,
        messageStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Theme.of(context).colorScheme.surface,
        ),
        slideCurve: Curves.easeInOut,
        shadowColor: Theme.of(
          context,
        ).colorScheme.onSurface.withAlpha((255 * 0.5).round()),
      );

      _emailcontroller.clear();
      _passwordcontroller.clear();
    }
  }

  // ── Google sign-in handler ─────────────────────────────────────────────────
  Future<void> _handleGoogleSignIn() async {
    try {
      await AuthService().signInWithGoogle();
      if (!context.mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const BottomNav()),
      );
    } on NoGoogleAccountChoosenException {
      return;
    } catch (e) {
      if (!context.mounted) return;
      ToastService.showToast(
        context,
        backgroundColor: errorColor,
        dismissDirection: DismissDirection.endToStart,
        expandedHeight: 80,
        isClosable: true,
        leading: const Icon(Icons.error_outline),
        message: 'Unexpected error occurred,try again!',
        length: ToastLength.medium,
        positionCurve: Curves.bounceInOut,
        messageStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Theme.of(context).colorScheme.surface,
        ),
        slideCurve: Curves.easeInOut,
        shadowColor: Theme.of(
          context,
        ).colorScheme.onSurface.withAlpha((255 * 0.5).round()),
      );
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
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const BottomNav()),
      );
    } catch (e) {
      if (!context.mounted) return;

      // Show error toast
      ToastService.showToast(
        context,
        backgroundColor: errorColor,
        message: 'Facebook Login failed. Please try again!',
        leading: const Icon(Icons.error_outline),
        // ... include your other styling here ...
      );
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
