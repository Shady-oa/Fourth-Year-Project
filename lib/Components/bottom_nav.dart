import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/spacing.dart';
import 'package:final_project/Primary_Screens/ai.dart';
import 'package:final_project/Primary_Screens/home.dart';
import 'package:final_project/Primary_Screens/profile.dart';
import 'package:final_project/Primary_Screens/savings.dart';
import 'package:final_project/Primary_Screens/transactions.dart';
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
    const Transactions(),
    const SavingsPage(),
    const AiPage(),
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
        padding: paddingAllTiny,
        child: GNav(
          backgroundColor: primaryBg,
          color: primaryText,
          activeColor: primaryBg,
          tabBackgroundColor: primaryText,
          gap: 8,
          onTabChange: select,
          padding: paddingAllSmall,
          tabs: const [
            GButton(icon: Icons.home, text: 'Home'),
            GButton(
              icon: Icons.swap_horizontal_circle_rounded,
              text: 'Transactions',
              iconSize: 30,
            ),
            GButton(
              icon: Icons.analytics_rounded,
              text: 'Savings',
              iconSize: 30,
            ),
            GButton(
              icon: Icons.auto_awesome_rounded,
              text: 'Penny AI',
              iconSize: 30,
            ),
            GButton(icon: Icons.person_rounded, text: 'Profile', iconSize: 30),
          ],
        ),
      ),
    );
  }
}
