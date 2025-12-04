// ignore_for_file: prefer_const_constructors, use_build_context_synchronously

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:final_project/Components/bottom_nav.dart';
import 'package:final_project/Components/form_logo.dart';
import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/spacing.dart';
import 'package:final_project/Constants/typograpy.dart';
import 'package:final_project/Firebase/auth_services.dart';
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
  // 1. UPDATED: Removed first/last name and age controllers, added username controller
  final _emailcontroller = TextEditingController();
  final _passwordcontroller = TextEditingController();
  final _confirmpasswordcontroller = TextEditingController();
  final _usernamecontroller = TextEditingController();

  final users = FirebaseFirestore.instance.collection('users');

  @override
  void dispose() {
    // 2. UPDATED: Dispose of only the active controllers
    _emailcontroller.dispose();
    _passwordcontroller.dispose();
    _confirmpasswordcontroller.dispose();
    _usernamecontroller.dispose();
    super.dispose();
  }

  // 3. UPDATED: Logic now checks for username and uses signup()
  HandleSignup() async {
    if (_passwordcontroller.text.trim() ==
        _confirmpasswordcontroller.text.trim()) {
      await signup();
    } else if (_usernamecontroller.text.isEmpty ||
        _emailcontroller.text.isEmpty) {
      ToastService.showToast(
        context,
        backgroundColor: errorColor,
        dismissDirection: DismissDirection.endToStart,
        expandedHeight: 80,
        isClosable: true,
        leading: Icon(Icons.error_outline),
        message: 'Fill in all details',
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

  // 4. UPDATED: Call to addUserDetails is simpler
  Future signup() async {
    if (passwordConfirmed()) {
      try {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailcontroller.text.trim(),
          password: _passwordcontroller.text.trim(),
        );

        // Add user details to Firestore
        await addUserDetails(
          _usernamecontroller.text.trim(),
          _emailcontroller.text.trim(),
        );
      } on FirebaseAuthException catch (e) {
        // Handle specific Firebase errors (e.g., weak password, email already in use)
        ToastService.showToast(
          context,
          backgroundColor: errorColor,
          message: e.message ?? 'An error occurred during sign up.',
          length: ToastLength.medium,
        );
      }
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
  }

  // 5. UPDATED: Function signature and Firestore data structure
  Future addUserDetails(String userName, String email) async {
    // Use the user's UID as the document ID after successful authentication
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await users.doc(user.uid).set({
        'user name': userName,
        'email': email,
        'created_at': Timestamp.now(), // Helpful for tracking
      });
    }
  }

  bool passwordConfirmed() {
    if (_emailcontroller.text.isNotEmpty &&
        _confirmpasswordcontroller.text.isNotEmpty &&
        _passwordcontroller.text.isNotEmpty &&
        _usernamecontroller.text.isNotEmpty && // Added username check
        _passwordcontroller.text.trim() ==
            _confirmpasswordcontroller.text.trim()) {
      // Navigation is now handled inside signup() after successful addUserDetails
      // We only return true here to proceed with the signup logic.
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

                    // 6. ADDED: Username Text Field
                    TextField(
                      controller: _usernamecontroller,
                      decoration: InputDecoration(
                        hintText: 'User Name',
                        border: OutlineInputBorder(borderRadius: radiusMedium),
                        fillColor: primaryText.withOpacity(0.1),
                        filled: true,
                      ),
                    ),
                    sizedBoxHeightSmall,

                    TextField(
                      controller: _emailcontroller,
                      keyboardType: TextInputType.emailAddress,
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
                          final userCredential = await AuthService()
                              .signInWithGoogle();
                          // Automatically add/update user details after Google sign-in
                          await users.doc(userCredential.user!.uid).set({
                            'user name':
                                userCredential.user!.displayName ??
                                'Google User',
                            'email': userCredential.user!.email ?? '',
                            'created_at': Timestamp.now(),
                          }, SetOptions(merge: true));
                        
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BottomNav(),
                            ),
                          );
                        } on NoGoogleAccountChoosenException {
                          return;
                        } catch (e) {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                backgroundColor: errorColor,
                                content: Text(
                                  'Error: ${e.toString()}',
                                  style: kTextTheme.bodyMedium,
                                ),
                              );
                            },
                          );
                        }
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
                            Image.asset('assets/image/google.png', height: 24),
                            sizedBoxWidthSmall,
                            Text(
                              'Or Sign Up with Google',
                              style: kTextTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Removed extra sizedBoxWidthSmall here
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
