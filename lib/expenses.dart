import 'package:final_project/constants.dart';
import 'package:flutter/material.dart';

class SavingsPage extends StatelessWidget {
  const SavingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.arrow_back, color: primaryText),
                  Text(
                    "Savings",
                    style: kTextTheme.headlineSmall,
                  ),
                  const Icon(Icons.notifications_none, color: primaryText),
                ],
              ),
              const SizedBox(height: 20),

              // Balance Info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Total Balance", style: kTextTheme.bodyLarge),
                      const SizedBox(height: 4),
                      Text(
                        "\$7,783.00",
                        style: kTextTheme.headlineMedium,
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Total Expense", style: kTextTheme.bodyLarge),
                      const SizedBox(height: 4),
                      Text(
                        "-\$1,187.40",
                        style: kTextTheme.headlineMedium
                            ?.copyWith(color: Colors.blue),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Savings Goals Grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TravelSavingsPage(),
                          ),
                        );
                      },
                      child: savingsGoalItem("Travel", Icons.flight),
                    ),
                    savingsGoalItem("New House", Icons.home),
                    savingsGoalItem("Car", Icons.directions_car),
                    savingsGoalItem("Wedding", Icons.favorite),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Add More Button
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 12),
                  ),
                  onPressed: () {},
                  child: Text(
                    "Add More",
                    style: kTextTheme.bodyMedium?.copyWith(color: primaryText),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget savingsGoalItem(String title, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: primaryText.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: primaryText, size: 40),
          const SizedBox(height: 8),
          Text(
            title,
            style: kTextTheme.bodyLarge?.copyWith(color: primaryText),
          ),
        ],
      ),
    );
  }
}

class TravelSavingsPage extends StatelessWidget {
  const TravelSavingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, color: primaryText),
                  ),
                  Text(
                    "Travel",
                    style: kTextTheme.headlineSmall,
                  ),
                  const Icon(Icons.notifications_none, color: primaryText),
                ],
              ),
              const SizedBox(height: 20),

              // Goal and Amount Saved
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Goal", style: kTextTheme.bodyLarge),
                      const SizedBox(height: 4),
                      Text(
                        "\$1,962.93",
                        style: kTextTheme.headlineMedium,
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Amount Saved", style: kTextTheme.bodyLarge),
                      const SizedBox(height: 4),
                      Text(
                        "\$653.31",
                        style:
                            kTextTheme.headlineMedium?.copyWith(color: brandGreen),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Progress bar
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: primaryText.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: 0.4, // 40% progress
                        child: Container(
                          decoration: BoxDecoration(
                            color: brandGreen,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "\$1,962.93",
                    style: kTextTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                "30% Of Your Expenses, Looks Good.",
                style: kTextTheme.bodyMedium
                    ?.copyWith(color: primaryText.withOpacity(0.7)),
              ),
              const SizedBox(height: 20),

              // Transaction List
              Text(
                "April",
                style: kTextTheme.titleLarge,
              ),
              Expanded(
                child: ListView(
                  children: [
                    transactionItem(
                        "Travel Deposit", "19:56 - April 30", "\$217.77"),
                    transactionItem(
                        "Travel Deposit", "17:42 - April 14", "\$217.77"),
                    transactionItem(
                        "Travel Deposit", "12:30 - April 02", "\$217.77"),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Add Savings Button
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 12),
                  ),
                  onPressed: () {},
                  child: Text(
                    "Add Savings",
                    style: kTextTheme.bodyMedium?.copyWith(color: primaryText),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget transactionItem(String title, String date, String amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.flight, color: Colors.blue, size: 40),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: kTextTheme.bodyLarge,
                  ),
                  Text(
                    date,
                    style: kTextTheme.bodySmall
                        ?.copyWith(color: primaryText.withOpacity(0.7)),
                  ),
                ],
              ),
            ],
          ),
          Text(
            amount,
            style: kTextTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
