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
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.only(top: 16.0, bottom: 20.0),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 24,
                      backgroundImage: AssetImage('assets/image/cat.jpg'),
                    ),
                    const Spacer(),
                    Text(
                      'Savings',
                      style: kTextTheme.headlineSmall,
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.notifications_none_outlined,
                      color: primaryText,
                    ),
                  ],
                ),
              ),

              // Balance section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryText.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ksh 20,000',
                      style: kTextTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'In My Total goals',
                      style: kTextTheme.bodyLarge
                          ?.copyWith(color: primaryText.withOpacity(0.7)),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: SizedBox(
                        height: 40,
                        width: 150,
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: brandGreen,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text("ADD GOAL",
                              style: kTextTheme.bodyMedium
                                  ?.copyWith(color: primaryText)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Goals section
              Text(
                'My Goals',
                style: kTextTheme.titleLarge,
              ),
              const SizedBox(height: 8),
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
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: primaryText.withOpacity(0.1),
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
                                      color: brandGreen,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      goals[index],
                                      style: kTextTheme.titleMedium,
                                    ),
                                  ],
                                ),
                                Text(
                                  '${(1 - progress[index]) * 100}% left',
                                  style: kTextTheme.bodySmall?.copyWith(
                                      color: primaryText.withOpacity(0.7)),
                                ),
                                Icon(
                                  Icons.more_vert,
                                  color: primaryText.withOpacity(0.7),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Ksh ${amounts[index]} / ${targets[index]}',
                                  style: kTextTheme.bodyMedium
                                      ?.copyWith(color: brandGreen),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress[index],
                                backgroundColor: primaryText.withOpacity(0.2),
                                color: brandGreen,
                                minHeight: 8,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 40,
                              child: ElevatedButton(
                                onPressed: () {
                                  // Add functionality for the button
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: brandGreen,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text("Add Money",
                                    style: kTextTheme.bodyMedium
                                        ?.copyWith(color: primaryText)),
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
    );
  }
}
