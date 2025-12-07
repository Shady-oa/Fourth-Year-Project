// ignore_for_file: prefer_const_constructors, use_build_context_synchronously

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:final_project/AuthScreens/login.dart';
import 'package:final_project/Components/bottom_nav.dart';
import 'package:final_project/Components/form_logo.dart';
import 'package:final_project/Components/toast.dart';
import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/spacing.dart';
import 'package:final_project/Firebase/auth_services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
      showCustomToast(
        context: context,
        message: "Fill in all fields!",
        backgroundColor: errorColor,
        icon: Icons.error_outline_rounded,
      );
    } else {
      showCustomToast(
        context: context,
        message: "Passwords do not match!",
        backgroundColor: errorColor,
        icon: Icons.error_outline_rounded,
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
        showCustomToast(
          context: context,
          message: "Account created successfully! Please login.",
          backgroundColor: accentColor,
          icon: Icons.check_circle_outline_rounded,
        );
        _usernamecontroller.clear();
        _emailcontroller.clear();
        _confirmpasswordcontroller.clear();
        _passwordcontroller.clear();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => Login(showSignupPage: widget.showLoginpage),
          ),
        );
      } on FirebaseAuthException {
        // Handle specific Firebase errors (e.g., weak password, email already in use)
        showCustomToast(
          context: context,
          message: "Unexpected error occurred,try again!",
          backgroundColor: errorColor,
          icon: Icons.error_outline_rounded,
        );
      }
    } else {
      showCustomToast(
        context: context,
        message: "Passwords do not match!",
        backgroundColor: errorColor,
        icon: Icons.error_outline_rounded,
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
                "Create Account",
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

                      // 6. ADDED: Username Text Field
                      TextField(
                        controller: _usernamecontroller,
                        decoration: InputDecoration(
                          hintText: 'User Name',
                          border: OutlineInputBorder(
                            borderRadius: radiusMedium,
                          ),
                          fillColor: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.1),
                          filled: true,
                        ),
                      ),
                      sizedBoxHeightSmall,

                      TextField(
                        controller: _emailcontroller,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: 'Email',
                          border: OutlineInputBorder(
                            borderRadius: radiusMedium,
                          ),
                          fillColor: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.1),
                          filled: true,
                        ),
                      ),

                      sizedBoxHeightSmall,
                      TextField(
                        controller: _passwordcontroller,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: 'Password',
                          border: OutlineInputBorder(
                            borderRadius: radiusMedium,
                          ),
                          fillColor: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.1),
                          filled: true,
                        ),
                      ),

                      sizedBoxHeightSmall,
                      TextField(
                        controller: _confirmpasswordcontroller,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: 'Confirm password',
                          border: OutlineInputBorder(
                            borderRadius: radiusMedium,
                          ),
                          fillColor: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.1),
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
                            if (!context.mounted) return;
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
                              Image.asset('assets/image/google.png'),
                              sizedBoxWidthSmall,
                              Text(
                                'Or Sign Up with Google',
                                style: Theme.of(context).textTheme.bodyLarge,
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
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            sizedBoxWidthSmall,
                            GestureDetector(
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        Login(showSignupPage: () {}),
                                  ),
                                );
                              },
                              child: Text(
                                'Sign In',
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(color: Colors.blue),
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
      ),
    );
  }
}
