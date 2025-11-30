import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:final_project/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final collection = 'users';
  Future SignUp(String fName, String lName, String age, String email,
    String password) async {
  try {
    // Create a new user with email and password
    UserCredential userCredential = await auth.createUserWithEmailAndPassword(
        email: email, password: password);
    User? user = userCredential.user;

    // Check if the user was created successfully
    if (user == null) throw FirebaseAuthException(code: "user-not-created");

    // Add user details to Firestore
    final userDoc = FirebaseFirestore.instance.collection(collection).doc(user.uid);
    await userDoc.set({
      'first name': fName,
      'last name': lName,
      'age': age,
      'email': email,
    });

    // Initialize the budgets, savings, and incomes sub-collections
    final budgetsCollection = userDoc.collection('budgets');
    final savingsCollection = userDoc.collection('savings');
    final incomesCollection = userDoc.collection('incomes');

    // Add placeholder documents or initialize with empty data
    await budgetsCollection.doc('placeholder').set({'message': 'Start adding budgets!'});
    await savingsCollection.doc('placeholder').set({'message': 'Start adding savings!'});
    await incomesCollection.doc('placeholder').set({'message': 'Start adding incomes!'});

    // Send email verification
    if (!user.emailVerified) {
      await user.sendEmailVerification();
      Fluttertoast.showToast(
        msg:
            "Sign-up successful! A verification email has been sent to your email. Please verify before logging in.",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 5,
        backgroundColor: brandGreen,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  } on FirebaseAuthException catch (e) {
    // Handle specific errors
    if (e.code == 'email-already-in-use') {
      Fluttertoast.showToast(
        msg: "Email already registered! Try signing in.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 3,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    } else if (e.code == 'weak-password') {
      Fluttertoast.showToast(
        msg: "Weak password! Use at least 6 characters.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 3,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    } else if (e.code == 'invalid-email') {
      Fluttertoast.showToast(
        msg: "Invalid email format.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 3,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    } else {
      Fluttertoast.showToast(
        msg: "An error occurred. Please try again.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 3,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }
}



  Future SignIn(String email, String password) async {
    try {
      UserCredential userCredential = await auth.signInWithEmailAndPassword(
          email: email, password: password);
      User? user = userCredential.user;

      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        Fluttertoast.showToast(
          msg: "Email not verified! A new verification email has been sent.",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 5,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        return;
      }

      Fluttertoast.showToast(
        msg: "Login successful!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 3,
        backgroundColor: brandGreen,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error: ${e.toString()}",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 3,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  Future<UserCredential> signInWithGoogle() async {
    // Trigger the authentication flow
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    if (googleUser == null) {
      throw const NoGoogleAccountChoosenException();
    }

    // Obtain the auth details from the request
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    // Create a new credential  
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final UserCredential userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);
    final user = userCredential.user;
    final uid = user?.uid;

    await FirebaseFirestore.instance.collection(collection).doc(uid).set({});

    // Once signed in, return the UserCredential
    return userCredential;
  }
}

class NoGoogleAccountChoosenException implements Exception {
  const NoGoogleAccountChoosenException();
}
