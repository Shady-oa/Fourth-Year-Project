import 'package:final_project/Primary_Screens/ai.dart';
import 'package:final_project/Primary_Screens/home.dart';
import 'package:final_project/Primary_Screens/profile.dart';
import 'package:final_project/Primary_Screens/savings.dart';
import 'package:final_project/Primary_Screens/budget.dart';
import 'package:flutter/material.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int current_index = 0;
  List pages = [
    const HomePage(),
    const Budget(),
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: pages[current_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: current_index,
        onTap: select,
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedItemColor: Theme.of(context).colorScheme.onSurface,
        unselectedItemColor: Theme.of(
          context,
        ).colorScheme.onSurface.withOpacity(0.6),
        type: BottomNavigationBarType.fixed, // Ensures all items are visible
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_rounded),
            label: 'Budgets',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.savings_rounded),
            label: 'Savings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome_rounded),
            label: 'Penny AI',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
