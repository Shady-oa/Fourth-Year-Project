import 'package:final_project/balance.dart';
import 'package:final_project/budget.dart';
import 'package:final_project/constants.dart';
import 'package:final_project/income.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

import 'save_page.dart';

class BottomNavigation extends StatefulWidget {
  const BottomNavigation({super.key});

  @override
  _BottomNavigationState createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    BalancePage(),
    BudgetsPage(),
    SavePage(),
    Income(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBg,
      body: _pages[_selectedIndex],

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: primaryBg,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
        ),

        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: GNav(
            // IMPORTANT → padding inside GNav (controls spacing)
            gap: 12,

            // Colors
            color: Colors.black, // inactive icon/text
            activeColor: Colors.white, // icon/text when selected
            tabBackgroundColor: brandGreen, // active tab background

            selectedIndex: _selectedIndex,
            onTabChange: _onItemTapped,

            tabs: const [
              GButton(icon: Icons.home, text: 'Home'),
              GButton(icon: Icons.pie_chart, text: 'Stats'),
              GButton(icon: Icons.savings, text: 'Save'),
              GButton(icon: Icons.account_circle, text: 'Profile'),
            ],
          ),
        ),
      ),
    );
  }
}
