import 'package:final_project/Constants/spacing.dart';
import 'package:final_project/Primary_Screens/ai.dart';
import 'package:final_project/Primary_Screens/Budgets/budget.dart';
import 'package:final_project/Primary_Screens/home.dart';
import 'package:final_project/Primary_Screens/profile.dart';
import 'package:final_project/Primary_Screens/savings.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class GoogleBottomNav extends StatefulWidget {
  const GoogleBottomNav({super.key});

  @override
  State<GoogleBottomNav> createState() => _GoogleBottomNavState();
}

class _GoogleBottomNavState extends State<GoogleBottomNav> {
  int currentIndex = 0;
  List pages = [
    const HomePage(),
    const BudgetScreen(),
    const SavingsScreen(),
    const AiPage(),
    const Profile(),
  ];

  void select(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: pages[currentIndex],
      bottomNavigationBar: Container(
        padding: paddingAllTiny,
        child: GNav(
          backgroundColor: Theme.of(context).colorScheme.surface,
          color: Theme.of(context).colorScheme.onSurface,
          activeColor: Theme.of(context).colorScheme.surface,
          tabBackgroundColor: Theme.of(context).colorScheme.onSurface,
          gap: 8,
          onTabChange: select,
          padding: paddingAllSmall,
          tabs: const [
            GButton(icon: Icons.home_rounded, text: 'Home'),
            GButton(
              icon: Icons.swap_horizontal_circle_rounded,
              text: 'Budgets',
              iconSize: 30,
            ),
            GButton(icon: Icons.savings_rounded, text: 'Savings', iconSize: 30),
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
