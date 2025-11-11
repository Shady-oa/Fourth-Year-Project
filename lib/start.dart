import 'package:final_project/balance.dart';
import 'package:final_project/budget.dart';
import 'package:final_project/hme.dart';
import 'package:final_project/save_page.dart';
import 'package:flutter/material.dart';

class MainLoader extends StatefulWidget {
  const MainLoader({super.key});

  @override
  State<MainLoader> createState() => _MainLoaderState();
}

class _MainLoaderState extends State<MainLoader> {
  int current_index = 0;
  List pages = [HomePage(), SavePage(), Balance(),BudgetsPage() ];

  void select(int index) {
    setState(() {
      current_index = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[current_index],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Color(0xFF0E3E3E),
        selectedItemColor: Colors.greenAccent,
        unselectedItemColor: Colors.white70,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        onTap: select,
        items: [
          BottomNavigationBarItem(
            icon: SizedBox(width: 24, height: 24, child: Icon(Icons.home)),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: SizedBox(width: 24, height: 24, child: Icon(Icons.pie_chart)),
            label: 'Home',
          ),
          //BottomNavigationBarItem(icon: Icon(Icons.pie_chart), label: 'Stats'),
          BottomNavigationBarItem(
            icon: SizedBox(
              width: 24,
              height: 24,
              child: Icon(Icons.swap_horiz),
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: SizedBox(
              width: 24,
              height: 24,
              child: Icon(Icons.account_circle),
            ),
            label: 'Home',
          ),
        ],
      ),
    );
  }
}
