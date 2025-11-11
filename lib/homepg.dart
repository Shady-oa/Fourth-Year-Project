import 'package:flutter/material.dart';

class HomePg extends StatefulWidget {
  const HomePg({super.key});

  @override
  _HomePgState createState() => _HomePgState();
}

class _HomePgState extends State<HomePg> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, String>> activities = [
    {"title": "Groceries", "date": "3 Jun,2024", "amount": "-4,000"},
    {"title": "School Fees", "date": "3 Jun,2024", "amount": "-4,000"},
    {"title": "Added to Goal", "date": "3 Jun,2024", "amount": "-6,000"},
  ];
  List<Map<String, String>> filteredActivities = [];

  @override
  void initState() {
    super.initState();
    filteredActivities = activities;
    _searchController.addListener(_filterActivities);
  }

  void _filterActivities() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredActivities = activities
          .where((activity) => activity["title"]!.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xff08090A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Header
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: AssetImage('assets/image/coin.jpg'),
                    ),
                    SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Welcome back,",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xffF2F2F2),
                          ),
                        ),
                        Text(
                          "John",
                          style: TextStyle(
                            fontSize: 18,
                            color: Color(0xff9A9B98),
                          ),
                        ),
                      ],
                    ),
                    Spacer(),
                    IconButton(
                      onPressed: () {},
                      icon: Icon(
                        Icons.notifications_none_outlined,
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Search Bar
              Container(
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border.all(color: Colors.white, width: 1),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search',
                    hintStyle: TextStyle(color: Colors.white54),
                    prefixIcon: Icon(Icons.search, color: Colors.white),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: Colors.white),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 32),
                  ),
                  style: TextStyle(color: Colors.white),
                  autofocus: true,
                ),
              ),
              SizedBox(height: 20),

              // Balance Section
              Container(
                padding: EdgeInsets.all(20),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Color(0xFF424247),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Ksh 32,423",
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      "Your Balance",
                      style: TextStyle(
                        color: Color(0xff9A9B98),
                      ),
                    ),
                    SizedBox(height: 10),
                    Center(
                      child: SizedBox(
                        height: 40,
                        width: 211,
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            "ADD FUNDS",
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Center(child: Text("View Report")),
              ),
              SizedBox(height: 20),

              // Saving Goals & Budget Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Saving Goals & Budget",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      "see all",
                      style: TextStyle(color: Colors.amber),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  GoalCard(
                    icon: Icons.restaurant,
                    title: "Dinner",
                    progress: "3,000 of 6,000",
                  ),
                  GoalCard(
                    icon: Icons.desktop_windows_outlined,
                    title: "Desktop setup",
                    progress: "20,000 complete",
                  ),
                  GoalCard(
                    icon: Icons.airplanemode_active_outlined,
                    title: "Family Vacation",
                    progress: "40,000 of 50,000",
                  ),
                ],
              ),
              SizedBox(height: 20),

              // Recent Activities Section
              Text(
                "Recent Activities",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Column(
                children: filteredActivities.map((activity) {
                  return ActivityTile(
                    title: activity["title"]!,
                    date: activity["date"]!,
                    amount: activity["amount"]!,
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Color(0xff14BE9C),
        type: BottomNavigationBarType.shifting,
        selectedItemColor: Colors.amber[300],
        unselectedItemColor: Colors.white,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedFontSize: 14.0,
        unselectedFontSize: 12.0,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
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
            backgroundColor: Color(0xff14BE9C),
          ),
        ],
      ),
    );
  }
}

// Custom Widgets for Goal Card and Activity Tile

class GoalCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String progress;

  const GoalCard({super.key, required this.icon, required this.title, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 114,
      height: 114,
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Color(0xFF424247),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.amber, size: 30),
          SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          Text(
            progress,
            style: TextStyle(color: Color(0xff9A9B98), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class ActivityTile extends StatelessWidget {
  final String title;
  final String date;
  final String amount;

  const ActivityTile({super.key, required this.title, required this.date, required this.amount});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        date,
        style: TextStyle(color: Colors.grey),
      ),
      trailing: Text(
        amount,
        style: TextStyle(
          color: amount.contains('-') ? Colors.red : Colors.green,
        ),
      ),
    );
  }
}
