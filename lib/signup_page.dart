// ignore_for_file: prefer_const_constructors

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:final_project/auth_services.dart';
import 'package:final_project/component/button.dart';
import 'package:final_project/start.dart';
// import 'package:firebase/auth_services.dart';
// import 'package:firebase/component/button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
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
        backgroundColor: Color.fromARGB(154, 229, 56, 53),
        dismissDirection: DismissDirection.endToStart,
        expandedHeight: 80,
        isClosable: true,
        leading: Icon(Icons.error_outline),
        message: 'fill in all details',
        length: ToastLength.medium,
        positionCurve: Curves.bounceInOut,
        messageStyle: TextStyle(fontSize: 18, color: Colors.white),
        slideCurve: Curves.easeInOut,
        shadowColor: Color.fromARGB(199, 153, 151, 151),
      );
    } else {
      ToastService.showToast(
        context,
        backgroundColor: Color.fromARGB(199, 153, 151, 151),
        dismissDirection: DismissDirection.endToStart,
        expandedHeight: 80,
        isClosable: true,
        leading: Icon(
          Icons.error_outline,
          color: const Color.fromARGB(179, 239, 83, 80),
        ),
        message: 'Password not the same!!',
        length: ToastLength.medium,
        positionCurve: Curves.bounceInOut,
        messageStyle: TextStyle(fontSize: 18, color: Colors.white),
        slideCurve: Curves.easeInOut,
        shadowColor: Color.fromARGB(199, 153, 151, 151),
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
            title: Text('Alert Title'),
            content: Text('password is not the same'),
            actions: <Widget>[
              TextButton(
                child: Text('OK'),
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
      backgroundColor: Color(0xFF052224),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              SafeArea(
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
              SizedBox(height: 35),
              /*
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: TextField(
                  controller: _firstnamecontroller,
                  decoration: InputDecoration(
                    hintText: 'First name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    fillColor: Color.fromARGB(183, 255, 255, 255),
                    filled: true,
                  ),
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: TextField(
                  controller: _lastnamecontroller,
                  decoration: InputDecoration(
                    hintText: 'Last name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    fillColor: Color.fromARGB(183, 255, 255, 255),
                    filled: true,
                  ),
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: TextField(
                  controller: _agecontroller,
                  decoration: InputDecoration(
                    hintText: 'Age',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    fillColor: Color.fromARGB(183, 255, 255, 255),
                    filled: true,
                  ),
                ),
              ),
              SizedBox(
                height: 10,
              ),*/
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
              SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: TextField(
                  controller: _confirmpasswordcontroller,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Confirm password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    fillColor: Color.fromARGB(183, 255, 255, 255),
                    filled: true,
                  ),
                ),
              ),
              SizedBox(height: 45),
              GestureDetector(
                child: Button(h: 50, s: 380, text: 'Sign Up'),
                onTap: () async {
                  await HandleSignup();
                },
              ),
              SizedBox(height: 32),
              Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'or signup with',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white70,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
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
                              content: Text('Unknown error occured'),
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
                      width: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.all(Radius.circular(6)),
                      ),
                      child: Image(
                        image: AssetImage('assets/image/google.png'),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      // AuthService().signInWithGoogle();
                    },
                    child: Container(
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.all(Radius.circular(6)),
                      ),
                      child: Image(image: AssetImage('assets/image/FB.jpeg')),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'I am a member?',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white70,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    SizedBox(width: 8),
                    GestureDetector(
                      onTap: widget.showLoginpage,
                      child: Text(
                        'Sign In',
                        style: TextStyle(color: Colors.blue, fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
