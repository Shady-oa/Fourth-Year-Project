import 'package:final_project/AuthScreens/forgot_pwd_page.dart';
import 'package:final_project/AuthScreens/signup_page.dart';
import 'package:final_project/Components/bottom_nav.dart';
import 'package:final_project/Components/form_logo.dart';
import 'package:final_project/Components/toast.dart';
import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/spacing.dart';
import 'package:final_project/Firebase/auth_services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
      showCustomToast(
        context: context,
        message: "Please enter both email and password!",
        backgroundColor: errorColor,
        icon: Icons.error_outline_rounded,
      );
      return;
    }

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailcontroller.text.trim(),
        password: _passwordcontroller.text.trim(),
      );
      showCustomToast(
        context: context,
        message: "Logged in successfully! ",
        backgroundColor: accentColor,
        icon: Icons.check_circle_outline_rounded,
      );
      _emailcontroller.clear();
      _passwordcontroller.clear();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const BottomNav()),
      );
    } catch (e) {
      showCustomToast(
        context: context,
        message: "Wrong email or password!",
        backgroundColor: errorColor,
        icon: Icons.error_outline_rounded,
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
                "Welcome Back",
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

                      TextField(
                        controller: _emailcontroller,
                        decoration: InputDecoration(
                          hintText: 'Email',
                          border: const OutlineInputBorder(
                            borderRadius: radiusMedium,
                          ),
                          fillColor: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.1),
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
                          fillColor: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.1),
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
                      ),

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

                      sizedBoxHeightLarge,

                      //GOOGLE BUTTON
                      GestureDetector(
                        onTap: () async {
                          try {
                            await AuthService().signInWithGoogle();
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const BottomNav(),
                              ),
                            );
                          } on NoGoogleAccountChoosenException {
                            return;
                          } catch (e) {
                            showCustomToast(
                              context: context,
                              message: "Unexpected error occurred,try again!",
                              backgroundColor: errorColor,
                              icon: Icons.error_outline_rounded,
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
                                'Or Sign in with Google',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ),
                      ),

                      sizedBoxHeightXLarge,

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
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      SignUp(showLoginpage: () {}),
                                ),
                              );
                            },
                            child: Text(
                              'Register now',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(color: accentColor),
                            ),
                          ),
                        ],
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
