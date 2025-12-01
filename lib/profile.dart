import 'package:final_project/constants.dart';
import 'package:flutter/material.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: brandGreen,
      body: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.arrow_back, color: primaryBg),
                Text('Profile', style: kTextTheme.displaySmall),
                CircleAvatar(
                  radius: 30,
                  backgroundColor: primaryBg,
                  child: Icon(
                    Icons.notifications_outlined,
                    color: primaryText,
                    size: 20,
                  ),
                ),
              ],
            ),
            Container(
              decoration: BoxDecoration(
                color: primaryBg,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
