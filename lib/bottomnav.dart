import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

// --- Placeholder for your constants.dart ---
// You should ensure these colors provide proper contrast.
// Example: Dark primaryBg and a bright brandGreen.
const Color primaryBg = Color(0xFF1E1E1E); // Dark background color
const Color brandGreen = Color(0xFF4CAF50); // A bright green for the active tab
// ------------------------------------------

// --- Placeholder pages for a runnable example ---
class BalancePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Center(
    child: Text('Home', style: TextStyle(color: Colors.white, fontSize: 30)),
  );
}

class BudgetsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Center(
    child: Text('Stats', style: TextStyle(color: Colors.white, fontSize: 30)),
  );
}

class SavePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Center(
    child: Text('Save', style: TextStyle(color: Colors.white, fontSize: 30)),
  );
}

class Income extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Center(
    child: Text('Profile', style: TextStyle(color: Colors.white, fontSize: 30)),
  );
}
// --------------------------------------------------

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
      // Set the main scaffold background to your primary background color
      backgroundColor: primaryBg,

      // Display the selected page in the body
      body: _pages[_selectedIndex],

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          // Set the nav bar background to your primary background color
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
            gap: 12,

            // --- THE FIXES ---

            // 1. Inactive tabs are now **White** so they are visible against the dark primaryBg.
            color: Colors.white,

            // 2. Active icon/text color is now **Black**, as requested.
            activeColor: Colors.black,

            // 3. The background color of the active tab (brandGreen) must contrast with the activeColor (black).
            tabBackgroundColor: brandGreen,

            // --- END OF FIXES ---
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
