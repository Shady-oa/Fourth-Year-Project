import 'package:final_project/auth_services.dart';
import 'package:final_project/component/button.dart';
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
        backgroundColor: Color.fromARGB(154, 229, 56, 53),
        dismissDirection: DismissDirection.endToStart,
        expandedHeight: 80,
        isClosable: true,
        leading: Icon(Icons.error_outline),
        message: 'Please enter both email and password!',
        length: ToastLength.medium,
        positionCurve: Curves.bounceInOut,
        messageStyle: TextStyle(fontSize: 18, color: Colors.white),
        slideCurve: Curves.easeInOut,
        shadowColor: Color.fromARGB(199, 153, 151, 151),
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
            content: Text('Wrong password or email!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
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
      backgroundColor: Color(0xFF052224),
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
                  color: Color(0xff00D09E),
                ),
              ),
            ),
            Text(
              'Penny Wise',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
            SizedBox(height: 2),
            Text(
              "Wise Choices For Financial Freedom",
              style: TextStyle(
                fontSize: 18,
                color: Colors.white70,
                fontWeight: FontWeight.normal,
              ),
            ),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: TextField(
                controller: _emailcontroller,
                decoration: InputDecoration(
                  hintText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  fillColor: Color.fromARGB(183, 255, 255, 255),
                  filled: true,
                ),
              ),
            ),
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: TextField(
                controller: _passwordcontroller,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  fillColor: Color.fromARGB(183, 255, 255, 255),
                  filled: true,
                ),
              ),
            ),
            SizedBox(height: 5),
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
                    style: TextStyle(fontSize: 16, color: Colors.blue),
                  ),
                ),
              ),
            ),
            SizedBox(height: 35),
            GestureDetector(
              child: Button(h: 50, s: 380, text: 'Sign in'),
              onTap: () async {
                await signin(); // Use the updated signin method
              },
            ),
            SizedBox(height: 32),
            Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'or sign in with',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
                Expanded(child: Divider()),
              ],
            ),
            SizedBox(height: 32),
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
                        content: Text('Unknown error occured'),
                      );
                    },
                  );
                }

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => MainLoader()),
                ); //'/homepage'
              },
              child: Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(6)),
                ),
                child: Image(image: AssetImage('assets/image/google.png')),
              ),
            ),
            SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Not a member?',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white70,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                SizedBox(width: 8),
                GestureDetector(
                  onTap: widget.showSignupPage,
                  child: Text(
                    'Register now',
                    style: TextStyle(color: Colors.blue, fontSize: 18),
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
