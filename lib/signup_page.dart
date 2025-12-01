// ignore_for_file: prefer_const_constructors

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:final_project/auth_services.dart';
import 'package:final_project/constants.dart';
import 'package:final_project/start.dart';
// import 'package:firebase/auth_services.dart';
// import 'package:firebase/component/button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:toasty_box/toast_enums.dart';
import 'package:toasty_box/toasty_box.dart';

class SignUp extends StatefulWidget {
  final VoidCallback showLoginpage;
  const SignUp({super.key, required this.showLoginpage});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final _emailcontroller = TextEditingController();
  final _passwordcontroller = TextEditingController();
  final _confirmpasswordcontroller = TextEditingController();
  final _firstnamecontroller = TextEditingController();
  final _lastnamecontroller = TextEditingController();
  final _agecontroller = TextEditingController();

  final users = FirebaseFirestore.instance.collection('users');

  @override
  void dispose() {
    // TODO: implement dispose
    _emailcontroller.dispose();
    _passwordcontroller.dispose();
    _confirmpasswordcontroller.dispose();
    _firstnamecontroller.dispose();
    _lastnamecontroller.dispose();
    _agecontroller.dispose();
    super.dispose();
  }

  HandleSignup() async {
    if (_passwordcontroller.text.isNotEmpty &&
        _confirmpasswordcontroller.text.isNotEmpty &&
        _passwordcontroller.text.trim() ==
            _confirmpasswordcontroller.text.trim()) {
      await AuthService().SignUp(
        _firstnamecontroller.text.trim(),
        _lastnamecontroller.text.trim(),
        _agecontroller.text.trim(),
        _emailcontroller.text.trim(),
        _passwordcontroller.text.trim(),
      );
    } else if (_agecontroller.text.isEmpty ||
        _emailcontroller.text.isEmpty ||
        _firstnamecontroller.text.isEmpty ||
        _lastnamecontroller.text.isEmpty) {
      ToastService.showToast(
        context,
        backgroundColor: errorColor,
        dismissDirection: DismissDirection.endToStart,
        expandedHeight: 80,
        isClosable: true,
        leading: Icon(Icons.error_outline),
        message: 'fill in all details',
        length: ToastLength.medium,
        positionCurve: Curves.bounceInOut,
        messageStyle: kTextTheme.bodyLarge?.copyWith(color: primaryBg),
        slideCurve: Curves.easeInOut,
        shadowColor: primaryText.withOpacity(0.5),
      );
    } else {
      ToastService.showToast(
        context,
        backgroundColor: primaryText.withOpacity(0.5),
        dismissDirection: DismissDirection.endToStart,
        expandedHeight: 80,
        isClosable: true,
        leading: Icon(Icons.error_outline, color: Colors.red),
        message: 'Password not the same!!',
        length: ToastLength.medium,
        positionCurve: Curves.bounceInOut,
        messageStyle: kTextTheme.bodyLarge?.copyWith(color: primaryBg),
        slideCurve: Curves.easeInOut,
        shadowColor: primaryText.withOpacity(0.5),
      );
    }
  }

  Future signup() async {
    if (passwordConfirmed()) {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailcontroller.text.trim(),
        password: _passwordcontroller.text.trim(),
      );
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: primaryBg,
            title: Text('Alert Title', style: kTextTheme.headlineSmall),
            content: Text(
              'password is not the same',
              style: kTextTheme.bodyMedium,
            ),
            actions: <Widget>[
              TextButton(
                child: Text(
                  'OK',
                  style: kTextTheme.bodyMedium?.copyWith(color: brandGreen),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }

    addUserDetails(
      _firstnamecontroller.text.trim(),
      _lastnamecontroller.text.trim(),
      _emailcontroller.text.trim(),
      int.parse(_agecontroller.text.trim()),
    );
  }

  Future addUserDetails(
    String firstName,
    String lastName,
    String email,
    int age,
  ) async {
    final user = FirebaseFirestore.instance.collection('users').doc();

    await users.add({
      'first name': firstName,
      'last name': lastName,
      'age': age,
      'email': email,
    });
  }

  bool passwordConfirmed() {
    if (_emailcontroller.text.isNotEmpty &&
        _confirmpasswordcontroller.text.isNotEmpty &&
        _passwordcontroller.text.isNotEmpty &&
        _passwordcontroller.text.trim() ==
            _confirmpasswordcontroller.text.trim()) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MainLoader()),
      ); // '/homepage'
      return true;
    } else {
      return false;
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
            height: 100,
            child: Text("Create Account", style: kTextTheme.displaySmall),
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
                  children: [
                    formLogo,

                    TextField(
                      controller: _emailcontroller,
                      decoration: InputDecoration(
                        hintText: 'Email',
                        border: OutlineInputBorder(borderRadius: radiusMedium),
                        fillColor: primaryText.withOpacity(0.1),
                        filled: true,
                      ),
                    ),

                    sizedBoxHeightSmall,
                    TextField(
                      controller: _passwordcontroller,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: 'Password',
                        border: OutlineInputBorder(borderRadius: radiusMedium),
                        fillColor: primaryText.withOpacity(0.1),
                        filled: true,
                      ),
                    ),

                    sizedBoxHeightSmall,
                    TextField(
                      controller: _confirmpasswordcontroller,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: 'Confirm password',
                        border: OutlineInputBorder(borderRadius: radiusMedium),
                        fillColor: primaryText.withOpacity(0.1),
                        filled: true,
                      ),
                    ),

                    sizedBoxHeightXLarge,
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
                          await HandleSignup();
                        },
                        child: Text(
                          'Sign Up',
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
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                backgroundColor: errorColor,
                                content: Text(
                                  'Unknown error occured',
                                  style: kTextTheme.bodyMedium,
                                ),
                              );
                            },
                          );
                        }

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => MainLoader()),
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
                          children: [
                            Image(image: AssetImage('assets/image/google.png')),
                            sizedBoxWidthSmall,
                            Text(
                              'Or Sign Up with Google',
                              style: kTextTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                    ),
                    sizedBoxWidthSmall,

                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account?',
                            style: kTextTheme.bodyLarge,
                          ),
                          sizedBoxWidthSmall,
                          GestureDetector(
                            onTap: widget.showLoginpage,
                            child: Text(
                              'Sign In',
                              style: kTextTheme.bodyLarge?.copyWith(
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ],
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
