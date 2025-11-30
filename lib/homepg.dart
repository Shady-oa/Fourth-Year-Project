import 'package:final_project/constants.dart';
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
      backgroundColor: primaryBg,
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
                    const CircleAvatar(
                      radius: 30,
                      backgroundImage: AssetImage('assets/image/coin.jpg'),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Welcome back,",
                          style: kTextTheme.titleLarge,
                        ),
                        Text(
                          "John",
                          style: kTextTheme.bodyLarge
                              ?.copyWith(color: primaryText.withOpacity(0.7)),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.notifications_none_outlined,
                        size: 30,
                        color: primaryText,
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
                  border: Border.all(color: primaryText, width: 1),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search',
                    hintStyle: TextStyle(color: primaryText.withOpacity(0.5)),
                    prefixIcon: const Icon(Icons.search, color: primaryText),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: primaryText),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 32),
                  ),
                  style: const TextStyle(color: primaryText),
                  autofocus: true,
                ),
              ),
              const SizedBox(height: 20),

              // Balance Section
              Container(
                padding: const EdgeInsets.all(20),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: primaryText.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Ksh 32,423",
                      style: kTextTheme.displaySmall,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "Your Balance",
                      style: kTextTheme.bodyLarge
                          ?.copyWith(color: primaryText.withOpacity(0.7)),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: SizedBox(
                        height: 40,
                        width: 211,
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: brandGreen,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            "ADD FUNDS",
                            style: kTextTheme.bodyMedium
                                ?.copyWith(color: primaryText),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Center(
                    child: Text("View Report",
                        style: kTextTheme.bodyMedium
                            ?.copyWith(color: primaryText))),
              ),
              const SizedBox(height: 20),

              // Saving Goals & Budget Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Saving Goals & Budget",
                    style: kTextTheme.titleLarge,
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      "see all",
                      style: kTextTheme.bodyMedium?.copyWith(color: brandGreen),
                    ),
                  ),
                ],
              ),
              const Row(
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
              const SizedBox(height: 20),

              // Recent Activities Section
              Text(
                "Recent Activities",
                style: kTextTheme.titleLarge,
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
    );
  }
}

// Custom Widgets for Goal Card and Activity Tile

class GoalCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String progress;

  const GoalCard(
      {super.key,
      required this.icon,
      required this.title,
      required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 114,
      height: 114,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: primaryText.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: brandGreen, size: 30),
          const SizedBox(height: 10),
          Text(
            title,
            style: kTextTheme.bodyLarge,
          ),
          Text(
            progress,
            style: kTextTheme.bodySmall
                ?.copyWith(color: primaryText.withOpacity(0.7)),
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

  const ActivityTile(
      {super.key,
      required this.title,
      required this.date,
      required this.amount});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        title,
        style: kTextTheme.bodyLarge,
      ),
      subtitle: Text(
        date,
        style:
            kTextTheme.bodySmall?.copyWith(color: primaryText.withOpacity(0.7)),
      ),
      trailing: Text(
        amount,
        style: kTextTheme.bodyLarge?.copyWith(
          color: amount.contains('-') ? Colors.red : brandGreen,
        ),
      ),
    );
  }
}
