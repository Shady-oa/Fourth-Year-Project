import 'package:final_project/auth_services.dart';
import 'package:final_project/component/button.dart';
import 'package:final_project/constants.dart';
import 'package:final_project/start.dart';
// import 'package:firebase/auth_services.dart';
// import 'package:firebase/component/button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:toasty_box/toast_enums.dart';
import 'package:toasty_box/toast_service.dart';
//import 'package:google_fonts/google_fonts.dart';

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
      // Show a toast or an alert if fields are empty
      ToastService.showToast(
        context,
        backgroundColor: Colors.red,
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
      return; // Prevent further execution if fields are empty
    }

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailcontroller.text.trim(),
        password: _passwordcontroller.text.trim(),
      );
      Navigator.pushReplacementNamed(context, '/navigation');
    } catch (e) {
      // Handle error cases
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: primaryBg,
            content:
                Text('Wrong password or email!', style: kTextTheme.bodyMedium),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK',
                    style:
                        kTextTheme.bodyMedium?.copyWith(color: brandGreen)),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 100, 0, 0),
              child: Center(
                child: SvgPicture.asset(
                  'assets/svg/penny.svg',
                  height: 120,
                  width: 120,
                  colorFilter:
                      const ColorFilter.mode(brandGreen, BlendMode.srcIn),
                ),
              ),
            ),
            Text(
              'Penny Wise',
              style: kTextTheme.displayMedium,
            ),
            const SizedBox(height: 2),
            Text(
              "Wise Choices For Financial Freedom",
              style: kTextTheme.titleMedium,
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: TextField(
                controller: _emailcontroller,
                decoration: InputDecoration(
                  hintText: 'Email',
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  fillColor: primaryText.withOpacity(0.1),
                  filled: true,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: TextField(
                controller: _passwordcontroller,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Password',
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  fillColor: primaryText.withOpacity(0.1),
                  filled: true,
                ),
              ),
            ),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/forgotpassword');
                  },
                  child: Text(
                    'Forgot password?',
                    style: kTextTheme.bodyMedium?.copyWith(color: Colors.blue),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 35),
            GestureDetector(
              child: const Button(h: 50, s: 380, text: 'Sign in'),
              onTap: () async {
                await signin(); // Use the updated signin method
              },
            ),
            const SizedBox(height: 32),
            const Row(
              children: [
                Expanded(child: Divider(color: primaryText)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'or sign in with',
                    style: TextStyle(
                      color: primaryText,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: primaryText)),
              ],
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () async {
                try {
                  await AuthService().signInWithGoogle();
                } on NoGoogleAccountChoosenException {
                  return;
                } catch (e) {
                  if (!context.mounted) {
                    return;
                  }
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        backgroundColor: primaryBg,
                        content: Text('Unknown error occured',
                            style: kTextTheme.bodyMedium),
                      );
                    },
                  );
                }

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const MainLoader()),
                ); //'/homepage'
              },
              child: Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  color: primaryBg,
                  borderRadius: const BorderRadius.all(Radius.circular(6)),
                  border: Border.all(color: primaryText),
                ),
                child: const Image(
                    image: AssetImage('assets/image/google.png')),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Not a member?',
                  style: kTextTheme.bodyLarge,
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: widget.showSignupPage,
                  child: Text(
                    'Register now',
                    style: kTextTheme.bodyLarge?.copyWith(color: Colors.blue),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
