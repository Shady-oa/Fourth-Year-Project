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
      body: _pages[_selectedIndex], // Display the current page
      bottomNavigationBar: Container(
        color: primaryBg,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 20),
          child: GNav(
            backgroundColor: primaryBg,
            color: Colors.black,
            activeColor: Colors.black,
            tabBackgroundColor: brandGreen,
            gap: 8,
            onTabChange: _onItemTapped,
            padding: const EdgeInsets.all(16),
            tabs: [
              GButton(icon: Icons.home, text: 'Home'),
              GButton(icon: Icons.pie_chart, text: 'Stats'),
              GButton(icon: Icons.swap_horiz, text: 'Transfer'),
              GButton(icon: Icons.account_circle, text: 'Profile'),
            ],
          ),
        ),
      ),
    );
  }
}
