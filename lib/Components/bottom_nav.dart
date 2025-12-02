import 'package:final_project/Constants/colors.dart';
import 'package:final_project/balance.dart';
import 'package:final_project/Constants/spacing.dart';
import 'package:final_project/Screens/home.dart';
import 'package:final_project/Screens/profile.dart';
import 'package:final_project/save_page.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int current_index = 0;
  List pages = [
    const HomePage(),
    const SavePage(),
    const BalancePage(),
    const Profile(),
  ];

  void select(int index) {
    setState(() {
      current_index = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBg,
      body: pages[current_index],
      bottomNavigationBar: Container(
        padding: paddingAllSmall,
        color: primaryText,
        child: GNav(
          backgroundColor: primaryText,
          color: primaryBg,
          activeColor: primaryText,
          tabBackgroundColor: primaryBg,
          gap: 8,
          onTabChange: select,
          padding: paddingAllSmall,
          tabs: const [
            GButton(icon: Icons.home_rounded, text: 'Home'),
            GButton(icon: Icons.swap_horiz_rounded, text: 'Transfer'),
            GButton(icon: Icons.pie_chart_rounded, text: 'Stats'),
            GButton(icon: Icons.account_circle_rounded, text: 'Profile'),
          ],
        ),
      ),
    );
  }
}
