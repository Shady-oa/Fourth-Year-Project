import 'package:final_project/auth_services.dart';
import 'package:final_project/constants.dart';
import 'package:final_project/start.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
        messageStyle: kTextTheme.bodyLarge?.copyWith(color: primaryBg),
        slideCurve: Curves.easeInOut,
        shadowColor: primaryText.withOpacity(0.5),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailcontroller.text.trim(),
        password: _passwordcontroller.text.trim(),
      );
      Navigator.pushReplacementNamed(context, '/navigation');
    } catch (e) {
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
        messageStyle: kTextTheme.bodyLarge?.copyWith(color: primaryBg),
        slideCurve: Curves.easeInOut,
        shadowColor: primaryText.withOpacity(0.5),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: brandGreen,
      body: Column(
        children: [
          Container(
            alignment: Alignment.center,
            height: 150,
            child: Text("Welcome Back", style: kTextTheme.displaySmall),
          ),

          // BOTTOM EXPANDED CONTAINER
          Expanded(
            child: Container(
              padding: paddingAllMedium,
              decoration: const BoxDecoration(
                color: primaryBg,
                borderRadius: topOnly,
              ),

              // SCROLL ONLY INSIDE BOTTOM AREA
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Center(
                      child: SvgPicture.asset(
                        'assets/svg/penny.svg',
                        height: 120,
                        width: 120,
                        colorFilter: const ColorFilter.mode(
                          brandGreen,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),

                    Text('Penny Wise', style: kTextTheme.displayMedium),
                    const SizedBox(height: 2),
                    Text(
                      "Wise Choices For Financial Freedom",
                      style: kTextTheme.titleMedium,
                    ),

                    const SizedBox(height: 20),

                    // EMAIL FIELD
                    TextField(
                      controller: _emailcontroller,
                      decoration: InputDecoration(
                        hintText: 'Email',
                        border: const OutlineInputBorder(
                          borderRadius: radiusMedium,
                        ),
                        fillColor: primaryText.withOpacity(0.1),
                        filled: true,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // PASSWORD FIELD
                    TextField(
                      controller: _passwordcontroller,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: 'Password',
                        border: const OutlineInputBorder(
                          borderRadius: radiusMedium,
                        ),
                        fillColor: primaryText.withOpacity(0.1),
                        filled: true,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () =>
                            Navigator.pushNamed(context, '/forgotpassword'),
                        child: Text(
                          'Forgot password?',
                          style: kTextTheme.bodyMedium?.copyWith(
                            color: accentColor,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 35),

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
                          style: kTextTheme.titleLarge?.copyWith(
                            color: primaryText,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    //GOOGLE BUTTON
                    GestureDetector(
                      onTap: () async {
                        try {
                          await AuthService().signInWithGoogle();
                        } on NoGoogleAccountChoosenException {
                          return;
                        } catch (e) {
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
                            messageStyle: kTextTheme.bodyLarge?.copyWith(
                              color: primaryBg,
                            ),
                            slideCurve: Curves.easeInOut,
                            shadowColor: primaryText.withOpacity(0.5),
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

                    const SizedBox(height: 32),

                    //  SIGNUP REDIRECT
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Don\'t have an account?',
                          style: kTextTheme.bodyLarge,
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: widget.showSignupPage,
                          child: Text(
                            'Register now',
                            style: kTextTheme.bodyLarge?.copyWith(
                              color: accentColor,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),
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
