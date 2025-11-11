import 'package:flutter/material.dart';

class Button extends StatelessWidget {
  final double h;
  final double s;
  final String text;
  const Button({super.key, required this.h, required this.s, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Container(
        height: h,
        width: s,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          color: Color(0xff00D09E),
        ),
        child: Center(child: Text(text,style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Color(0xff093030),
        ),)),
      ),
    );
  }
}