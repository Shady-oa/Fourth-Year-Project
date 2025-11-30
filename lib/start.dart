import 'package:final_project/balance.dart';
import 'package:final_project/budget.dart';
import 'package:final_project/constants.dart';
import 'package:final_project/hme.dart';
import 'package:final_project/save_page.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class MainLoader extends StatefulWidget {
  const MainLoader({super.key});

  @override
  State<MainLoader> createState() => _MainLoaderState();
}

class _MainLoaderState extends State<MainLoader> {
  int current_index = 0;
  List pages = [const HomePage(), const SavePage(), const BalancePage(), const BudgetsPage()];

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
        color: primaryBg,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 20),
          child: GNav(
            backgroundColor: primaryBg,
            color: Colors.white,
            activeColor: Colors.white,
            tabBackgroundColor: brandGreen,
            gap: 8,
            onTabChange: select,
            padding: const EdgeInsets.all(16),
            tabs: const [
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
