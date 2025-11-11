import 'package:flutter/material.dart';

class SavingsPage extends StatelessWidget {
  const SavingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xff08090A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.only(top: 16.0, bottom: 20.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: AssetImage('assets/image/cat.jpg'),
                    ),
                    Spacer(),
                    Text(
                      'Savings',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Spacer(),
                    Icon(
                      Icons.notifications_none_outlined,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),

              // Balance section
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFF424247),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ksh 20,000',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'In My Total goals',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xff9A9B98),
                      ),
                    ),
                    SizedBox(height: 16),
                    Center(
                      child: SizedBox(
                        height: 40,
                        width: 150,
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text("ADD GOAL"),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),

              // Goals section
              Text(
                'My Goals',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: 4, // Number of goals
                  itemBuilder: (context, index) {
                    List<String> goals = [
                      'New Car',
                      'Family Vacation',
                      'Dinner',
                      'Desktop Setup'
                    ];
                    List<double> progress = [0.46, 0.75, 0.25, 1.0];
                    List<double> amounts = [80000, 10000, 5000, 2000];
                    List<double> targets = [150000, 15000, 10000, 2000];

                    IconData getIconForGoal(String goal) {
                      switch (goal) {
                        case 'New Car':
                          return Icons.directions_car;
                        case 'Family Vacation':
                          return Icons.airplanemode_active_outlined;
                        case 'Dinner':
                          return Icons.restaurant;
                        case 'Desktop Setup':
                          return Icons.desktop_windows_outlined;
                        default:
                          return Icons
                              .error; // Default icon if goal doesn't match
                      }
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color(0xFF424247),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      getIconForGoal(goals[index]),
                                      color: Colors.amber,
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      goals[index],
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${(1 - progress[index]) * 100}% left',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                                Icon(
                                  Icons.more_vert,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Ksh ${amounts[index]} / ${targets[index]}',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress[index],
                                backgroundColor: Colors.grey,
                                color: Colors.green,
                                minHeight: 8,
                              ),
                            ),
                            SizedBox(height: 8),
                            SizedBox(
                              height: 40,
                              child: ElevatedButton(
                                onPressed: () {
                                  // Add functionality for the button
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text("Add Money"),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      /*bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Color(0xff14BE9C),
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Budget',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.savings),
            label: 'Savings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insert_chart),
            label: 'Report',
          ),
        ],
      ),*/
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Color(0xff14BE9C),
        type: BottomNavigationBarType.shifting,
        selectedItemColor: Colors.amber[300],
        unselectedItemColor: Colors.white,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedFontSize: 14.0,
        unselectedFontSize: 12.0,
        selectedLabelStyle:
            TextStyle(fontWeight: FontWeight.bold), // Style for selected label
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
            backgroundColor: Color(0xff14BE9C),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_outlined),
            label: 'Budget',
            backgroundColor: Color(0xff14BE9C),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.savings_outlined),
            label: 'Savings',
            backgroundColor: Color(0xff14BE9C),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insert_chart_outlined_outlined),
            label: 'Report',
            backgroundColor: Color(0xff14BE9C), // Background color for the item
          ),
        ],
      ),
    );
  }
}
