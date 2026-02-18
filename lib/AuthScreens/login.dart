import 'package:final_project/AuthScreens/forgot_pwd_page.dart';
import 'package:final_project/Components/bottom_nav.dart';
import 'package:final_project/Components/form_logo.dart';
import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/spacing.dart';
import 'package:final_project/Firebase/auth_services.dart';
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
            Container(
              alignment: Alignment.center,
              height: 100,
              child: Text(
                "Welcome",
                style: Theme.of(context).textTheme.displaySmall,
              ),
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
                    children: [
                      formLogo,
                      /*
                      TextField(
                        controller: _emailcontroller,
                        decoration: InputDecoration(
                          hintText: 'Email',
                          border: const OutlineInputBorder(
                            borderRadius: radiusMedium,
                          ),
                          fillColor: Theme.of(context).colorScheme.onSurface
                              .withAlpha((255 * 0.1).round()),
                          filled: true,
                        ),
                      ),

                      sizedBoxHeightSmall,

                      // PASSWORD FIELD
                      TextField(
                        controller: _passwordcontroller,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: 'Password',
                          border: const OutlineInputBorder(
                            borderRadius: radiusMedium,
                          ),
                          fillColor: Theme.of(context).colorScheme.onSurface
                              .withAlpha((255 * 0.1).round()),
                          filled: true,
                        ),
                      ),

                      sizedBoxHeightTiny,

                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const ForgotPassword(),
                              ),
                            );
                          },
                          child: Text(
                            'Forgot password?',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: accentColor),
                          ),
                        ),
                      ),*/
                      /*
                      sizedBoxHeightXLarge,

                      // SIGN IN BUTTON
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
                            await signin();
                          },
                          child: Text(
                            'Sign in',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                          ),
                        ),
                      ),
*/
                      sizedBoxHeightLarge,

                      //GOOGLE BUTTON
                      GestureDetector(
                        onTap: () async {
                          try {
                            await AuthService().signInWithGoogle();
                            if (!context.mounted) return;
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const BottomNav(),
                              ),
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
                              messageStyle: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surface,
                                  ),
                              slideCurve: Curves.easeInOut,
                              shadowColor: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withAlpha((255 * 0.5).round()),
                            );
                          }
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
                                'Sign in with Google',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ),
                      ),
                      sizedBoxHeightXLarge,
                      GestureDetector(
                        onTap: () async {
                          try {
                            // Call the Facebook function
                            final userCredential = await AuthService()
                                .signInWithFacebook();

                            // If userCredential is null, it means the user cancelled the login
                            if (userCredential == null) return;

                            if (!context.mounted) return;

                            // Success! Navigate to Home
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const BottomNav(),
                              ),
                            );
                          } catch (e) {
                            if (!context.mounted) return;

                            // Show error toast
                            ToastService.showToast(
                              context,
                              backgroundColor: errorColor,
                              message:
                                  'Facebook Login failed. Please try again!',
                              leading: const Icon(Icons.error_outline),
                              // ... include your other styling here ...
                            );
                            print(
                              "Facebook Error✅✅✅: $e",
                            ); // Helpful for debugging the Key Hash!
                          }
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
                                image: AssetImage('assets/image/facebook.png'),
                                width: 32,
                                height: 32,
                              ),
                              sizedBoxWidthMedium,
                              Text(
                                'Sign in with Facebook',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ),
                      ),

                      /* sizedBoxHeightXLarge,
                      //  SIGNUP REDIRECT
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Don\'t have an account?',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          sizedBoxWidthSmall,
                          GestureDetector(
                            onTap: widget.showSignupPage,
                            child: Text(
                              'Register now',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(color: accentColor),
                            ),
                          ),
                        ],
                      ),*/
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
